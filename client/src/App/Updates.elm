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
import Device
import Home.Updates as Home
import Json.Decode as Decode
import NewCapsule.Updates as NewCapsule
import Preparation.Types as Preparation
import Preparation.Updates as Preparation
import Route
import Unlogged.Updates as Unlogged


{-| Updates the model from a message, and returns the new model as well as the command to send.
-}
update : App.MaybeMsg -> App.MaybeModel -> ( App.MaybeModel, Cmd App.MaybeMsg )
update message model =
    case ( message, model ) of
        ( App.LoggedMsg msg, App.Logged m ) ->
            updateModel msg m |> Tuple.mapBoth App.Logged (Cmd.map App.LoggedMsg)

        ( App.UnloggedMsg msg, App.Unlogged m ) ->
            Unlogged.update msg m |> Tuple.mapBoth App.Unlogged (Cmd.map App.UnloggedMsg)

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

                App.OnUrlChange url ->
                    let
                        ( page, cmd ) =
                            App.pageFromRoute model.config model.user (Route.fromUrl url)
                    in
                    ( { model | page = page }, cmd )

                App.InternalUrl url ->
                    ( model, Browser.Navigation.pushUrl model.config.clientState.key url.path )

                App.ExternalUrl url ->
                    ( model, Browser.Navigation.load url )

                App.Logout ->
                    ( model, Api.logout App.LoggedOut )

                App.LoggedOut ->
                    ( model
                    , Browser.Navigation.load (Maybe.withDefault model.config.serverConfig.root model.config.serverConfig.home)
                    )
    in
    ( updatedModel, Cmd.batch [ updatedCmd, unbindDevice ] )


{-| Returns the subscriptions of the app.
-}
subs : App.MaybeModel -> Sub App.MaybeMsg
subs m =
    case m of
        App.Logged model ->
            Sub.batch
                [ Sub.map App.ConfigMsg Config.subs
                , case model.page of
                    App.Home ->
                        Home.subs

                    App.NewCapsule _ ->
                        Sub.none

                    App.Preparation x ->
                        Preparation.subs x

                    App.Acquisition x ->
                        Acquisition.subs x
                ]
                |> Sub.map App.LoggedMsg

        _ ->
            Sub.none
