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
import TimeUtils
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Graphics as Ui
import Ui.Utils as Ui


{-| The view function for the preparation page.

The first element of the tuple is the main content, the second element is the right column and the last element is an
optional popup.

We need to send the right column outside the content so that the parent caller can make the right column the same size
as the left column.

-}
view : Config -> User -> Acquisition.Model -> ( Element App.Msg, Element App.Msg, Element App.Msg )
view config user model =
    let
        lang =
            config.clientState.lang

        videoTitle =
            Element.el [ Font.bold ] <| Element.text <| Strings.deviceWebcam lang

        preferredVideo =
            Maybe.andThen .video config.clientConfig.preferredDevice

        preferredAudio =
            Maybe.andThen .audio config.clientConfig.preferredDevice

        disableVideo =
            videoResolutionView lang preferredVideo Nothing

        video =
            (disableVideo :: List.map (videoView lang preferredVideo) config.clientConfig.devices.video)
                |> Element.column [ Ui.s 10, Ui.pb 10 ]

        audioTitle =
            Element.el [ Font.bold ] <| Element.text <| Strings.deviceMicrophone lang

        audio =
            List.map (audioView (Maybe.andThen .audio config.clientConfig.preferredDevice)) config.clientConfig.devices.audio
                |> Element.column [ Ui.s 10, Ui.pb 10 ]

        settings =
            Element.column [ Ui.wf, Ui.at, Ui.s 10 ] [ videoTitle, video, audioTitle, audio ]

        deviceInfo =
            Element.column [ Ui.wf, Ui.px 10, Ui.s 10, Ui.at ]
                [ Ui.title (Strings.deviceWebcam lang)
                , preferredVideo
                    |> Maybe.map Tuple.first
                    |> Maybe.map .label
                    |> Maybe.withDefault (Strings.deviceDisabled lang)
                    |> Element.text
                    |> (\x -> Element.paragraph [] [ x ])
                , preferredVideo
                    |> Maybe.map (\_ -> Ui.title (Strings.deviceResolution lang))
                    |> Maybe.withDefault Element.none
                , preferredVideo
                    |> Maybe.map Tuple.second
                    |> Maybe.map (\r -> String.fromInt r.width ++ "x" ++ String.fromInt r.height)
                    |> Maybe.map Element.text
                    |> Maybe.map (\x -> Element.paragraph [] [ x ])
                    |> Maybe.withDefault Element.none
                , Ui.title (Strings.deviceMicrophone lang)
                , preferredAudio
                    |> Maybe.map .label
                    |> Maybe.withDefault (Strings.deviceDisabled lang)
                    |> Element.text
                    |> (\x -> Element.paragraph [] [ x ])
                ]

        devicePlayer =
            Element.el
                [ Ui.wf
                , Ui.at
                , Element.inFront <|
                    case ( model.state /= Acquisition.Ready, preferredVideo ) of
                        ( True, _ ) ->
                            [ Ui.spinningSpinner [ Font.color Colors.white, Ui.cx, Ui.cy ] 50
                            , Element.text (Strings.stepsAcquisitionBindingWebcam config.clientState.lang)
                            ]
                                |> Element.column [ Ui.cx, Ui.cy, Ui.s 10, Font.color Colors.white ]
                                |> Element.el [ Ui.wf, Ui.hf, Background.color Colors.black ]

                        ( _, Nothing ) ->
                            [ Ui.icon 50 Material.Icons.videocam_off ]
                                |> Element.column [ Ui.cx, Ui.cy, Ui.s 10, Font.color Colors.white ]
                                |> Element.el [ Ui.wf, Ui.hf, Background.color Colors.black ]

                        _ ->
                            Element.none
                , Element.inFront <|
                    case ( model.state == Acquisition.Ready, model.deviceLevel ) of
                        ( True, Just level ) ->
                            vumeter level

                        _ ->
                            Element.none
                , Element.inFront <|
                    if model.state == Acquisition.Ready && not model.showSettings then
                        Ui.navigationElement
                            (Ui.Msg <| App.AcquisitionMsg <| Acquisition.ToggleSettings)
                            [ Font.color Colors.white, Ui.ab, Ui.ar, Ui.p 10 ]
                            (Ui.icon 25 Material.Icons.settings)

                    else
                        Element.none
                ]
                videoElement

        recordView : Int -> Acquisition.Record -> Element App.Msg
        recordView index record =
            Element.el [ Element.paddingXY 10 0, Ui.wf ] <|
                Element.el [ Element.paddingXY 5 10, Ui.wf, Ui.r 10, Ui.b 1, Border.color Colors.greyBorder ] <|
                    Element.row [ Ui.wf, Ui.s 10 ]
                        [ Element.text (String.fromInt (index + 1))
                        , Element.column [ Ui.wf ]
                            [ Element.text (TimeUtils.formatDuration (Acquisition.recordDuration record)) ]
                        ]

        rightColumn =
            Element.el [ Ui.wf, Ui.hf, Ui.bl 1, Border.color Colors.greyBorder ] <|
                Element.column
                    [ Ui.wf, Ui.s 10 ]
                    ((if not model.showSettings then
                        devicePlayer

                      else
                        Element.none
                     )
                        :: deviceInfo
                        :: Element.el
                            [ Ui.wf
                            , Element.paddingEach { top = 10, bottom = 0, left = 10, right = 10 }
                            , Ui.bt 1
                            , Border.color Colors.greyBorder
                            ]
                            (Ui.title (Strings.stepsAcquisitionRecordList lang 2))
                        :: List.indexedMap recordView (List.reverse model.records)
                    )

        settingsPopup =
            if model.showSettings then
                Element.column [ Ui.wf, Ui.hf ]
                    [ Element.row [ Ui.wf, Ui.hf ]
                        [ Element.el [ Ui.wf ] settings
                        , Element.el [ Ui.wf ] devicePlayer
                        ]
                    , Ui.primary [ Ui.ab, Ui.ar ]
                        { label = Strings.uiConfirm lang
                        , action = Ui.Msg <| App.AcquisitionMsg <| Acquisition.ToggleSettings
                        }
                    ]
                    |> Ui.popup 5 (Strings.navigationSettings lang)

            else
                Element.none
    in
    ( Element.none, rightColumn, settingsPopup )


videoView : Lang -> Maybe ( Device.Video, Device.Resolution ) -> Device.Video -> Element App.Msg
videoView lang preferredVideo video =
    Element.row [ Ui.s 5 ]
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
                        Colors.white
            in
            Element.el [ Ui.ab, Ui.wf, Ui.hf, Ui.b 1, Background.color color ] Element.none
    in
    [ Element.el [ Ui.hf ] Element.none
    , List.range 0 maxLeds
        |> List.reverse
        |> List.map led
        |> Element.column [ Ui.hf, Ui.s 2, Ui.wpx 20, Ui.ab ]
    ]
        |> Element.column [ Ui.al, Ui.ab, Ui.p 10, Ui.hf ]
