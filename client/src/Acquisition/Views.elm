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
import Html.Events
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
view : Config -> User -> Acquisition.Model Data.Capsule Data.Gos -> ( Element App.Msg, Element App.Msg, Element App.Msg )
view config _ model =
    let
        -- Shortcut for lang
        lang =
            config.clientState.lang

        -- Shortcut for the current slide
        currentSlide : Maybe Data.Slide
        currentSlide =
            List.head (List.drop model.currentSlide model.gos.slides)

        -- Formats a view of a record, whether it is on the client or on the server
        recordView : Int -> Acquisition.Record -> Element App.Msg
        recordView index record =
            let
                -- Play button
                playButton : Element App.Msg
                playButton =
                    let
                        isPlaying =
                            case model.recordPlaying of
                                Just ( recordIndex, _ ) ->
                                    index == recordIndex

                                Nothing ->
                                    False

                        action =
                            if isPlaying || model.recording /= Nothing then
                                Ui.None

                            else
                                Ui.Msg <| App.AcquisitionMsg <| Acquisition.PlayRecord ( index, record )
                    in
                    Ui.secondaryIcon []
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
                                Just ( recordIndex, _ ) ->
                                    index == recordIndex

                                Nothing ->
                                    False

                        action =
                            if isPlaying then
                                Ui.Msg <| App.AcquisitionMsg <| Acquisition.StopRecord

                            else
                                Ui.None
                    in
                    Ui.secondaryIcon []
                        { icon = Material.Icons.stop
                        , tooltip = Strings.stepsAcquisitionStopRecord lang
                        , action = action
                        }

                -- Label of the record
                label : String
                label =
                    if record.old then
                        Strings.stepsAcquisitionSavedRecord lang

                    else if List.any (\r -> r.old) model.records then
                        String.fromInt index

                    else
                        String.fromInt <| index + 1

                -- Button to add pointer to a specific record
                pointerButton : Element App.Msg
                pointerButton =
                    Ui.secondaryIcon []
                        { icon = Material.Icons.gps_fixed
                        , tooltip = Strings.stepsAcquisitionRecordPointer lang
                        , action =
                            if model.recordPlaying /= Nothing || model.recording /= Nothing then
                                Ui.None

                            else
                                Ui.Msg <| App.AcquisitionMsg <| Acquisition.StartPointerRecording index record
                        }

                -- Delete or validate button
                delValButton : Element App.Msg
                delValButton =
                    Utils.tern
                        record.old
                        (Ui.secondaryIcon []
                            { icon = Material.Icons.delete
                            , tooltip = Strings.stepsAcquisitionDeleteRecord lang
                            , action = Ui.Msg <| App.AcquisitionMsg <| Acquisition.DeleteRecord Utils.Request
                            }
                        )
                        (Ui.primaryIcon []
                            { icon = Material.Icons.done
                            , tooltip = Strings.stepsAcquisitionValidateRecord lang
                            , action = Ui.Msg <| App.AcquisitionMsg <| Acquisition.UploadRecord record
                            }
                        )
            in
            Element.el [ Element.paddingXY 10 0, Ui.wf ] <|
                Element.el [ Element.paddingXY 5 10, Ui.wf, Ui.r 10, Ui.b 1, Border.color Colors.greyBorder ] <|
                    Element.row [ Ui.wf, Ui.s 10 ]
                        [ Ui.longText [] label
                        , Element.text (TimeUtils.formatDuration (Acquisition.recordDuration record))
                        , playButton
                        , stopButton
                        , pointerButton
                        , delValButton
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
                        , label = Element.text <| Strings.uiCancel lang
                        }
                    , Ui.primary []
                        { action = mkUiMsg (Acquisition.DeleteRecord Utils.Confirm)
                        , label = Element.text <| Strings.uiConfirm lang
                        }
                    ]
                ]
                |> Ui.popup 1 (Strings.actionsDeleteRecord lang)

        -- Popup to warn the user that they're leaving and that they might lose their record
        warnLeavingPopup : Element App.Msg
        warnLeavingPopup =
            Element.column [ Ui.wf, Ui.hf ]
                [ Element.paragraph [ Ui.wf, Ui.cy, Font.center ]
                    [ Element.text (Lang.question Strings.stepsAcquisitionNonValidatedRecordsWillBeLost lang) ]
                , Element.row [ Ui.ab, Ui.ar, Ui.s 10 ]
                    [ Ui.secondary []
                        { action = mkUiMsg (Acquisition.Leave Utils.Cancel)
                        , label = Element.text <| Strings.uiCancel lang
                        }
                    , Ui.primary []
                        { action = mkUiMsg (Acquisition.Leave Utils.Confirm)
                        , label = Element.text <| Strings.uiConfirm lang
                        }
                    ]
                ]
                |> Ui.popup 1 (Strings.uiWarning lang)

        -- Popup to show the help to the user
        helpPopup : Element App.Msg
        helpPopup =
            Element.column [ Ui.wf, Ui.hf, Ui.s 30 ]
                [ Ui.paragraph [ Ui.wf, Ui.cy, Font.center ] <| Strings.stepsAcquisitionHelpFirst lang ++ "."
                , Ui.paragraph [ Ui.wf, Ui.cy, Font.center ] <| Strings.stepsAcquisitionHelpSecond lang ++ "."
                , Ui.paragraph [ Ui.wf, Ui.cy, Font.center ] <| Strings.stepsAcquisitionHelpThird lang ++ "."
                , Ui.paragraph [ Ui.wf, Ui.cy, Font.center ] <| Strings.stepsAcquisitionHelpFourth lang ++ "."
                , Ui.primary [ Ui.ab, Ui.ar ]
                    { action = Ui.Msg <| App.AcquisitionMsg <| Acquisition.ToggleHelp
                    , label = Element.text <| Strings.uiConfirm lang
                    }
                ]
                |> Ui.popup 2 (Strings.uiHelp lang)

        -- Column that contains the device feedback element, the info, and the list of records
        rightColumn : Element App.Msg
        rightColumn =
            Element.el [ Ui.wf, Ui.hf, Ui.bl 1, Border.color Colors.greyBorder ] <|
                Element.column
                    [ Ui.wf, Ui.s 10 ]
                    ((if not model.showSettings then
                        devicePlayer config model

                      else
                        Element.none
                     )
                        :: deviceInfo config
                        :: Element.el
                            [ Ui.wf
                            , Element.paddingEach { top = 10, bottom = 0, left = 10, right = 10 }
                            , Ui.bt 1
                            , Border.color Colors.greyBorder
                            ]
                            (Ui.title (Strings.stepsAcquisitionRecordList lang 2))
                        :: List.indexedMap recordView (List.reverse model.records)
                    )

        -- Displays the recording status
        statusElement : Element App.Msg
        statusElement =
            Element.row [ Ui.wf, Ui.p 10 ]
                [ Element.el [ Ui.cx ] <|
                    let
                        slideIndexDisplay =
                            String.fromInt (model.currentSlide + 1)
                                ++ " / "
                                ++ String.fromInt (List.length model.gos.slides)

                        slideIndexElement =
                            Strings.dataCapsuleSlide lang 1
                                ++ " "
                                ++ slideIndexDisplay
                                |> Element.text

                        lineIndexElement =
                            Strings.dataCapsuleLine lang 1
                                ++ " "
                                ++ lineIndexDisplay
                                |> Element.text

                        promptLength =
                            currentSlide
                                |> Maybe.map .prompt
                                |> Maybe.withDefault ""
                                |> String.split "\n"
                                |> List.length
                                |> String.fromInt

                        lineIndexDisplay =
                            String.fromInt (model.currentSentence + 1) ++ " / " ++ promptLength
                    in
                    case model.recording of
                        Just t ->
                            Element.row [ Ui.s 30 ]
                                [ Element.el [ Ui.class "blink", Font.color Colors.red ] (Element.text "⬤ REC")
                                , slideIndexElement
                                , lineIndexElement
                                , (Time.posixToMillis config.clientState.time - Time.posixToMillis t)
                                    |> TimeUtils.formatDuration
                                    |> Element.text
                                    |> Element.el [ Element.width (Element.minimum 50 Element.shrink) ]
                                ]

                        Nothing ->
                            Element.row [ Ui.s 30 ]
                                [ Element.text (Strings.stepsAcquisitionReadyForRecording lang)
                                , slideIndexElement
                                , lineIndexElement
                                , Ui.primaryIcon []
                                    { icon = Material.Icons.help_outline
                                    , tooltip = Strings.uiHelp lang
                                    , action = Ui.Msg <| App.AcquisitionMsg <| Acquisition.ToggleHelp
                                    }
                                ]
                ]

        -- Displays the current slide
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

        -- Full content of the page
        content =
            Element.column [ Ui.wf, Ui.hf ]
                [ promptElement config model
                , statusElement
                , Element.row
                    [ Ui.wf, Ui.hf ]
                    [ pointerControl model
                    , slideElement
                    ]
                ]

        -- Settings popup or popup to confirm the deletion of a record
        popup =
            if model.showSettings then
                settingsPopup config model

            else if model.deleteRecord then
                deleteRecordPopup

            else if model.warnLeaving /= Nothing then
                warnLeavingPopup

            else if model.showHelp then
                helpPopup

            else
                Element.none
    in
    ( content, rightColumn, popup )


{-| Shows the element that contains the prompt text.
-}
promptElement : Config -> Acquisition.Model Data.Capsule Data.Gos -> Element App.Msg
promptElement _ model =
    let
        -- Whether a prompt exists in the grain
        hasPrompt : Bool
        hasPrompt =
            model.gos.slides |> List.map .prompt |> List.any (\x -> x /= "")

        -- The current slide (Nothing should be unreachable)
        currentSlide : Maybe Data.Slide
        currentSlide =
            List.head (List.drop model.currentSlide model.gos.slides)

        -- The next slide of the grain if the current slide is not the last one
        nextSlide : Maybe Data.Slide
        nextSlide =
            List.head (List.drop (model.currentSlide + 1) model.gos.slides)

        -- Helper to extract the nth line of the prompt text of a slide
        getLine : Int -> Data.Slide -> Maybe String
        getLine n x =
            List.head (List.drop n (String.split "\n" x.prompt))

        -- The sentence that is just before the current sentence
        -- previousSentence : Maybe String
        -- previousSentence =
        --     Maybe.withDefault Nothing (Maybe.map (getLine (model.currentSentence - 1)) currentSlide)
        --
        --
        -- The current sentence
        currentSentence : Maybe String
        currentSentence =
            case model.currentReplacementPrompt of
                Just s ->
                    Just s

                _ ->
                    Maybe.withDefault Nothing (Maybe.map (getLine model.currentSentence) currentSlide)

        -- The next sentence of the current slide if any
        nextSentenceCurrentSlide : Maybe String
        nextSentenceCurrentSlide =
            Maybe.withDefault Nothing (Maybe.map (getLine (model.currentSentence + 1)) currentSlide)

        -- Either the next sentence of the current slide if the current slide has a next sentence, or the first sentence
        -- of the next slide of the same grain if there is a next slide that has a prompt
        nextSentence : Maybe String
        nextSentence =
            let
                tmp =
                    nextSlide
                        |> Maybe.map (\x -> List.head (String.split "\n" x.prompt))
                        |> Maybe.withDefault Nothing
            in
            case ( model.nextReplacementPrompt, nextSentenceCurrentSlide ) of
                ( Just s, _ ) ->
                    Just s

                ( _, Nothing ) ->
                    tmp

                ( _, x ) ->
                    x

        -- A small icon that indicates to the speaker that the next sentence belongs to the next slide
        -- nextSlideIcon =
        --     if nextSentenceCurrentSlide == Nothing && nextSentence /= Nothing then
        --         Ui.icon 40 Material.Icons.arrow_circle_right
        --             |> Element.el [ Element.paddingEach { right = 10, left = 0, top = 0, bottom = 0 } ]
        --     else
        --         Element.none
        --
        --
        -- Display navigation buttons that let the user move around the prompt text even if they're not recording
        navigationButtons =
            Element.row [ Ui.ab, Ui.wf ]
                [ case ( model.recording, model.currentSentence > 0 && model.recording == Nothing ) of
                    ( Nothing, True ) ->
                        Ui.navigationElement
                            (Ui.Msg <| App.AcquisitionMsg <| Acquisition.PreviousSentence)
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
                    Ui.icon 25 Material.Icons.navigate_before
                        |> Element.el [ Element.htmlAttribute (Html.Attributes.style "visibility" "hidden") ]
                ]

        -- Displays the current line of the prompt text
        currentSentencePrompt : String -> Element App.Msg
        currentSentencePrompt s =
            Element.el [ Ui.cx, Font.center, Font.size 40 ]
                (Input.multiline
                    [ Background.color Colors.black
                    , Ui.b 0
                    , Ui.id Acquisition.promptFirstSentenceId
                    , Element.htmlAttribute (Html.Attributes.style "-moz-text-align-last" "center")
                    , Element.htmlAttribute (Html.Attributes.style "text-align-last" "center")
                    , Element.htmlAttribute <| Html.Events.onFocus <| App.AcquisitionMsg <| Acquisition.StartEditingPrompt
                    , Element.htmlAttribute <| Html.Events.onBlur <| App.AcquisitionMsg <| Acquisition.StopEditingPrompt
                    ]
                    { label = Input.labelHidden ""
                    , onChange = \x -> App.AcquisitionMsg (Acquisition.CurrentSentenceChanged x)
                    , placeholder = Nothing
                    , text = s
                    , spellcheck = False
                    }
                )

        -- Displays the next line of the prompt text
        nextSentencePrompt : String -> Element App.Msg
        nextSentencePrompt s =
            Element.el [ Ui.cx, Font.center, Font.size 40, Font.color (Colors.grey 5) ]
                (Input.multiline
                    [ Font.center
                    , Background.color Colors.black
                    , Ui.b 0
                    , Ui.id Acquisition.promptSecondSentenceId
                    , Element.htmlAttribute (Html.Attributes.style "-moz-text-align-last" "center")
                    , Element.htmlAttribute (Html.Attributes.style "text-align-last" "center")
                    , Element.htmlAttribute <| Html.Events.onFocus <| App.AcquisitionMsg <| Acquisition.StartEditingSecondPrompt
                    , Element.htmlAttribute <| Html.Events.onBlur <| App.AcquisitionMsg <| Acquisition.StopEditingSecondPrompt
                    ]
                    { label = Input.labelHidden ""
                    , onChange = \x -> App.AcquisitionMsg <| Acquisition.NextSentenceChanged x
                    , placeholder = Nothing
                    , spellcheck = False
                    , text = s
                    }
                )
    in
    case ( hasPrompt, currentSentence ) of
        ( False, _ ) ->
            Element.none

        ( _, Just s ) ->
            Element.column [ Ui.wf, Background.color Colors.black, Font.color Colors.white, Ui.p 10, Ui.s 10 ]
                [ currentSentencePrompt s
                , Maybe.withDefault "" nextSentence |> nextSentencePrompt
                , navigationButtons
                ]

        _ ->
            Element.none


{-| Element that displays the info about the seleected device
-}
deviceInfo : Config -> Element App.Msg
deviceInfo config =
    let
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

        -- Text that displays the preferred video device
        preferredVideoElement : Element App.Msg
        preferredVideoElement =
            preferredVideo
                |> Maybe.map Tuple.first
                |> Maybe.map .label
                |> Maybe.withDefault (Strings.deviceDisabled lang)
                |> Ui.paragraph []

        -- Text that displays the preferred resolution
        preferredResolutionElement : Element App.Msg
        preferredResolutionElement =
            preferredVideo
                |> Maybe.map Tuple.second
                |> Maybe.map (\r -> String.fromInt r.width ++ "x" ++ String.fromInt r.height)
                |> Maybe.map (Ui.paragraph [])
                |> Maybe.withDefault Element.none

        -- Text that displays the preferred audio device
        preferredAudioElement : Element App.Msg
        preferredAudioElement =
            preferredAudio
                |> Maybe.map .label
                |> Maybe.withDefault (Strings.deviceDisabled lang)
                |> Ui.paragraph []
    in
    Element.column [ Ui.wf, Ui.px 10, Ui.s 5, Ui.at ]
        [ Ui.title (Strings.deviceWebcam lang)
        , preferredVideoElement
        , Ui.title (Strings.deviceResolution lang) |> Utils.tern (preferredVideo == Nothing) Element.none
        , preferredResolutionElement
        , Ui.title (Strings.deviceMicrophone lang)
        , preferredAudioElement
        ]


{-| Creates a HTML video element on which the device feedback will be displayed.
-}
devicePlayer : Config -> Acquisition.Model Data.Capsule Data.Gos -> Element App.Msg
devicePlayer config model =
    let
        -- Shortcut for lang
        lang =
            config.clientState.lang

        -- Shortcut for the preferred video device
        preferredVideo : Maybe ( Device.Video, Device.Resolution )
        preferredVideo =
            Maybe.andThen .video config.clientConfig.preferredDevice

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
            case ( model.state, preferredVideo ) of
                ( Acquisition.DetectingDevices, _ ) ->
                    [ Ui.spinningSpinner [ Font.color Colors.white, Ui.cx, Ui.cy ] 50
                    , Ui.paragraph [ Font.center ] (Strings.stepsAcquisitionBindingWebcam lang)
                    ]
                        |> Element.column [ Ui.cx, Ui.cy, Ui.s 10, Font.color Colors.white ]
                        |> Element.el [ Ui.wf, Ui.hf, Background.color Colors.black ]

                ( Acquisition.BindingWebcam, _ ) ->
                    [ Ui.spinningSpinner [ Font.color Colors.white, Ui.cx, Ui.cy ] 50
                    , Ui.paragraph [ Font.center ] (Strings.stepsAcquisitionBindingWebcam lang)
                    ]
                        |> Element.column [ Ui.cx, Ui.cy, Ui.s 10, Font.color Colors.white ]
                        |> Element.el [ Ui.wf, Ui.hf, Background.color Colors.black ]

                ( Acquisition.Error, _ ) ->
                    [ Element.el [ Ui.cx, Ui.cy ] <| Ui.icon 50 Material.Icons.videocam_off
                    , Ui.paragraph [ Font.center ] (Strings.stepsAcquisitionErrorBindingWebcam lang ++ ".")
                    , Ui.paragraph [ Font.center ] (Lang.question Strings.stepsAcquisitionIsWebcamUsed lang)
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
            if not model.showSettings then
                Ui.navigationElement
                    (Ui.Msg <| App.AcquisitionMsg <| Acquisition.ToggleSettings)
                    [ Font.color Colors.white, Ui.ab, Ui.ar, Ui.p 10 ]
                    (Ui.icon 25 Material.Icons.settings)

            else
                Element.none

        -- Element that shows the device feedback to the user
        player : Element App.Msg
        player =
            Element.el
                [ Ui.wf
                , Ui.at
                , Element.inFront inFrontElement
                , Element.inFront vumeterElement
                , Element.inFront settingsElement
                ]
                (Element.html (Html.video [ Html.Attributes.class "wf", Html.Attributes.id "video" ] []))
    in
    player


{-| Creates the settings popup, with all the information about the different devices.
-}
settingsPopup : Config -> Acquisition.Model Data.Capsule Data.Gos -> Element App.Msg
settingsPopup config model =
    let
        -- Shortcut for lang
        lang =
            config.clientState.lang

        -- Shortcut for the preferred video device
        preferredVideo : Maybe ( Device.Video, Device.Resolution )
        preferredVideo =
            Maybe.andThen .video config.clientConfig.preferredDevice

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

        -- Title before the reinit everything button
        reinitTitle : Element App.Msg
        reinitTitle =
            Ui.title <| Strings.stepsAcquisitionReinitializeDevices lang

        -- Button that reinitializes the camera detection
        reinitButton : Element App.Msg
        reinitButton =
            Ui.primary []
                { label = Element.text <| Strings.stepsAcquisitionReinitializeDevices lang
                , action = Ui.Msg <| App.AcquisitionMsg <| Acquisition.ReinitializeDevices
                }

        -- Element that contains all the device settings
        settings : Element App.Msg
        settings =
            Element.column [ Ui.wf, Ui.cy, Ui.s 20 ]
                [ Element.column [ Ui.wf, Ui.s 10 ] [ videoTitle, video ]
                , Element.column [ Ui.wf, Ui.s 10 ] [ resolutionTitle, resolution ]
                , Element.column [ Ui.wf, Ui.s 10 ] [ audioTitle, audio ]
                , Element.column [ Ui.wf, Ui.s 10 ] [ reinitTitle, reinitButton ]
                ]
    in
    Element.column [ Ui.wf, Ui.hf, Element.scrollbars ]
        [ Element.row [ Ui.wf, Ui.hf, Element.scrollbars ]
            [ Element.el [ Ui.wf, Ui.hf, Element.scrollbars ] settings
            , Element.el [ Ui.wf ] <| devicePlayer config model
            ]
        , Ui.primary [ Ui.ab, Ui.ar ]
            { label = Element.text <| Strings.uiConfirm lang
            , action = Ui.Msg <| App.AcquisitionMsg <| Acquisition.ToggleSettings
            }
        ]
        |> Ui.popup 5 (Strings.navigationSettings lang)


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
                { label = Element.text <| Maybe.withDefault (Strings.deviceDisabled lang) <| Maybe.map .label video
                , action = action
                }
    in
    button


{-| Displays a button to select a specific video resolution.
-}
videoResolutionView : Lang -> ( Device.Video, Device.Resolution ) -> Device.Resolution -> Element App.Msg
videoResolutionView _ ( preferredVideo, preferredResolution ) resolution =
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
        { label = Element.text <| Device.formatResolution resolution
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
    makeButton [] { label = Element.text <| audio.label, action = action }


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


{-| Element to control the style of the pointer.
-}
pointerControl : Acquisition.Model Data.Capsule Data.Gos -> Element App.Msg
pointerControl model =
    let
        colorToButton : Element.Color -> Element App.Msg
        colorToButton color =
            let
                borderColor : Element.Color
                borderColor =
                    Utils.tern (Colors.colorToString color == model.pointerStyle.color) Colors.green2 (Colors.alpha 0.3)
            in
            Ui.navigationElement
                (Ui.Msg <| App.AcquisitionMsg <| Acquisition.SetPointerColor <| Colors.colorToString color)
                [ Background.color color
                , Ui.r 10
                , Ui.b 4
                , Border.color borderColor
                , Border.shadow
                    { offset = ( 0.0, 0.0 )
                    , size = 1.0
                    , blur = 4.0
                    , color = Colors.alpha 0.4
                    }
                ]
                (Element.el
                    [ Ui.wpx 35
                    , Ui.hpx 35
                    , Ui.r 6
                    , Element.mouseOver [ Background.color <| Colors.alpha 0.2 ]
                    ]
                    Element.none
                )
    in
    Element.column [ Ui.cy, Ui.p 5, Ui.s 8 ]
        [ Element.column [ Ui.s 8 ]
            [ Element.row [ Ui.s 8 ]
                [ Ui.navigationElement
                    (Ui.Msg <| App.AcquisitionMsg <| Acquisition.SetPointerMode <| Acquisition.Pointer)
                    [ Ui.r 10
                    , Border.color <|
                        Utils.tern
                            (model.pointerStyle.mode == Acquisition.Pointer)
                            Colors.green2
                            (Colors.alpha 0.1)
                    , Ui.b 4
                    , Font.color Colors.green2
                    , Element.mouseOver [ Background.color <| Colors.alpha 0.1 ]
                    , Border.shadow
                        { offset = ( 0.0, 0.0 )
                        , size = 1.0
                        , blur = 4.0
                        , color = Colors.alpha 0.4
                        }
                    ]
                    (Ui.icon 35 Material.Icons.gps_fixed)
                , Ui.navigationElement
                    (Ui.Msg <| App.AcquisitionMsg <| Acquisition.SetPointerMode <| Acquisition.Brush)
                    [ Ui.r 10
                    , Border.color <|
                        Utils.tern
                            (model.pointerStyle.mode == Acquisition.Brush)
                            Colors.green2
                            (Colors.alpha 0.1)
                    , Ui.b 4
                    , Font.color Colors.green2
                    , Element.mouseOver [ Background.color <| Colors.alpha 0.1 ]
                    , Border.shadow
                        { offset = ( 0.0, 0.0 )
                        , size = 1.0
                        , blur = 4.0
                        , color = Colors.alpha 0.4
                        }
                    ]
                    (Ui.icon 35 Material.Icons.brush)
                ]
            , Element.row [ Ui.s 8 ]
                [ Ui.navigationElement
                    (Ui.Msg <| App.AcquisitionMsg <| Acquisition.ClearPointer)
                    [ Ui.r 10
                    , Border.color <| Colors.alpha 0.1
                    , Ui.b 4
                    , Font.color Colors.green2
                    , Element.mouseOver [ Background.color <| Colors.alpha 0.1 ]
                    , Border.shadow
                        { offset = ( 0.0, 0.0 )
                        , size = 1.0
                        , blur = 4.0
                        , color = Colors.alpha 0.4
                        }
                    ]
                    (Ui.icon 35 Material.Icons.recycling)
                , Element.el [ Ui.wpx 45, Ui.hpx 45 ] <|
                    Element.el
                        [ Ui.wpx (model.pointerStyle.size * 2)
                        , Ui.hpx (model.pointerStyle.size * 2)
                        , Ui.r 100
                        , Ui.cy
                        , Ui.cx
                        , Background.color Colors.green2
                        ]
                        Element.none
                ]
            , Element.row [ Ui.s 8 ]
                [ Ui.navigationElement
                    (Ui.Msg <| App.AcquisitionMsg <| Acquisition.SetPointerSize <| model.pointerStyle.size - 5)
                    [ Ui.r 10
                    , Border.color <| Colors.alpha 0.1
                    , Ui.b 4
                    , Font.color Colors.green2
                    , Element.mouseOver [ Background.color <| Colors.alpha 0.1 ]
                    , Border.shadow
                        { offset = ( 0.0, 0.0 )
                        , size = 1.0
                        , blur = 4.0
                        , color = Colors.alpha 0.4
                        }
                    ]
                    (Ui.icon 35 Material.Icons.remove)
                , Ui.navigationElement
                    (Ui.Msg <| App.AcquisitionMsg <| Acquisition.SetPointerSize <| model.pointerStyle.size + 5)
                    [ Ui.r 10
                    , Border.color <| Colors.alpha 0.1
                    , Ui.b 4
                    , Font.color Colors.green2
                    , Element.mouseOver [ Background.color <| Colors.alpha 0.1 ]
                    , Border.shadow
                        { offset = ( 0.0, 0.0 )
                        , size = 1.0
                        , blur = 4.0
                        , color = Colors.alpha 0.4
                        }
                    ]
                    (Ui.icon 35 Material.Icons.add)
                ]
            ]
        , palette
            |> List.map (\( x, y ) -> Element.row [ Ui.s 8 ] [ colorToButton x, colorToButton y ])
            |> Element.column [ Ui.s 8 ]
        ]


{-| Palette of colors that can be used for pointer.
-}
palette : List ( Element.Color, Element.Color )
palette =
    [ ( Element.rgb255 255 0 0, Element.rgb255 0 0 255 )
    , ( Element.rgb255 0 255 0, Element.rgb255 255 255 0 )
    , ( Element.rgb255 0 255 255, Element.rgb255 255 128 0 )
    ]


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
