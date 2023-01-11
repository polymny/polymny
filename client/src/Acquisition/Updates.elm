port module Acquisition.Updates exposing
    ( update
    , subs
    )

{-| This module contains the update function for the preparation page.

@docs update

-}

import Acquisition.Types as Acquisition
import App.Types as App
import Device


{-| The update function of the preparation page.
-}
update : Acquisition.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    let
        clientConfig =
            model.config.clientConfig
    in
    case model.page of
        App.Acquisition m ->
            case msg of
                Acquisition.DeviceChanged ->
                    ( { model | page = App.Acquisition { m | state = Acquisition.BindingWebcam, deviceLevel = Nothing } }
                    , Device.bindDevice (Device.getDevice clientConfig.devices clientConfig.preferredDevice)
                    )

                Acquisition.DetectDevicesFinished ->
                    ( { model | page = App.Acquisition { m | state = Acquisition.BindingWebcam, deviceLevel = Nothing } }
                    , Device.bindDevice (Device.getDevice clientConfig.devices clientConfig.preferredDevice)
                    )

                Acquisition.DeviceBound ->
                    ( { model | page = App.Acquisition { m | state = Acquisition.Ready } }, Cmd.none )

                Acquisition.DeviceLevel x ->
                    ( { model | page = App.Acquisition { m | deviceLevel = Just x } }, Cmd.none )

                Acquisition.ToggleSettings ->
                    ( { model | page = App.Acquisition { m | state = Acquisition.BindingWebcam, showSettings = not m.showSettings } }
                    , Device.bindDevice (Device.getDevice clientConfig.devices clientConfig.preferredDevice)
                    )

        _ ->
            ( model, Cmd.none )


{-| The subscriptions needed for the page to work.
-}
subs : Acquisition.Model -> Sub App.Msg
subs model =
    Sub.batch
        [ detectDevicesFinished (\_ -> App.AcquisitionMsg Acquisition.DetectDevicesFinished)
        , deviceBound (\_ -> App.AcquisitionMsg Acquisition.DeviceBound)
        , deviceLevel (\x -> App.AcquisitionMsg (Acquisition.DeviceLevel x))
        ]


{-| The detection of devices asked by elm is finished.
-}
port detectDevicesFinished : (() -> msg) -> Sub msg


{-| The device binding is finished.
-}
port deviceBound : (() -> msg) -> Sub msg


{-| The device make a specific amount of sound.
-}
port deviceLevel : (Float -> msg) -> Sub msg
