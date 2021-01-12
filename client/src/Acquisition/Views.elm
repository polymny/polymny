module Acquisition.Views exposing (audioDropdownConfig, resolutionDropdownConfig, subscriptions, videoDropdownConfig, view)

import Acquisition.Types as Acquisition
import Api
import Core.Types as Core
import Dropdown
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Keyed
import FontAwesome
import Html
import Html.Attributes
import Keyboard
import LoggedIn.Types as LoggedIn
import Preparation.Views as Preparation
import Status
import Ui.Colors as Colors
import Ui.Icons
import Ui.Ui as Ui


mkmsg : Acquisition.Model -> Acquisition.Msg -> Core.Msg
mkmsg model msg =
    if model.cameraReady then
        Core.LoggedInMsg (LoggedIn.AcquisitionMsg msg)

    else
        Core.Noop


shortcuts : Acquisition.Model -> Keyboard.RawKey -> Core.Msg
shortcuts model msg =
    let
        raw =
            Keyboard.rawValue msg
    in
    case raw of
        " " ->
            mkmsg model
                (if model.recording then
                    Acquisition.StopRecording

                 else
                    Acquisition.StartRecording
                )

        "ArrowRight" ->
            mkmsg model Acquisition.NextSentence

        _ ->
            Core.Noop


subscriptions : Acquisition.Model -> Sub Core.Msg
subscriptions model =
    Sub.batch
        [ Keyboard.ups (shortcuts model)
        ]


view : Core.Global -> Api.Session -> Acquisition.Model -> ( Element Core.Msg, Maybe (Element Core.Msg) )
view _ _ model =
    let
        attributes =
            Element.height Element.fill
                :: (if model.cameraReady then
                        []

                    else
                        [ Element.htmlAttribute (Html.Attributes.style "visibility" "hidden") ]
                   )

        popup =
            case ( model.status, model.showSettings ) of
                ( Status.Sent, _ ) ->
                    Element.column [ Element.width Element.fill, Element.padding 10, Element.spacing 10 ]
                        [ Element.paragraph [ Element.centerX, Font.center ] [ Element.text "Envoi de l'enregistrement en cours." ]
                        , Element.paragraph [ Element.centerX, Font.center ] [ Element.text "Le temps de transfert peut être long, notamment si l'enregistrement est long ou si la connexion est lente (par exemple ADSL)" ]
                        , Element.el [ Element.centerX ] Ui.spinner
                        ]
                        |> Element.el [ Element.centerX, Element.centerY ]
                        |> Element.el
                            [ Element.width Element.fill
                            , Element.height Element.fill
                            , Background.color Colors.light
                            ]
                        |> Ui.popup "Envoi de l'enregistrement"
                        |> Just

                ( _, Just ( videoDropdown, resolutionDropdown, audioDropdown ) ) ->
                    let
                        toggleMsg =
                            Acquisition.ToggleSettings
                                |> LoggedIn.AcquisitionMsg
                                |> Core.LoggedInMsg
                                |> Just

                        popupElement =
                            Element.row [ Element.centerY, Element.width Element.fill, Element.spacing 10 ]
                                [ Element.column [ Element.width Element.fill, Element.padding 20, Element.spacing 10 ]
                                    [ Element.column [ Element.width Element.fill ]
                                        [ Element.text "Caméras disponibles"
                                        , Dropdown.view videoDropdownConfig videoDropdown model.devices.video
                                        ]
                                    , case Acquisition.video model of
                                        Just (Just video) ->
                                            Element.column [ Element.width Element.fill ]
                                                [ Element.text "Résolutions disponibles"
                                                , Dropdown.view resolutionDropdownConfig resolutionDropdown video.resolutions
                                                ]

                                        _ ->
                                            Element.none
                                    , Element.column [ Element.width Element.fill ]
                                        [ Element.text "Microphones disponibles"
                                        , Dropdown.view audioDropdownConfig audioDropdown model.devices.audio
                                        ]
                                    , case model.device of
                                        ( Just Nothing, _, Just Nothing ) ->
                                            Element.text "Vous devez au moins activer la webcam ou le micro"

                                        _ ->
                                            Ui.primaryButton toggleMsg "Valider"
                                    ]
                                , Element.el [ Element.width Element.fill ] videoElement
                                ]
                    in
                    Just (Ui.popupWithSize 5 "Paramètres" popupElement)

                _ ->
                    Nothing
    in
    ( Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.scrollbarY
        ]
        [ Preparation.leftColumnView model.details (Just model.gos)
        , Element.el (Element.width (Element.fillPortion 6) :: attributes) (centerView model)
        , Element.el (Element.width (Element.fillPortion 1) :: attributes) (rightColumn model)
        ]
    , popup
    )



-- element =
--     Element.row
--         [ Element.width Element.fill
--         , Element.height Element.fill
--         , Element.scrollbarY
--         ]
--         [ Preparation.leftColumnView model.details (Just model.gos)
--         , Element.el (Element.width (Element.fillPortion 6) :: attributes) (centerView model)
--         , Element.el (Element.width (Element.fillPortion 1) :: attributes) (rightColumn model)
--         ]
-- popup =
--     if model.status == Status.Sent then
--         --     else
--         Nothing
-- in
-- ( element, popup )


centerView : Acquisition.Model -> Element Core.Msg
centerView model =
    Element.column [ Element.width Element.fill, Element.height Element.fill ]
        [ promptView model
        , slideView model
        ]


promptView : Acquisition.Model -> Element Core.Msg
promptView model =
    let
        promptAttributes : List (Element.Attribute Core.Msg)
        promptAttributes =
            [ Font.center
            , Element.centerX
            ]

        currentSlide : Maybe Api.Slide
        currentSlide =
            List.head (List.drop model.currentSlide (Maybe.withDefault [] model.slides))

        nextSlide : Maybe Api.Slide
        nextSlide =
            List.head (List.drop (model.currentSlide + 1) (Maybe.withDefault [] model.slides))

        getLine : Int -> Api.Slide -> Maybe String
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
            case nextSentenceCurrentSlide of
                Nothing ->
                    Maybe.withDefault Nothing (Maybe.map List.head (Maybe.map (\x -> String.split "\n" x.prompt) nextSlide))

                x ->
                    x

        nextSlideIcon =
            if nextSentenceCurrentSlide == Nothing && nextSentence /= Nothing then
                Element.html
                    (Html.span [ Html.Attributes.style "padding-right" "10px" ]
                        [ FontAwesome.iconWithOptions FontAwesome.arrowCircleRight FontAwesome.Solid [] []
                        ]
                    )

            else
                Element.none

        noPrompt =
            List.all (\x -> x.prompt == "") (Maybe.withDefault [] model.slides)

        promptText =
            case currentSentence of
                Just h ->
                    Element.el
                        (Font.size 35 :: Font.color Colors.white :: promptAttributes)
                        (Element.paragraph [] [ Element.text h ])

                _ ->
                    Element.none

        nextPromptText =
            case nextSentence of
                Just h ->
                    Element.row
                        (Font.size 25 :: Font.color Colors.grey :: promptAttributes)
                        [ Element.paragraph [] [ nextSlideIcon, Element.text h ] ]

                _ ->
                    Element.none

        help =
            Element.column [ Element.width Element.fill, Element.height Element.fill, Element.padding 5, Element.spacing 20 ]
                [ Element.paragraph [] [ Element.text "Enregistrer : espace" ]
                , Element.paragraph [] [ Element.text "Finir l'enregistrement : espace" ]
                , Element.paragraph [] [ Element.text "Prochaine ligne : flèche à droite" ]
                ]

        totalSlides =
            List.length (Maybe.withDefault [] model.slides)

        totalLines =
            Maybe.withDefault [] model.slides
                |> List.map (.prompt >> String.lines >> List.length)
                |> List.foldl (+) 0

        -- Some mattpiz wizardry
        currentLine =
            Maybe.withDefault [] model.slides
                |> List.take model.currentSlide
                |> List.map (.prompt >> String.lines >> List.length)
                |> List.foldl (+) (model.currentLine + 1)

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
                                        [ Ui.Icons.buttonFromIcon FontAwesome.circle
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
                                        [ Element.el [ Font.size 25 ] (Ui.Icons.buttonFromIcon FontAwesome.stopCircle)
                                        , Element.el [ Element.paddingEach { left = 5, bottom = 0, top = 0, right = 0 } ]
                                            (Element.text "Enregistrement arrêté")
                                        ]
                                    )
                                ]
                        ]
                , onPress =
                    Just
                        (mkmsg model
                            (if model.recording then
                                Acquisition.StopRecording

                             else
                                Acquisition.StartRecording
                            )
                        )
                }

        info =
            Element.row [ Element.padding 10, Element.spacing 30, Element.width Element.fill ]
                [ status
                , Element.el [ Element.width Element.fill ] Element.none
                , Element.text ("Slide " ++ String.fromInt (model.currentSlide + 1) ++ " / " ++ String.fromInt totalSlides)
                , Element.text ("Ligne " ++ String.fromInt currentLine ++ " / " ++ String.fromInt totalLines)
                ]
    in
    Element.row
        (if noPrompt then
            [ Element.width Element.fill ]

         else
            [ Element.width Element.fill
            , Element.height Element.fill
            ]
        )
        [ Element.el [ Element.width (Element.fillPortion 1), Element.height Element.fill ] help
        , if noPrompt then
            Element.el [] info

          else
            Element.column
                [ Element.width (Element.fillPortion 3)
                , Element.height Element.fill
                ]
                [ Element.column
                    [ Element.width Element.fill
                    , Element.height Element.fill
                    , Background.color Colors.black
                    , Element.padding 10
                    , Element.spacing 20
                    ]
                    [ promptText, nextPromptText ]
                , info
                ]
        , Element.el [ Element.width (Element.fillPortion 1), Element.height Element.fill ] Element.none
        ]


slideView : Acquisition.Model -> Element Core.Msg
slideView model =
    case List.head (List.drop model.currentSlide (Maybe.withDefault [] model.slides)) of
        Just h ->
            Element.el
                [ Input.focusedOnLoad
                , Element.width Element.fill
                , Element.height (Element.fillPortion 2)
                , Element.htmlAttribute
                    (Html.Attributes.style "background"
                        ("center / contain content-box no-repeat url('" ++ h.asset.asset_path ++ "')")
                    )
                ]
                Element.none

        _ ->
            Element.none


rightColumn : Acquisition.Model -> Element Core.Msg
rightColumn model =
    let
        recordView : Int -> Acquisition.Record -> Element Core.Msg
        recordView index record =
            Element.row [ Element.spacing 10 ]
                [ Element.text (String.fromInt (index + 1))
                , Ui.primaryButtonWithTooltip (msg record)
                    (if model.currentVideo == Just index && not model.watchingWebcam then
                        "◼"

                     else
                        "▶"
                    )
                    (if model.currentVideo == Just index && not model.watchingWebcam then
                        "Revenir à la webcam"

                     else
                        "Lire l'enregistrement"
                    )
                , Acquisition.UploadStream (url model.details.capsule.id model.gos) index
                    |> LoggedIn.AcquisitionMsg
                    |> Core.LoggedInMsg
                    |> Just
                    |> (\x -> Ui.primaryButtonWithTooltip x "✔" "Valider cet enregistrement")
                ]

        msg : Acquisition.Record -> Maybe Core.Msg
        msg i =
            if model.recording then
                Nothing

            else if model.currentVideo == Just i.id && not model.watchingWebcam then
                Just (Core.LoggedInMsg (LoggedIn.AcquisitionMsg Acquisition.GoToWebcam))

            else
                Just (Core.LoggedInMsg (LoggedIn.AcquisitionMsg (Acquisition.GoToStream i.id)))

        settingsButton : Element Core.Msg
        settingsButton =
            let
                settingsMsg =
                    Acquisition.ToggleSettings |> LoggedIn.AcquisitionMsg |> Core.LoggedInMsg |> Just
            in
            Ui.primaryButton settingsMsg "Paramètres"
    in
    Element.column [ Element.width Element.fill, Element.height Element.fill ]
        [ case model.showSettings of
            Just _ ->
                Element.none

            _ ->
                videoElement
        , settingsButton
        , Element.column [ Element.width Element.fill, Element.height Element.fill, Element.padding 10, Element.spacing 10 ]
            [ Element.el [ Element.centerX ] (Element.text "Enregistrements")
            , Element.column
                [ Element.width Element.fill, Element.height Element.fill, Element.scrollbarY ]
                (List.indexedMap recordView (List.reverse model.records))
            ]
        ]



-- CONSTANTS AND UTILS


videoElement =
    Element.html
        (Html.video [ Html.Attributes.class "wf", Html.Attributes.id elementId ] [])


text : Acquisition.Record -> String
text record =
    if record.new then
        "enregistrement #" ++ String.fromInt record.id

    else
        " ancien enregistrement"


url : Int -> Int -> String
url capsuleId gosId =
    "/api/capsule/" ++ String.fromInt capsuleId ++ "/" ++ String.fromInt gosId ++ "/upload_record"


elementId : String
elementId =
    "video"


videoDropdownConfig : Dropdown.Config Acquisition.VideoDevice Core.Msg
videoDropdownConfig =
    dropdownConfig
        Acquisition.videoLabel
        (\x -> Core.LoggedInMsg (LoggedIn.AcquisitionMsg (Acquisition.VideoDropdownMsg x)))
        (\x -> Core.LoggedInMsg (LoggedIn.AcquisitionMsg (Acquisition.VideoOptionPicked x)))


resolutionDropdownConfig : Dropdown.Config Acquisition.Resolution Core.Msg
resolutionDropdownConfig =
    dropdownConfig
        Acquisition.resolutionLabel
        (\x -> Core.LoggedInMsg (LoggedIn.AcquisitionMsg (Acquisition.ResolutionDropdownMsg x)))
        (\x -> Core.LoggedInMsg (LoggedIn.AcquisitionMsg (Acquisition.ResolutionOptionPicked x)))


audioDropdownConfig : Dropdown.Config Acquisition.AudioDevice Core.Msg
audioDropdownConfig =
    dropdownConfig
        Acquisition.audioLabel
        (\x -> Core.LoggedInMsg (LoggedIn.AcquisitionMsg (Acquisition.AudioDropdownMsg x)))
        (\x -> Core.LoggedInMsg (LoggedIn.AcquisitionMsg (Acquisition.AudioOptionPicked x)))


dropdownConfig : (a -> String) -> (Dropdown.Msg a -> Core.Msg) -> (Maybe a -> Core.Msg) -> Dropdown.Config a Core.Msg
dropdownConfig getLabel makeMsg1 makeMsg2 =
    let
        containerAttrs =
            [ Element.width Element.fill ]

        selectAttrs =
            [ Border.width 1
            , Border.rounded 5
            , Element.paddingXY 16 8
            , Element.spacing 10
            , Element.width Element.fill
            ]

        searchAttrs =
            [ Border.width 0, Element.padding 0, Element.width Element.fill ]

        listAttrs =
            [ Border.width 1
            , Border.roundEach { topLeft = 0, topRight = 0, bottomLeft = 5, bottomRight = 5 }
            , Element.width Element.fill
            , Element.clip
            , Element.scrollbarY
            , Element.height (Element.fill |> Element.maximum 200)
            ]

        itemToPrompt item =
            Element.text (getLabel item)

        itemToElement selected highlighted i =
            let
                bgColor =
                    if highlighted then
                        Element.rgb255 128 128 128

                    else if selected then
                        Element.rgb255 100 100 100

                    else
                        Element.rgb255 255 255 255
            in
            Element.row
                [ Background.color bgColor
                , Element.padding 8
                , Element.spacing 10
                , Element.width Element.fill
                ]
                [ Element.el [] (Element.text "-")
                , Element.el [ Font.size 16 ] (Element.text (getLabel i))
                ]
    in
    Dropdown.filterable
        makeMsg1
        makeMsg2
        itemToPrompt
        itemToElement
        getLabel
        |> Dropdown.withContainerAttributes containerAttrs
        |> Dropdown.withSelectAttributes selectAttrs
        |> Dropdown.withListAttributes listAttrs
        |> Dropdown.withSearchAttributes searchAttrs
        |> Dropdown.withFilterPlaceholder "Choisir"
        |> Dropdown.withPromptElement (Element.text "Choisir")
