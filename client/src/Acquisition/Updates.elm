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
                    ( model, Device.bindDevice (Device.getDevice clientConfig.devices clientConfig.preferredDevice) )

                Acquisition.DetectDevicesFinished ->
                    ( model, Device.bindDevice (Device.getDevice clientConfig.devices clientConfig.preferredDevice) )

        _ ->
            ( model, Cmd.none )


{-| The subscriptions needed for the page to work.
-}
subs : Acquisition.Model -> Sub App.Msg
subs model =
    detectDevicesFinished (\_ -> App.AcquisitionMsg Acquisition.DetectDevicesFinished)


port detectDevicesFinished : (() -> msg) -> Sub msg
