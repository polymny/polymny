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
import Element.Input as Input
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
import Utils


{-| The view function for the preparation page.

The first element of the tuple is the main content, the second element is the right column and the last element is an
optional popup.

We need to send the right column outside the content so that the parent caller can make the right column the same size
as the left column.

-}
view : Config -> User -> Acquisition.Model -> ( Element App.Msg, Element App.Msg, Element App.Msg )
view config user model =
    let
        --- HELPERS ---
        -- Shortcut for lang
        lang =
            config.clientState.lang

        -- Shortcut for the preferred video device
        preferredVideo : Maybe ( Device.Video, Device.Resolution )
        preferredVideo =
            Maybe.andThen .video config.clientConfig.preferredDevice

        -- Shortcut for the preferred audio device
        preferredAudio : Maybe Device.Audio
        preferredAudio =
            Maybe.andThen .audio config.clientConfig.preferredDevice

        --- UI ELEMENTS ---
        -- Title of the video part of the device settings
        videoTitle : Element App.Msg
        videoTitle =
            Ui.title (Strings.deviceWebcam lang)

        -- Button to disable the video
        disableVideo : Element App.Msg
        disableVideo =
            videoView lang preferredVideo Nothing

        -- Column with buttons that let the user select their webcam
        video : Element App.Msg
        video =
            (disableVideo :: List.map (\x -> videoView lang preferredVideo (Just x)) config.clientConfig.devices.video)
                |> Element.column [ Ui.s 10, Ui.pb 10 ]

        -- Title of the resolution part of the device settings
        resolutionTitle : Element App.Msg
        resolutionTitle =
            Ui.title (Strings.deviceResolution lang)
                |> Utils.tern (preferredVideo == Nothing) Element.none

        -- Column with buttons that let the user select the resolution of their webcam
        resolution : Element App.Msg
        resolution =
            preferredVideo
                |> Maybe.map (\( v, r ) -> List.map (videoResolutionView lang ( v, r )) v.resolutions)
                |> Maybe.map (Element.column [ Ui.s 10, Ui.pb 10 ])
                |> Maybe.withDefault Element.none

        -- Title of the audio input part of the device settings
        audioTitle : Element App.Msg
        audioTitle =
            Ui.title (Strings.deviceMicrophone lang)

        -- Column with the buttons that let the user pick their audio input
        audio =
            List.map (audioView (Maybe.andThen .audio config.clientConfig.preferredDevice)) config.clientConfig.devices.audio
                |> Element.column [ Ui.s 10, Ui.pb 10 ]

        -- Element that contains all the device settings
        settings : Element App.Msg
        settings =
            Element.column [ Ui.wf, Ui.at, Ui.s 10 ]
                [ videoTitle
                , video
                , resolutionTitle
                , resolution
                , audioTitle
                , audio
                ]

        -- Element that displays the info about the seleected device
        deviceInfo : Element App.Msg
        deviceInfo =
            Element.column [ Ui.wf, Ui.px 10, Ui.s 5, Ui.at ]
                [ Ui.title (Strings.deviceWebcam lang)
                , preferredVideo
                    |> Maybe.map Tuple.first
                    |> Maybe.map .label
                    |> Maybe.withDefault (Strings.deviceDisabled lang)
                    |> Ui.paragraph []
                , preferredVideo
                    |> Maybe.map (\_ -> Ui.title (Strings.deviceResolution lang))
                    |> Maybe.withDefault Element.none
                , preferredVideo
                    |> Maybe.map Tuple.second
                    |> Maybe.map (\r -> String.fromInt r.width ++ "x" ++ String.fromInt r.height)
                    |> Maybe.map (Ui.paragraph [])
                    |> Maybe.withDefault Element.none
                , Ui.title (Strings.deviceMicrophone lang)
                , preferredAudio
                    |> Maybe.map .label
                    |> Maybe.withDefault (Strings.deviceDisabled lang)
                    |> Ui.paragraph []
                ]

        -- VuMeter element that shows the volume of the audio input
        vumeterElement : Element App.Msg
        vumeterElement =
            case ( model.state == Acquisition.Ready && model.recordPlaying == Nothing, model.deviceLevel, model.showSettings ) of
                ( True, Just level, False ) ->
                    vumeter 2 level

                ( True, Just level, True ) ->
                    vumeter 4 level

                _ ->
                    Element.none

        -- Element displayed in front of the device feedback during loading or when camera is disabled
        inFrontElement : Element App.Msg
        inFrontElement =
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

        -- Element displayed in front of the device feedback with some buttons to manage the device settings
        settingsElement : Element App.Msg
        settingsElement =
            if model.state == Acquisition.Ready && not model.showSettings then
                Ui.navigationElement
                    (Ui.Msg <| App.AcquisitionMsg <| Acquisition.ToggleSettings)
                    [ Font.color Colors.white, Ui.ab, Ui.ar, Ui.p 10 ]
                    (Ui.icon 25 Material.Icons.settings)

            else
                Element.none

        -- Element that shows the device feedback to the user
        devicePlayer : Element App.Msg
        devicePlayer =
            Element.el
                [ Ui.wf
                , Ui.at
                , Element.inFront inFrontElement
                , Element.inFront vumeterElement
                , Element.inFront settingsElement
                ]
                (Element.html (Html.video [ Html.Attributes.class "wf", Html.Attributes.id "video" ] []))

        -- Formats a view of a record, whether it is on the client or on the server
        recordView : Int -> Acquisition.Record -> Element App.Msg
        recordView index record =
            let
                -- Attributes to show things as disabled
                disableAttr : List (Element.Attribute App.Msg)
                disableAttr =
                    [ Font.color Colors.greyFontDisabled ]

                -- Gives disable attributes if element is disabled
                disableAttrIf : Bool -> List (Element.Attribute App.Msg)
                disableAttrIf disabled =
                    if disabled then
                        disableAttr

                    else
                        []

                -- Play button
                playButton : Element App.Msg
                playButton =
                    let
                        isPlaying =
                            case model.recordPlaying of
                                Just rec ->
                                    rec == record

                                Nothing ->
                                    False

                        attr =
                            disableAttrIf isPlaying

                        action =
                            if isPlaying then
                                Ui.None

                            else
                                Ui.Msg <| App.AcquisitionMsg <| Acquisition.PlayRecord record
                    in
                    Ui.secondaryIcon
                        attr
                        { icon = Material.Icons.play_arrow
                        , tooltip = Strings.stepsAcquisitionPlayRecord lang
                        , action = action
                        }

                -- Stop button
                stopButton : Element App.Msg
                stopButton =
                    let
                        isPlaying =
                            case model.recordPlaying of
                                Just rec ->
                                    rec == record

                                Nothing ->
                                    False

                        attr =
                            disableAttrIf (not isPlaying)

                        action =
                            if isPlaying then
                                Ui.Msg <| App.AcquisitionMsg <| Acquisition.StopRecord

                            else
                                Ui.None
                    in
                    Ui.secondaryIcon
                        attr
                        { icon = Material.Icons.stop
                        , tooltip = Strings.stepsAcquisitionStopRecord lang
                        , action = action
                        }
            in
            Element.el [ Element.paddingXY 10 0, Ui.wf ] <|
                Element.el [ Element.paddingXY 5 10, Ui.wf, Ui.r 10, Ui.b 1, Border.color Colors.greyBorder ] <|
                    Element.row [ Ui.wf, Ui.s 10 ]
                        [ if record.old then
                            Element.text <| Strings.stepsAcquisitionSavedRecord lang

                          else
                            Element.text (String.fromInt (index + 1))
                        , Element.column [ Ui.wf ]
                            [ Element.text (TimeUtils.formatDuration (Acquisition.recordDuration record)) ]
                        , playButton
                        , stopButton
                        , Ui.primaryIcon []
                            { icon = Material.Icons.done
                            , tooltip = ""
                            , action = Ui.Msg <| App.AcquisitionMsg <| Acquisition.UploadRecord record
                            }
                        ]

        -- Popup to ask the user to confirm if they want to delete the current record
        deleteRecordPopup : Element App.Msg
        deleteRecordPopup =
            Element.column [ Ui.wf, Ui.hf ]
                [ Element.paragraph [ Ui.wf, Ui.cy, Font.center ]
                    [ Element.text (Lang.question Strings.actionsConfirmDeleteRecord lang) ]
                , Element.row [ Ui.ab, Ui.ar, Ui.s 10 ]
                    [ Ui.secondary []
                        { action = mkUiMsg (Acquisition.DeleteRecord Utils.Cancel)
                        , label = Strings.uiCancel lang
                        }
                    , Ui.primary []
                        { action = mkUiMsg (Acquisition.DeleteRecord Utils.Confirm)
                        , label = Strings.uiConfirm lang
                        }
                    ]
                ]
                |> Ui.popup 1 (Strings.actionsDeleteRecord lang)

        -- Column that contains the device feedback element, the info, and the list of records
        rightColumn : Element App.Msg
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

        -- Popup where the user can customize their device settings
        settingsPopup : Element App.Msg
        settingsPopup =
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

        currentSlide : Maybe Data.Slide
        currentSlide =
            List.head (List.drop model.currentSlide model.gos.slides)

        nextSlide : Maybe Data.Slide
        nextSlide =
            List.head (List.drop (model.currentSlide + 1) model.gos.slides)

        getLine : Int -> Data.Slide -> Maybe String
        getLine n x =
            List.head (List.drop n (String.split "\n" x.prompt))

        previousSentence : Maybe String
        previousSentence =
            Maybe.withDefault Nothing (Maybe.map (getLine (model.currentSentence - 1)) currentSlide)

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
            case ( Maybe.map .prompt currentSlide, currentSentence ) of
                ( Just "", _ ) ->
                    Element.none

                ( _, Just s ) ->
                    Element.column [ Ui.hfp 1, Ui.wf, Background.color Colors.black, Font.color Colors.white, Ui.p 10, Ui.s 10 ]
                        [ Element.el [ Ui.cx, Font.center, Font.size 40 ]
                            (Input.multiline
                                [ Background.color Colors.black
                                , Ui.b 0
                                , Element.htmlAttribute (Html.Attributes.style "-moz-text-align-last" "center")
                                , Element.htmlAttribute (Html.Attributes.style "text-align-last" "center")
                                ]
                                { label = Input.labelHidden ""
                                , onChange = \x -> App.AcquisitionMsg (Acquisition.CurrentSentenceChanged x)
                                , placeholder = Nothing
                                , text = s
                                , spellcheck = False
                                }
                            )
                        , case nextSentence of
                            Just s2 ->
                                Element.el [ Ui.cx, Font.center, Font.size 40, Font.color (Colors.grey 5) ]
                                    (Input.multiline [ Font.center, Background.color Colors.black, Ui.b 0 ]
                                        { label = Input.labelHidden ""
                                        , onChange = \_ -> App.Noop
                                        , placeholder = Nothing
                                        , spellcheck = False
                                        , text = s2
                                        }
                                    )

                            -- [ nextSlideIcon, Element.text s2 ]
                            _ ->
                                Element.none
                        , Element.row
                            [ Ui.ab
                            , Ui.wf
                            ]
                            [ case ( model.recording, model.currentSentence > 0 ) of
                                ( Nothing, True ) ->
                                    Ui.navigationElement
                                        (Ui.Msg <| App.AcquisitionMsg <| Acquisition.NextSentence False)
                                        [ Ui.al ]
                                        (Ui.icon 25 Material.Icons.navigate_before)

                                _ ->
                                    Element.none
                            , if model.recording == Nothing then
                                Ui.navigationElement
                                    (Ui.Msg <| App.AcquisitionMsg <| Acquisition.NextSentence False)
                                    [ Ui.ar ]
                                    (if nextSentence /= Nothing then
                                        Ui.icon 25 Material.Icons.navigate_next

                                     else
                                        Ui.icon 25 Material.Icons.replay
                                    )

                              else
                                Element.none
                            ]
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
                        , Background.uncropped (Data.slidePath model.capsule s)
                        , Element.html (Html.canvas [ Html.Attributes.id Acquisition.pointerCanvasId ] [])
                            |> Element.el [ Ui.wf, Ui.cy ]
                            |> Element.inFront
                        ]
                        Element.none

                _ ->
                    Element.none

        content =
            Element.column [ Ui.wf, Ui.hf ]
                [ promptElement
                , statusElement
                , Element.row
                    [ Ui.wf, Ui.hf ]
                    [ palette
                        |> List.map (\( x, y ) -> Element.row [ Element.spacing 5, Ui.wf, Ui.hf ] [ colorToButton x, colorToButton y ])
                        |> Element.column [ Element.width (Element.px 100), Element.spacing 5, Element.padding 5 ]
                    , slideElement
                    ]
                ]

        popup =
            if model.showSettings then
                settingsPopup

            else if model.deleteRecord then
                deleteRecordPopup

            else
                Element.none
    in
    ( content, rightColumn, popup )


{-| Displays a button to select a specific video device.
-}
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
                    if v.available then
                        Ui.Msg <| App.AcquisitionMsg <| Acquisition.RequestCameraPermission v.deviceId

                    else
                        Ui.None

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


{-| Displays a button to select a specific video resolution.
-}
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


{-| Displays a button to select a specific audio device.
-}
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


{-| Displays a nice VuMeter : a gauge that show the volume of the audio input.
-}
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


{-| Palette of colors that can be used for pointer.
-}
palette : List ( Element.Color, Element.Color )
palette =
    [ ( Element.rgb255 255 0 0, Element.rgb255 128 0 0 )
    , ( Element.rgb255 255 128 0, Element.rgb255 128 64 0 )
    , ( Element.rgb255 255 255 0, Element.rgb255 128 128 0 )
    , ( Element.rgb255 0 255 0, Element.rgb255 0 128 0 )
    , ( Element.rgb255 0 255 255, Element.rgb255 0 128 128 )
    , ( Element.rgb255 0 0 255, Element.rgb255 0 0 128 )
    , ( Element.rgb255 255 0 255, Element.rgb255 128 0 128 )
    , ( Element.rgb255 255 128 128, Element.rgb255 128 128 255 )
    , ( Element.rgb255 128 255 128, Element.rgb255 255 255 128 )
    ]


{-| Convers an element color to a css string.
-}
colorToString : Element.Color -> String
colorToString color =
    let
        { red, green, blue } =
            Element.toRgb color

        r =
            floor (255 * red) |> String.fromInt

        g =
            floor (255 * green) |> String.fromInt

        b =
            floor (255 * blue) |> String.fromInt
    in
    "rgb(" ++ r ++ "," ++ g ++ "," ++ b ++ ")"


{-| Convers an element color to an input button.
-}
colorToButton : Element.Color -> Element App.Msg
colorToButton color =
    Input.button [ Ui.wf, Element.height (Element.px 45) ]
        { label = Element.el [ Ui.wf, Ui.hf, Background.color color ] Element.none
        , onPress =
            colorToString color
                |> Acquisition.SetPointerColor
                |> App.AcquisitionMsg
                |> Just
        }


{-| Easily creates the Ui.Msg for options msg.
-}
mkUiMsg : Acquisition.Msg -> Ui.Action App.Msg
mkUiMsg msg =
    mkMsg msg |> Ui.Msg


{-| Easily creates a options msg.
-}
mkMsg : Acquisition.Msg -> App.Msg
mkMsg msg =
    App.AcquisitionMsg msg
