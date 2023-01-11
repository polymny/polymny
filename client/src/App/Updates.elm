module App.Updates exposing (update, updateModel, subs)

{-| This module contains the update function of the polymny application.

@docs update, updateModel, subs

-}

import Acquisition.Types as Acquisition
import Acquisition.Updates as Acquisition
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


{-| Updates the model from a message, and returns the new model as well as the command to send.
-}
update : App.Msg -> Result App.Error App.Model -> ( Result App.Error App.Model, Cmd App.Msg )
update msg model =
    case model of
        Ok m ->
            updateModel msg m |> Tuple.mapFirst Ok

        _ ->
            ( model, Cmd.none )


{-| Updates a well formed model from a message, and returns the new model as well as the command to send.
-}
updateModel : App.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
updateModel msg model =
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


{-| Returns the subscriptions of the app.
-}
subs : Result App.Error App.Model -> Sub App.Msg
subs m =
    case m of
        Err _ ->
            Sub.none

        Ok model ->
            Sub.batch
                [ Device.detectDevicesResponse
                    (\x ->
                        case Decode.decodeValue Device.decodeDevices x of
                            Ok devices ->
                                App.ConfigMsg (Config.DetectDevicesResponse devices)

                            _ ->
                                App.Noop
                    )
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
