module App.Updates exposing (update, updateModel, subs)

{-| This module contains the update function of the polymny application.

@docs update, updateModel, subs

-}

import Acquisition.Types as Acquisition
import Acquisition.Updates as Acquisition
import Api.User as Api
import App.Types as App
import App.Utils as App
import Browser.Navigation
import Config
import Data.User as Data
import Device
import Home.Updates as Home
import NewCapsule.Updates as NewCapsule
import Options.Types as Options
import Options.Updates as Options
import Preparation.Types as Preparation
import Preparation.Updates as Preparation
import Production.Updates as Production
import Publication.Types as Publication
import Publication.Updates as Publication
import RemoteData
import Route
import Settings.Types as Settings
import Settings.Updates as Settings
import Unlogged.Types as Unlogged
import Unlogged.Updates as Unlogged


{-| Updates the model from a message, and returns the new model as well as the command to send.
-}
update : App.MaybeMsg -> App.MaybeModel -> ( App.MaybeModel, Cmd App.MaybeMsg )
update message model =
    case ( message, model ) of
        -- In some cases (transitions from unlogged to logged or vice versa), the update needs to be managed here
        -- because the submodulse will not know about UnloggedModel or LoggedModel.
        -- This can happen :
        -- When login succeeds
        ( App.UnloggedMsg (Unlogged.LoginRequestChanged (RemoteData.Success user)), App.Unlogged m ) ->
            App.pageFromRoute m.config user Route.Home
                |> Tuple.mapBoth
                    (\x -> App.Logged { config = m.config, user = user, page = x })
                    (Cmd.map App.LoggedMsg)

        -- When the user changes their password after reset
        ( App.UnloggedMsg (Unlogged.ResetPasswordRequestChanged (RemoteData.Success user)), App.Unlogged m ) ->
            App.pageFromRoute m.config user Route.Home
                |> Tuple.mapBoth
                    (\x -> App.Logged { config = m.config, user = user, page = x })
                    (\x -> Cmd.batch [ Cmd.map App.LoggedMsg x, Route.push m.config.clientState.key Route.Home ])

        -- When the user deletes their account
        ( App.LoggedMsg (App.SettingsMsg (Settings.DeleteAccountDataChanged (RemoteData.Success _))), App.Logged m ) ->
            ( App.Unlogged (Unlogged.init m.config Nothing)
            , case m.config.serverConfig.home of
                Just url ->
                    Browser.Navigation.load url

                _ ->
                    Route.push m.config.clientState.key Route.Home
            )

        -- If the sortBy is changed, we need to update the logged model's user
        ( App.LoggedMsg (App.ConfigMsg (Config.SortByChanged newSortBy)), App.Logged m ) ->
            let
                user =
                    m.user
            in
            updateModel (App.ConfigMsg (Config.SortByChanged newSortBy))
                { m | user = { user | projects = Data.sortProjects newSortBy user.projects } }
                |> Tuple.mapBoth App.Logged (Cmd.map App.LoggedMsg)

        ( App.LoggedMsg msg, App.Logged m ) ->
            updateModel msg m |> Tuple.mapBoth App.Logged (Cmd.map App.LoggedMsg)

        ( App.UnloggedMsg msg, App.Unlogged m ) ->
            Unlogged.update msg m
                |> Tuple.mapBoth App.Unlogged (Cmd.map App.UnloggedMsg)

        _ ->
            ( model, Cmd.none )


{-| Updates a well formed model from a message, and returns the new model as well as the command to send.
-}
updateModel : App.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
updateModel msg model =
    let
        -- We check if the user exited the acqusition page, in that case, we unbind the device to turn off the webcam
        -- light.
        unbindDevice =
            case ( model.page, updatedModel.page ) of
                ( _, App.Acquisition _ ) ->
                    Cmd.none

                ( App.Acquisition _, _ ) ->
                    Device.unbindDevice

                _ ->
                    Cmd.none

        -- We check if the user exited the options page, in which case we should stop the playing of the soundtrack.
        stopSoundtrackCmd =
            case ( model.page, updatedModel.page ) of
                ( _, App.Options _ ) ->
                    Cmd.none

                ( App.Options m, _ ) ->
                    Options.stopTrackPreviewPort ()

                _ ->
                    Cmd.none

        ( updatedModel, updatedCmd ) =
            case msg of
                App.Noop ->
                    ( model, Cmd.none )

                App.ConfigMsg sMsg ->
                    let
                        oldPreferredDevice =
                            model.config.clientConfig.preferredDevice

                        ( nextConfig, nextCmd ) =
                            Config.update sMsg model.config

                        ( newModel, newCmd ) =
                            if oldPreferredDevice /= nextConfig.clientConfig.preferredDevice then
                                -- We need to tell the acquisition page that the device changed
                                let
                                    ( tmpModel, tmpCmd ) =
                                        updateModel (App.AcquisitionMsg Acquisition.DeviceChanged) { model | config = nextConfig }
                                in
                                ( tmpModel, Cmd.batch [ tmpCmd, nextCmd ] )

                            else
                                ( { model | config = nextConfig }, nextCmd )
                    in
                    ( newModel, newCmd )

                App.HomeMsg sMsg ->
                    Home.update sMsg model

                App.NewCapsuleMsg sMsg ->
                    NewCapsule.update sMsg model

                App.PreparationMsg sMsg ->
                    Preparation.update sMsg model

                App.AcquisitionMsg aMsg ->
                    Acquisition.update aMsg model

                App.ProductionMsg pMsg ->
                    Production.update pMsg model

                App.PublicationMsg pMsg ->
                    Publication.update pMsg model

                App.OptionsMsg oMsg ->
                    Options.update oMsg model

                App.SettingsMsg sMsg ->
                    Settings.update sMsg model

                App.OnUrlChange url ->
                    let
                        ( page, cmd ) =
                            App.pageFromRoute model.config model.user (Route.fromUrl url)
                    in
                    ( { model | page = page }, cmd )

                App.InternalUrl url ->
                    case model.config.clientState.key of
                        Just k ->
                            ( model, Browser.Navigation.pushUrl k url.path )

                        _ ->
                            ( model, Cmd.none )

                App.ExternalUrl url ->
                    ( model, Browser.Navigation.load url )

                App.Logout ->
                    ( model, Api.logout App.LoggedOut )

                App.LoggedOut ->
                    ( model
                    , Browser.Navigation.load (Maybe.withDefault model.config.serverConfig.root model.config.serverConfig.home)
                    )
    in
    ( updatedModel, Cmd.batch [ updatedCmd, stopSoundtrackCmd, unbindDevice ] )


{-| Returns the subscriptions of the app.
-}
subs : App.MaybeModel -> Sub App.MaybeMsg
subs m =
    case m of
        App.Logged model ->
            Sub.batch
                [ Sub.map App.ConfigMsg Config.subs
                , case model.page of
                    App.Home _ ->
                        Home.subs

                    App.NewCapsule _ ->
                        Sub.none

                    App.Preparation x ->
                        Preparation.subs x

                    App.Acquisition x ->
                        Acquisition.subs x

                    App.Production x ->
                        Production.subs x

                    App.Publication _ ->
                        Sub.none

                    App.Options _ ->
                        Options.subs

                    App.Settings _ ->
                        Sub.none
                ]
                |> Sub.map App.LoggedMsg

        App.Unlogged model ->
            Unlogged.subs |> Sub.map App.UnloggedMsg
        
        _ ->
            Sub.none
