module Acquisition.Views exposing (view)

{-| The main view for the acquisition page.

@docs view

-}

import Acquisition.Types as Acquisition
import App.Types as App
import Config exposing (Config)
import Data.User exposing (User)
import Device
import Element exposing (Element)
import Element.Font as Font
import Ui.Elements as Ui
import Ui.Graphics as Ui
import Ui.Utils as Ui


{-| The view function for the preparation page.
-}
view : Config -> User -> Acquisition.Model -> ( Element App.Msg, Element App.Msg )
view config user model =
    let
        videoTitle =
            Element.el [ Font.bold ] (Element.text "Video devices")

        video =
            List.map (videoView (Maybe.andThen .video config.clientConfig.preferredDevice)) config.clientConfig.devices.video
                |> Element.column [ Ui.s 10, Ui.pb 10 ]

        audioTitle =
            Element.el [ Font.bold ] (Element.text "Audio devices")

        audio =
            List.map (audioView (Maybe.andThen .audio config.clientConfig.preferredDevice)) config.clientConfig.devices.audio
                |> Element.column [ Ui.s 10, Ui.pb 10 ]

        content =
            Element.column [ Ui.p 10, Ui.s 10 ] [ videoTitle, video, audioTitle, audio ]
    in
    ( content, Element.none )


videoView : Maybe ( Device.Video, Device.Resolution ) -> Device.Video -> Element App.Msg
videoView preferredVideo video =
    Element.row [ Ui.s 10 ]
        (Element.text video.label :: List.map (videoResolutionView preferredVideo video) video.resolutions)


videoResolutionView : Maybe ( Device.Video, Device.Resolution ) -> Device.Video -> Device.Resolution -> Element App.Msg
videoResolutionView preferredVideo video resolution =
    let
        isPreferredVideo =
            preferredVideo
                |> Maybe.map Tuple.first
                |> Maybe.map .deviceId
                |> (==) (Just video.deviceId)

        isPreferredVideoAndResolution =
            preferredVideo
                |> Maybe.map Tuple.second
                |> (==) (Just resolution)
                |> (&&) isPreferredVideo

        makeButton =
            if isPreferredVideoAndResolution then
                Ui.primary

            else
                Ui.secondary

        action =
            if video.available then
                Ui.Msg <| App.ConfigMsg <| Config.SetVideo video resolution

            else
                Ui.None
    in
    makeButton [] { label = Device.formatResolution resolution, action = action }


audioView : Maybe Device.Audio -> Device.Audio -> Element App.Msg
audioView preferredAudio audio =
    let
        isPreferredAudio =
            preferredAudio
                |> Maybe.map .deviceId
                |> (==) (Just audio.deviceId)

        makeButton =
            if isPreferredAudio then
                Ui.primary

            else
                Ui.secondary

        action =
            if audio.available then
                Ui.Msg <| App.ConfigMsg <| Config.SetAudio audio

            else
                Ui.None
    in
    makeButton [] { label = audio.label, action = action }
