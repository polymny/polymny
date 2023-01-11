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
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html
import Html.Attributes
import Lang exposing (Lang)
import Material.Icons
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Graphics as Ui
import Ui.Utils as Ui


{-| The view function for the preparation page.
-}
view : Config -> User -> Acquisition.Model -> ( Element App.Msg, Element App.Msg )
view config user model =
    let
        lang =
            config.clientState.lang

        videoTitle =
            Element.el [ Font.bold ] (Element.text "Video devices")

        preferredVideo =
            Maybe.andThen .video config.clientConfig.preferredDevice

        disableVideo =
            videoResolutionView lang preferredVideo Nothing

        video =
            (disableVideo :: List.map (videoView lang preferredVideo) config.clientConfig.devices.video)
                |> Element.column [ Ui.s 10, Ui.pb 10 ]

        audioTitle =
            Element.el [ Font.bold ] (Element.text "Audio devices")

        audio =
            List.map (audioView (Maybe.andThen .audio config.clientConfig.preferredDevice)) config.clientConfig.devices.audio
                |> Element.column [ Ui.s 10, Ui.pb 10 ]

        settings =
            Element.column [ Ui.wf, Ui.s 10 ] [ videoTitle, video, audioTitle, audio ]

        content =
            Element.row [ Ui.wf, Ui.s 10, Ui.p 10 ]
                [ Element.el
                    [ Ui.wf
                    , Ui.hf
                    , Element.inFront
                        (case ( model.state /= Acquisition.Ready, preferredVideo, model.deviceLevel ) of
                            ( True, _, _ ) ->
                                Element.el [ Ui.wf, Ui.hf, Background.color Colors.black ]
                                    (Element.column [ Ui.cx, Ui.cy, Ui.s 10, Font.color Colors.white ]
                                        [ Ui.spinningSpinner [ Font.color Colors.white, Ui.cx, Ui.cy ] 50
                                        , Element.text (Strings.stepsAcquisitionBindingWebcam config.clientState.lang)
                                        ]
                                    )

                            ( _, Nothing, _ ) ->
                                Element.el [ Ui.wf, Ui.hf, Background.color Colors.black ]
                                    (Element.column [ Ui.cx, Ui.cy, Ui.s 10, Font.color Colors.white ]
                                        [ Ui.icon 50 Material.Icons.videocam_off
                                        ]
                                    )

                            ( _, _, Just level ) ->
                                vumeter level

                            _ ->
                                Element.none
                        )
                    ]
                    videoElement
                , settings
                ]
    in
    ( content, Element.none )


videoView : Lang -> Maybe ( Device.Video, Device.Resolution ) -> Device.Video -> Element App.Msg
videoView lang preferredVideo video =
    Element.row [ Ui.s 10 ]
        (Element.text video.label :: List.map (\x -> videoResolutionView lang preferredVideo (Just ( video, x ))) video.resolutions)


videoResolutionView : Lang -> Maybe ( Device.Video, Device.Resolution ) -> Maybe ( Device.Video, Device.Resolution ) -> Element App.Msg
videoResolutionView lang preferredVideo video =
    let
        isPreferredVideo =
            preferredVideo
                |> Maybe.map Tuple.first
                |> Maybe.map .deviceId
                |> (==) (Maybe.map .deviceId <| Maybe.map Tuple.first video)

        isPreferredVideoAndResolution =
            preferredVideo
                |> Maybe.map Tuple.second
                |> (==) (Maybe.map Tuple.second video)
                |> (&&) isPreferredVideo

        makeButton =
            if isPreferredVideoAndResolution then
                Ui.primary

            else
                Ui.secondary

        action =
            if Maybe.map .available (Maybe.map Tuple.first video) |> Maybe.withDefault True then
                Ui.Msg <| App.ConfigMsg <| Config.SetVideo <| video

            else
                Ui.None
    in
    makeButton []
        { label = Maybe.map Tuple.second video |> Maybe.map Device.formatResolution |> Maybe.withDefault (Strings.deviceDisabled lang)
        , action = action
        }


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


videoElement : Element App.Msg
videoElement =
    Element.html (Html.video [ Html.Attributes.class "wf", Html.Attributes.id "video" ] [])


vumeter : Float -> Element App.Msg
vumeter value =
    let
        maxLeds =
            10

        leds =
            round (value / 75.0 * toFloat maxLeds)

        led : Int -> Element App.Msg
        led index =
            let
                color =
                    if index < leds then
                        Colors.green2

                    else
                        Colors.transparent
            in
            Element.el [ Ui.ab, Ui.wf, Ui.hf, Ui.b 1, Background.color color ] Element.none
    in
    [ Element.el [ Ui.hfp 3 ] Element.none
    , List.range 0 maxLeds
        |> List.reverse
        |> List.map led
        |> Element.column [ Ui.hfp 1, Ui.s 2, Ui.wpx 20, Ui.ab ]
    ]
        |> Element.column [ Ui.ar, Ui.ab, Ui.p 10, Ui.hf ]
