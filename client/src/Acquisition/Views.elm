module Acquisition.Views exposing (view)

{-| The main view for the acquisition page.

@docs view

-}

import Acquisition.Types as Acquisition
import App.Types as App
import Config exposing (Config)
import Data.Capsule as Data
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
import Time
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

        preferredVideo =
            Maybe.andThen .video config.clientConfig.preferredDevice

        preferredAudio =
            Maybe.andThen .audio config.clientConfig.preferredDevice

        disableVideo =
            videoView lang preferredVideo Nothing

        videoTitle =
            Ui.title (Strings.deviceWebcam lang)

        video =
            (disableVideo :: List.map (\x -> videoView lang preferredVideo (Just x)) config.clientConfig.devices.video)
                |> Element.column [ Ui.s 10, Ui.pb 10 ]

        resolutionTitle =
            if preferredVideo == Nothing then
                Element.none

            else
                Ui.title (Strings.deviceResolution lang)

        resolution =
            case preferredVideo of
                Just ( v, r ) ->
                    List.map (videoResolutionView lang ( v, r )) v.resolutions
                        |> Element.column [ Ui.s 10, Ui.pb 10 ]

                _ ->
                    Element.none

        audioTitle =
            Ui.title (Strings.deviceMicrophone lang)

        audio =
            List.map (audioView (Maybe.andThen .audio config.clientConfig.preferredDevice)) config.clientConfig.devices.audio
                |> Element.column [ Ui.s 10, Ui.pb 10 ]

        settings =
            Element.column [ Ui.wf, Ui.at, Ui.s 10 ]
                [ videoTitle
                , video
                , resolutionTitle
                , resolution
                , audioTitle
                , audio
                ]

        deviceInfo =
            Element.column [ Ui.wf, Ui.px 10, Ui.s 5, Ui.at ]
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
                            , Element.text (Strings.stepsAcquisitionBindingWebcam lang)
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
                    case ( model.state == Acquisition.Ready && model.recordPlaying == Nothing, model.deviceLevel, model.showSettings ) of
                        ( True, Just level, False ) ->
                            vumeter 2 level

                        ( True, Just level, True ) ->
                            vumeter 4 level

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
                        , Ui.primaryIcon []
                            { icon =
                                if model.recordPlaying == Just record then
                                    Material.Icons.stop

                                else
                                    Material.Icons.play_arrow
                            , tooltip = ""
                            , action = Ui.Msg <| App.AcquisitionMsg <| Acquisition.PlayRecord record
                            }
                        , Ui.primaryIcon []
                            { icon = Material.Icons.done
                            , tooltip = ""
                            , action = Ui.Msg <| App.AcquisitionMsg <| Acquisition.UploadRecord record
                            }
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

        slides : List Data.Slide
        slides =
            List.drop model.gos model.capsule.structure |> List.head |> Maybe.map .slides |> Maybe.withDefault []

        currentSlide : Maybe Data.Slide
        currentSlide =
            List.head (List.drop model.currentSlide slides)

        nextSlide : Maybe Data.Slide
        nextSlide =
            List.head (List.drop (model.currentSlide + 1) slides)

        getLine : Int -> Data.Slide -> Maybe String
        getLine n x =
            List.head (List.drop n (String.split "\n" x.prompt))

        currentSentence : Maybe String
        currentSentence =
            Maybe.withDefault Nothing (Maybe.map (getLine model.currentSentence) currentSlide)

        nextSentenceCurrentSlide : Maybe String
        nextSentenceCurrentSlide =
            Maybe.withDefault Nothing (Maybe.map (getLine (model.currentSentence + 1)) currentSlide)

        nextSentence : Maybe String
        nextSentence =
            let
                tmp =
                    nextSlide
                        |> Maybe.map (\x -> List.head (String.split "\n" x.prompt))
                        |> Maybe.withDefault Nothing
            in
            case nextSentenceCurrentSlide of
                Nothing ->
                    tmp

                x ->
                    x

        nextSlideIcon =
            if nextSentenceCurrentSlide == Nothing && nextSentence /= Nothing then
                Ui.icon 40 Material.Icons.arrow_circle_right
                    |> Element.el [ Element.paddingEach { right = 10, left = 0, top = 0, bottom = 0 } ]

            else
                Element.none

        promptElement : Element App.Msg
        promptElement =
            case currentSentence of
                Just s ->
                    Element.column [ Ui.hfp 1, Ui.wf, Background.color Colors.black, Font.color Colors.white, Ui.p 10, Ui.s 10 ]
                        [ Element.paragraph [ Font.center, Font.size 40 ] [ Element.text s ]
                        , case nextSentence of
                            Just s2 ->
                                Element.paragraph [ Font.center, Font.size 40, Font.color (Colors.grey 5) ]
                                    [ nextSlideIcon, Element.text s2 ]

                            _ ->
                                Element.none
                        ]

                _ ->
                    Element.none

        statusElement : Element App.Msg
        statusElement =
            Element.row [ Ui.wf, Ui.p 10 ]
                [ Element.el [ Ui.cx ] <|
                    case model.recording of
                        Just t ->
                            Element.row [ Ui.s 10 ]
                                [ Element.el [ Ui.class "blink", Font.color Colors.red ] (Element.text "⬤ REC")
                                , Element.text (Lang.dots Strings.stepsAcquisitionRecording lang)
                                , Element.text (TimeUtils.formatDuration (Time.posixToMillis config.clientState.time - Time.posixToMillis t))
                                ]

                        Nothing ->
                            Element.text (Strings.stepsAcquisitionReadyForRecording lang)
                ]

        slideElement : Element App.Msg
        slideElement =
            case currentSlide of
                Just s ->
                    Element.el
                        [ Ui.wf
                        , Ui.hfp 2
                        , Background.uncropped
                            (Data.slidePath model.capsule s)
                        ]
                        Element.none

                _ ->
                    Element.none

        content =
            Element.column [ Ui.wf, Ui.hf ]
                [ promptElement, statusElement, slideElement ]
    in
    ( content, rightColumn, settingsPopup )


videoView : Lang -> Maybe ( Device.Video, Device.Resolution ) -> Maybe Device.Video -> Element App.Msg
videoView lang preferredVideo video =
    let
        mkButton =
            if Maybe.map .deviceId video == (preferredVideo |> Maybe.map Tuple.first |> Maybe.map .deviceId) then
                Ui.primary

            else
                Ui.secondary

        action =
            case Maybe.map (\x -> ( x, x.resolutions )) video of
                Nothing ->
                    Ui.Msg <| App.ConfigMsg <| Config.SetVideo Nothing

                Just ( v, [] ) ->
                    Ui.Msg <| App.AcquisitionMsg <| Acquisition.RequestCameraPermission v.deviceId

                Just ( v, r :: _ ) ->
                    if v.available then
                        Ui.Msg <| App.ConfigMsg <| Config.SetVideo <| Just ( v, r )

                    else
                        Ui.None

        button =
            mkButton []
                { label = Maybe.map .label video |> Maybe.withDefault (Strings.deviceDisabled lang)
                , action = action
                }
    in
    button


videoResolutionView : Lang -> ( Device.Video, Device.Resolution ) -> Device.Resolution -> Element App.Msg
videoResolutionView lang ( preferredVideo, preferredResolution ) resolution =
    let
        makeButton =
            if preferredResolution == resolution then
                Ui.primary

            else
                Ui.secondary

        action =
            Ui.Msg <| App.ConfigMsg <| Config.SetVideo <| Just ( preferredVideo, resolution )
    in
    makeButton []
        { label = Device.formatResolution resolution
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


vumeter : Int -> Float -> Element App.Msg
vumeter ratio value =
    let
        maxLeds =
            10

        leds =
            round (value / 80.0 * toFloat maxLeds)

        led : Int -> Element App.Msg
        led index =
            let
                color =
                    case ( index > maxLeds - 3, index > maxLeds - 5, index >= leds ) of
                        ( True, _, True ) ->
                            Colors.redLight

                        ( True, _, False ) ->
                            Colors.red

                        ( False, True, True ) ->
                            Colors.orangeLight

                        ( False, True, False ) ->
                            Colors.orange

                        ( _, _, True ) ->
                            Colors.greenLight

                        _ ->
                            Colors.green2
            in
            Element.el [ Ui.ab, Ui.wf, Ui.hf, Ui.b 1, Background.color color ] Element.none
    in
    [ Element.el [ Ui.hfp (ratio - 1) ] Element.none
    , List.range 0 (maxLeds - 1)
        |> List.reverse
        |> List.map led
        |> Element.column [ Ui.hfp 1, Ui.s 2, Ui.wpx 20, Ui.ab ]
    ]
        |> Element.column [ Ui.al, Ui.ab, Ui.p 10, Ui.hf ]
