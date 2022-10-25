module Acquisition.Views exposing (..)

import Acquisition.Types as Acquisition
import Capsule
import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import FontAwesome as Fa
import Html
import Html.Attributes
import Html.Events
import Keyboard
import Lang
import Status
import Ui.Colors as Colors
import Ui.Utils as Ui
import User exposing (User)
import Utils exposing (formatTime, tern)


shortcuts : Acquisition.Model -> Keyboard.RawKey -> Core.Msg
shortcuts model msg =
    let
        raw =
            Keyboard.rawValue msg
    in
    case raw of
        " " ->
            if model.recording then
                Core.AcquisitionMsg Acquisition.StopRecording

            else
                Core.AcquisitionMsg Acquisition.StartRecording

        "ArrowRight" ->
            Core.AcquisitionMsg Acquisition.NextSentence

        _ ->
            Core.Noop


view : Core.Global -> User -> Acquisition.Model -> ( Element Core.Msg, Maybe (Element Core.Msg) )
view global user model =
    let
        content =
            case ( global.devices, model.webcamBound ) of
                ( Just d, True ) ->
                    let
                        submodel =
                            Acquisition.toSubmodel d model
                    in
                    Element.el [ Ui.wfp 6, Ui.hf ] (centerElement global user submodel)

                _ ->
                    Element.column [ Ui.wfp 6, Ui.hf, Element.spacing 10 ]
                        [ if Acquisition.isError model.state then
                            Element.none

                          else
                            Element.el [ Element.centerX, Element.centerY ] Ui.spinner
                        , Element.paragraph [ Font.center, Element.centerX, Element.centerY ]
                            [ Element.text
                                (case model.state of
                                    Acquisition.DetectingDevices ->
                                        Lang.detectingDevices global.lang

                                    Acquisition.BindingWebcam ->
                                        Lang.bindingWebcam global.lang

                                    Acquisition.ErrorDetectingDevices ->
                                        Lang.errorDetectingDevices global.lang

                                    Acquisition.ErrorBindingWebcam ->
                                        Lang.errorBindingWebcam global.lang
                                )
                            ]
                        ]

        popup =
            case ( model.showSettings, global.devices, ( model.status, model.uploading ) ) of
                ( _, _, ( Status.Error, _ ) ) ->
                    Just
                        (Ui.customSizedPopup 1
                            (Lang.error global.lang)
                            (Element.el [ Ui.wf, Ui.hf, Background.color Colors.whiteBis ]
                                (Element.column [ Ui.wf, Ui.hf, Element.centerX, Font.center, Element.spacing 10 ]
                                    [ Element.paragraph
                                        [ Element.centerX, Element.centerY, Font.center ]
                                        [ Element.text (Lang.uploadRecordFailed global.lang) ]
                                    , Element.el [ Element.alignBottom, Element.alignRight, Element.padding 10 ]
                                        (Ui.primaryButton
                                            { onPress = Just (Core.AcquisitionMsg Acquisition.UploadRecordFailedAck)
                                            , label = Element.text (Lang.confirm global.lang)
                                            }
                                        )
                                    ]
                                )
                            )
                        )

                ( True, Just d, _ ) ->
                    Just (settingsView global user (Acquisition.toSubmodel d model))

                ( _, _, ( _, Just progress ) ) ->
                    Just
                        (Ui.customSizedPopup 1
                            (Lang.loading global.lang)
                            (Element.el [ Ui.wf, Ui.hf, Background.color Colors.whiteBis ]
                                (Element.column [ Ui.wf, Element.centerX, Element.centerY, Font.center, Element.spacing 10 ]
                                    [ Element.paragraph
                                        [ Element.centerX, Element.centerY, Font.center ]
                                        [ Element.text (Lang.uploading global.lang) ]
                                    , Ui.progressBar progress
                                    ]
                                )
                            )
                        )

                _ ->
                    Nothing
    in
    ( Element.row [ Ui.wf, Ui.hf ]
        [ content
        , Element.el [ Ui.wfp 1, Ui.hf ]
            (rightColumn global user (Maybe.map (\x -> Acquisition.toSubmodel x model) global.devices))
        ]
    , popup
    )


rightColumn : Core.Global -> User -> Maybe Acquisition.Submodel -> Element Core.Msg
rightColumn global user submodel =
    let
        settingsButton =
            Ui.primaryButton
                { onPress = Just (Core.AcquisitionMsg Acquisition.ToggleSettings)
                , label = Element.text (Lang.settings global.lang)
                }
                |> Element.el [ Element.centerX, Element.padding 10 ]

        info =
            case submodel of
                Just s ->
                    Element.column [ Ui.wf, Element.spacing 5, Element.padding 10 ]
                        [ Element.el [ Font.bold ] (Element.text (Lang.webcam global.lang))
                        , s.chosenDevice.video
                            |> Maybe.map .label
                            |> Maybe.withDefault (Lang.disabled global.lang)
                            |> Element.text
                            |> paragraph
                        , Element.el [ Font.bold ] (Element.text (Lang.resolution global.lang))
                        , s.chosenDevice.resolution
                            |> Maybe.map Acquisition.format
                            |> Maybe.map Element.text
                            |> Maybe.withDefault Element.none
                        , Element.el [ Font.bold ] (Element.text (Lang.microphone global.lang))
                        , s.chosenDevice.audio
                            |> Maybe.map .label
                            |> Maybe.withDefault (Lang.disabled global.lang)
                            |> Element.text
                            |> paragraph
                        , settingsButton
                        ]

                _ ->
                    Element.none

        recordView : Int -> Acquisition.Record -> Element Core.Msg
        recordView id record =
            Element.row [ Ui.wf, Element.spacing 20, Element.padding 10, Border.color Colors.greyLight, Border.rounded 5, Border.width 1 ]
                [ Element.text (String.fromInt (id + 1))
                , Element.column [ Element.spacing 10 ]
                    [ Element.row [ Element.spacing 10 ]
                        [ record.events
                            |> List.reverse
                            |> List.head
                            |> Maybe.map (\x -> formatTime x.time)
                            |> Maybe.withDefault ""
                            |> Element.text
                        ]
                    , if User.isPremium user then
                        Element.row [ Element.spacing 10 ]
                            [ Input.button [] { label = Element.text "record", onPress = Just (Core.AcquisitionMsg (Acquisition.StartPointerRecording record)) }
                            , if record.pointerBlob == Nothing then
                                Element.text "no pointer"

                              else
                                Element.text "pointer"
                            ]

                      else
                        Element.none
                    ]
                , Element.row [ Element.alignRight, Element.spacing 10, Element.centerY ]
                    [ if Maybe.andThen .recordPlaying submodel /= Just record then
                        Ui.iconButton [ Font.color Colors.navbar ]
                            { onPress = Just (Core.AcquisitionMsg (Acquisition.PlayRecord record))
                            , icon = Fa.play
                            , text = Nothing
                            , tooltip = Just (Lang.playRecord global.lang)
                            }

                      else
                        Ui.iconButton [ Font.color Colors.navbar ]
                            { onPress = Just (Core.AcquisitionMsg Acquisition.StopPlayingRecord)
                            , icon = Fa.stop
                            , text = Nothing
                            , tooltip = Just (Lang.stopRecord global.lang)
                            }
                    , Ui.iconButton [ Font.color Colors.navbar ]
                        { onPress = Just (Core.AcquisitionMsg (Acquisition.UploadRecord record))
                        , icon = Fa.check
                        , text = Nothing
                        , tooltip = Just (Lang.uploadRecord global.lang)
                        }
                    ]
                ]

        records =
            case submodel of
                Just s ->
                    Element.column
                        [ Ui.wf
                        , Ui.hf
                        , Border.widthEach { top = 1, bottom = 0, left = 0, right = 0 }
                        , Border.color Colors.greyLighter
                        , Element.padding 10
                        , Element.spacing 10
                        ]
                        (Element.el [ Element.centerX ] (Element.text (Lang.records global.lang))
                            :: List.indexedMap recordView (List.reverse s.records)
                        )

                _ ->
                    Element.none
    in
    Element.column
        [ Border.color Colors.greyLighter
        , Border.widthEach { left = 1, right = 0, top = 0, bottom = 0 }
        , Background.color Colors.whiteTer
        , Ui.wf
        , Ui.hf
        ]
        [ if submodel |> Maybe.map .showSettings |> Maybe.withDefault False then
            Element.none

          else
            videoElement [ Ui.wf ]
        , info
        , records
        ]


settingsView : Core.Global -> User -> Acquisition.Submodel -> Element Core.Msg
settingsView global user model =
    let
        onVideoChange =
            Html.Events.onInput
                (\x ->
                    case Acquisition.videoDeviceFromId model.devices.video x of
                        Just v ->
                            Core.AcquisitionMsg (Acquisition.VideoDeviceChanged v)

                        _ ->
                            Core.Noop
                )

        videoOption : Maybe Acquisition.VideoDevice -> Html.Html Core.Msg
        videoOption device =
            let
                selected =
                    Html.Attributes.selected (device == model.chosenDevice.video)
            in
            case device of
                Just d ->
                    Html.option [ selected, Html.Attributes.value d.deviceId ] [ Html.text d.label ]

                _ ->
                    Html.option
                        [ selected
                        , Html.Attributes.value "disabled"
                        ]
                        [ Html.text (Lang.disabled global.lang) ]

        onResolutionChange =
            Html.Events.onInput
                (\x ->
                    case model.chosenDevice.video of
                        Just chosenDevice ->
                            case Acquisition.resolutionFromString chosenDevice.resolutions x of
                                Just v ->
                                    Core.AcquisitionMsg (Acquisition.ResolutionChanged v)

                                _ ->
                                    Core.Noop

                        _ ->
                            Core.Noop
                )

        resolutionOption : Acquisition.Resolution -> Html.Html Core.Msg
        resolutionOption resolution =
            let
                selected =
                    Html.Attributes.selected (Just resolution == model.chosenDevice.resolution)
            in
            Html.option
                [ selected
                , Html.Attributes.value (Acquisition.format resolution)
                ]
                [ Html.text (Acquisition.format resolution) ]

        onAudioChange =
            Html.Events.onInput
                (\x ->
                    case Acquisition.audioDeviceFromId model.devices.audio x of
                        Just v ->
                            Core.AcquisitionMsg (Acquisition.AudioDeviceChanged v)

                        _ ->
                            Core.Noop
                )

        audioOption : Acquisition.AudioDevice -> Html.Html Core.Msg
        audioOption device =
            let
                selected =
                    Html.Attributes.selected (Just device == model.chosenDevice.audio)
            in
            Html.option
                [ selected
                , Html.Attributes.value device.deviceId
                ]
                [ Html.text device.label ]

        form =
            Element.column [ Ui.wf, Ui.hf ]
                [ Element.text (Lang.webcam global.lang)
                , (Nothing :: (model.devices.video |> List.map Just))
                    |> List.map videoOption
                    |> Html.select [ onVideoChange ]
                    |> Element.html
                    |> Element.el [ Element.paddingXY 0 10 ]
                , case model.chosenDevice.video of
                    Just _ ->
                        Element.text (Lang.resolution global.lang)

                    _ ->
                        Element.none
                , case model.chosenDevice.video of
                    Just v ->
                        Html.select [ onResolutionChange ] (List.map resolutionOption v.resolutions)
                            |> Element.html
                            |> Element.el [ Element.paddingXY 0 10 ]

                    _ ->
                        Element.none
                , Element.text (Lang.microphone global.lang)
                , Html.select [ onAudioChange ] (List.map audioOption model.devices.audio)
                    |> Element.html
                    |> Element.el [ Element.paddingXY 0 10 ]
                , Ui.simpleButton
                    { label = Element.text (Lang.refreshDevices global.lang)
                    , onPress = Just (Core.AcquisitionMsg Acquisition.RefreshDevices)
                    }
                ]

        element =
            Element.column [ Ui.wf, Ui.hf, Background.color Colors.whiteBis, Element.spacing 10, Element.padding 10 ]
                [ Element.row [ Ui.wf, Element.centerY, Background.color Colors.whiteBis, Element.spacing 10 ]
                    [ form
                    , Element.el [ Ui.wf, Ui.hf ] (videoElement [ Ui.wf, Ui.hf ])
                    ]
                , Element.el [ Element.alignBottom, Ui.wf ]
                    (Element.el [ Element.alignRight ]
                        (Ui.primaryButton
                            { onPress = Just (Core.AcquisitionMsg Acquisition.ToggleSettings)
                            , label = Element.text (Lang.confirm global.lang)
                            }
                        )
                    )
                ]
    in
    Ui.customSizedPopup 5 (Lang.settings global.lang) element


centerElement : Core.Global -> User -> Acquisition.Submodel -> Element Core.Msg
centerElement global user model =
    let
        prompt =
            promptElement global user model

        slide =
            Element.row [ Ui.wf, Ui.hf ]
                [ toolbarElement global user model
                , slideElement global user model
                ]
    in
    Element.column [ Ui.wf, Ui.hf ] (tern global.acquisitionInverted [ slide, prompt ] [ prompt, slide ])


promptElement : Core.Global -> User -> Acquisition.Submodel -> Element Core.Msg
promptElement global user model =
    let
        slides : List Capsule.Slide
        slides =
            List.drop model.gos model.capsule.structure |> List.head |> Maybe.map .slides |> Maybe.withDefault []

        currentSlide : Maybe Capsule.Slide
        currentSlide =
            List.head (List.drop model.currentSlide slides)

        nextSlide : Maybe Capsule.Slide
        nextSlide =
            List.head (List.drop (model.currentSlide + 1) slides)

        getLine : Int -> Capsule.Slide -> Maybe String
        getLine n x =
            List.head (List.drop n (String.split "\n" x.prompt))

        currentSentence : Maybe String
        currentSentence =
            Maybe.withDefault Nothing (Maybe.map (getLine model.currentLine) currentSlide)

        nextSentenceCurrentSlide : Maybe String
        nextSentenceCurrentSlide =
            Maybe.withDefault Nothing (Maybe.map (getLine (model.currentLine + 1)) currentSlide)

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
                Element.html (Html.span [] [ Fa.iconWithOptions Fa.arrowCircleRight Fa.Solid [] [] ])
                    |> Element.el [ Element.paddingEach { right = 10, left = 0, top = 0, bottom = 0 } ]

            else
                Element.none

        promptAttributes : List (Element.Attribute Core.Msg)
        promptAttributes =
            [ Font.center, Element.centerX ]

        promptText =
            case currentSentence of
                Just h ->
                    Element.el
                        (Font.size (global.promptSize + 10) :: Font.color Colors.white :: promptAttributes)
                        (Element.paragraph [] [ Element.text h ])

                _ ->
                    Element.none

        nextPromptText =
            case nextSentence of
                Just h ->
                    Element.row
                        (Font.size global.promptSize :: Font.color Colors.grey :: promptAttributes)
                        [ Element.paragraph [] [ nextSlideIcon, Element.text h ] ]

                _ ->
                    Element.none

        totalSlides =
            List.length slides

        totalLines =
            slides
                |> List.map (.prompt >> String.lines >> List.length)
                |> List.foldl (+) 0

        -- Some mattpiz wizardry
        currentLine =
            slides
                |> List.take model.currentSlide
                |> List.map (.prompt >> String.lines >> List.length)
                |> List.foldl (+) (model.currentLine + 1)

        noPrompt =
            List.all (\x -> x.prompt == "") slides

        status : Element Core.Msg
        status =
            Input.button []
                { label =
                    Element.column [ Font.color Colors.white, Font.bold, Background.color Colors.navbar, Element.padding 5, Border.color Colors.success, Border.width 2, Border.rounded 50 ]
                        [ if model.recording then
                            Element.row [ Element.width Element.fill, Element.spacing 10 ]
                                [ Element.el
                                    [ Font.size 25, Font.color (Element.rgb255 255 0 0) ]
                                    (Element.row [ Ui.blink ]
                                        [ Element.none -- Ui.Icons.buttonFromIcon Fa.circle
                                        , Element.el [ Element.paddingEach { left = 5, bottom = 0, top = 0, right = 0 } ]
                                            (Element.text "REC")
                                        ]
                                    )
                                ]

                          else
                            Element.row [ Element.width Element.fill, Element.spacing 10 ]
                                [ Element.el
                                    []
                                    (Element.row []
                                        [ Element.el [ Font.size 25 ] Element.none -- (Ui.Icons.buttonFromIcon Fa.stopCircle)
                                        , Element.el [ Element.paddingEach { left = 5, bottom = 0, top = 0, right = 0 } ]
                                            (Element.text (Lang.recordingStopped global.lang))
                                        ]
                                    )
                                ]
                        ]
                , onPress = Just (Core.AcquisitionMsg (tern model.recording Acquisition.StopRecording Acquisition.StartRecording))
                }

        invertButton =
            Ui.iconButton [ Font.color Colors.navbar ]
                { onPress = Just (Core.AcquisitionMsg Acquisition.InvertAcquisition)
                , icon = Fa.arrowsAltVertical
                , text = Nothing
                , tooltip = Just (Lang.invertSlideAndPrompt global.lang)
                }

        info =
            Element.row [ Element.padding 10, Element.spacing 30, Ui.wf ]
                [ status
                , Element.el [ Element.width Element.fill ] (Element.el [ Element.centerX ] invertButton)
                , Element.text (Lang.slide global.lang ++ " " ++ String.fromInt (model.currentSlide + 1) ++ " / " ++ String.fromInt totalSlides)
                , Element.text (Lang.line global.lang ++ " " ++ String.fromInt currentLine ++ " / " ++ String.fromInt totalLines)
                , Ui.iconButton [ Font.color Colors.navbar ]
                    { onPress = Just (Core.AcquisitionMsg Acquisition.DecreasePromptSize)
                    , text = Nothing
                    , tooltip = Just (Lang.zoomOut global.lang)
                    , icon = Fa.searchMinus
                    }
                , Ui.iconButton [ Font.color Colors.navbar ]
                    { onPress = Just (Core.AcquisitionMsg Acquisition.IncreasePromptSize)
                    , text = Nothing
                    , tooltip = Just (Lang.zoomIn global.lang)
                    , icon = Fa.searchPlus
                    }
                ]

        fullPrompt =
            if noPrompt then
                Element.none

            else
                Element.column
                    [ Ui.wf
                    , Ui.hf
                    , Background.color Colors.black
                    , Element.padding 10
                    , Element.spacing 20
                    ]
                    [ promptText, nextPromptText ]
    in
    Element.row (tern noPrompt [ Ui.wf ] [ Ui.wf, Ui.hf ])
        [ Element.el
            [ Ui.wf, Element.alignTop, Element.padding 10 ]
            (Element.column [ Element.spacing 10 ] (List.map Element.text (Lang.shortcuts global.lang)))
        , Element.column
            [ Ui.wfp 3, Ui.hf ]
            (tern global.acquisitionInverted [ info, fullPrompt ] [ fullPrompt, info ])
        , Element.el [ Ui.wf ] Element.none
        ]


toolbarElement : Core.Global -> User -> Acquisition.Submodel -> Element Core.Msg
toolbarElement global user model =
    if not (User.isPremium user) then
        Element.none

    else
        let
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

            colorToButton : Element.Color -> Element Core.Msg
            colorToButton color =
                Input.button [ Ui.wf, Element.height (Element.px 45) ]
                    { label = Element.el [ Ui.wf, Ui.hf, Background.color color ] Element.none
                    , onPress =
                        colorToString color
                            |> Acquisition.ChangeColor
                            |> Acquisition.SetCanvas
                            |> Core.AcquisitionMsg
                            |> Just
                    }

            mkMsg : Acquisition.SetCanvas -> Maybe Core.Msg
            mkMsg style =
                style
                    |> Acquisition.SetCanvas
                    |> Core.AcquisitionMsg
                    |> Just
        in
        Element.column [ Element.centerY ]
            [ Element.row [ Ui.wf, Element.spacing 5 ]
                [ Element.el [ Ui.wf, Element.height (Element.px 45) ]
                    (Element.el [ Element.centerX, Element.centerY, Font.color Colors.navbar, Font.size 30 ]
                        (Ui.iconButton []
                            { icon = Fa.bullseye
                            , onPress = mkMsg (Acquisition.ChangeStyle Acquisition.Pointer)
                            , text = Nothing
                            , tooltip = Nothing
                            }
                        )
                    )
                , Element.el [ Ui.wf, Element.height (Element.px 45) ]
                    (Element.el [ Element.centerX, Element.centerY, Font.color Colors.navbar, Font.size 30 ]
                        (Ui.iconButton []
                            { icon = Fa.paintBrush
                            , onPress = mkMsg (Acquisition.ChangeStyle Acquisition.Brush)
                            , text = Nothing
                            , tooltip = Nothing
                            }
                        )
                    )
                ]
            , Element.row [ Ui.wf, Element.spacing 5 ]
                [ Element.el [ Ui.wf, Element.height (Element.px 45) ]
                    (Element.el [ Element.centerX, Element.centerY, Font.color Colors.navbar, Font.size 30 ]
                        (Ui.iconButton []
                            { icon = Fa.eraser
                            , onPress = mkMsg Acquisition.Erase
                            , text = Nothing
                            , tooltip = Nothing
                            }
                        )
                    )
                , Element.el [ Ui.wf, Element.height (Element.px 45) ] Element.none
                ]
            , Element.row [ Ui.wf, Element.spacing 5 ]
                [ Element.el [ Ui.wf, Element.height (Element.px 45) ]
                    (Element.el [ Element.centerX, Element.centerY, Font.color Colors.navbar, Font.size 30 ]
                        (Ui.iconButton []
                            { icon = Fa.circle
                            , onPress = mkMsg (Acquisition.ChangeSize 20)
                            , text = Nothing
                            , tooltip = Nothing
                            }
                        )
                    )
                , Element.el [ Ui.wf, Element.height (Element.px 45) ]
                    (Element.el [ Element.centerX, Element.centerY, Font.color Colors.navbar, Font.size 30 ]
                        (Ui.iconButton []
                            { icon = Fa.circle
                            , onPress = mkMsg (Acquisition.ChangeSize 40)
                            , text = Nothing
                            , tooltip = Nothing
                            }
                        )
                    )
                ]
            , palette
                |> List.map (\( x, y ) -> Element.row [ Element.spacing 5, Ui.wf, Ui.hf ] [ colorToButton x, colorToButton y ])
                |> Element.column [ Element.width (Element.px 100), Element.spacing 5, Element.padding 5 ]
            ]


slideElement : Core.Global -> User -> Acquisition.Submodel -> Element Core.Msg
slideElement global user model =
    let
        slides : List Capsule.Slide
        slides =
            List.drop model.gos model.capsule.structure |> List.head |> Maybe.map .slides |> Maybe.withDefault []

        currentSlide : Maybe Capsule.Slide
        currentSlide =
            List.head (List.drop model.currentSlide slides)
    in
    case ( currentSlide, Maybe.andThen .extra currentSlide ) of
        ( _, Just s ) ->
            let
                src =
                    "/data/" ++ model.capsule.id ++ "/assets/" ++ s ++ ".mp4"
            in
            Element.row [ Ui.hfp 2, Ui.wf, Element.htmlAttribute (Html.Attributes.style "display" "flex") ]
                [ Element.el [ Ui.wf ] Element.none
                , Element.el [ Ui.wfp 2 ]
                    (Element.html
                        (Html.video
                            [ Html.Attributes.attribute "muted" ""
                            , Html.Attributes.id extraId
                            , Html.Attributes.class "wf"
                            ]
                            [ Html.source [ Html.Attributes.src src ] [] ]
                        )
                    )
                , Element.el [ Ui.wf ] Element.none
                ]

        ( Just s, Nothing ) ->
            Element.column [ Ui.wf, Ui.hfp 2 ]
                [ Element.el [ Ui.hf ] Element.none
                , Element.image
                    [ Ui.wf
                    , Ui.hf
                    , Element.htmlAttribute (Html.Attributes.id "slideimg")
                    , Element.inFront (Element.html (Html.canvas [ Html.Attributes.id "pointer-canvas" ] []))
                    ]
                    { description = "slide", src = Capsule.slidePath model.capsule s }
                , Element.el [ Ui.hf ] Element.none
                ]

        _ ->
            Element.none


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


videoId : String
videoId =
    "video"


extraId : String
extraId =
    "extra"


videoElement : List (Element.Attribute Core.Msg) -> Element Core.Msg
videoElement attr =
    Element.html (Html.video [ Html.Attributes.class "wf", Html.Attributes.id videoId ] [])


paragraph : Element Core.Msg -> Element Core.Msg
paragraph x =
    Element.paragraph [] [ x ]
