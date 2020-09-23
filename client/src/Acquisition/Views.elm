module Acquisition.Views exposing (subscriptions, view)

import Acquisition.Types as Acquisition
import Api
import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
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


view : Core.Global -> Api.Session -> Acquisition.Model -> Element Core.Msg
view global _ model =
    let
        attributes =
            if model.cameraReady then
                [ Element.width Element.fill
                , Element.height Element.fill
                , Element.scrollbarY
                ]

            else
                [ Element.width Element.fill
                , Element.height Element.fill
                , Element.scrollbarY
                , Element.htmlAttribute (Html.Attributes.style "visibility" "hidden")
                ]
    in
    Element.row
        attributes
        [ Preparation.leftColumnView model.details (Just model.gos)
        , centerView model
        , rightColumn model
        ]


centerView : Acquisition.Model -> Element Core.Msg
centerView model =
    Element.column [ Element.width (Element.fillPortion 6), Element.height Element.fill ]
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
                    Element.column [ Element.padding 5, Border.color Colors.primary, Border.width 2, Border.rounded 5 ]
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
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ Element.el [ Element.width (Element.fillPortion 1), Element.height Element.fill ] help
        , Element.column
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
                        ("center / contain content-box no-repeat url(" ++ h.asset.asset_path ++ ")")
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
            let
                makeButton =
                    Ui.primaryButton
            in
            Element.row [ Element.spacing 10 ]
                [ Element.text (String.fromInt (index + 1))
                , makeButton (msg record)
                    (if model.currentVideo == Just index && not model.watchingWebcam then
                        "◼"

                     else
                        "▶"
                    )
                , Acquisition.UploadStream (url model.details.capsule.id model.gos) index
                    |> LoggedIn.AcquisitionMsg
                    |> Core.LoggedInMsg
                    |> Just
                    |> (\x -> makeButton x "✔")
                ]

        msg : Acquisition.Record -> Maybe Core.Msg
        msg i =
            if model.recording then
                Nothing

            else if model.currentVideo == Just i.id && not model.watchingWebcam then
                Just (Core.LoggedInMsg (LoggedIn.AcquisitionMsg Acquisition.GoToWebcam))

            else
                Just (Core.LoggedInMsg (LoggedIn.AcquisitionMsg (Acquisition.GoToStream i.id)))
    in
    Element.column [ Element.width Element.fill, Element.height Element.fill ]
        [ Element.html (Html.video [ Html.Attributes.class "wf", Html.Attributes.id elementId ] [])
        , Element.column [ Element.width Element.fill, Element.padding 10, Element.spacing 10 ]
            (Element.el [ Element.centerX ] (Element.text "Enregistrements")
                :: List.indexedMap recordView (List.reverse model.records)
            )
        ]



-- mainView : Core.Global -> Acquisition.Model -> Element Core.Msg
-- mainView global model =
--     let
--         nextButton =
--             case model.slides of
--                 Just x ->
--                     case List.length x of
--                         0 ->
--                             Element.none
--
--                         1 ->
--                             Element.none
--
--                         _ ->
--                             nextSlideButton
--
--                 Nothing ->
--                     Element.none
--
--         slidePos =
--             Element.column
--                 [ Element.paddingXY 50 10
--                 , Font.size 28
--                 , Font.center
--                 , Background.color Colors.whiteDark
--                 , Border.color Colors.whiteDarker
--                 , Border.rounded 5
--                 , Border.width 1
--                 , Element.width Element.shrink
--                 , Element.centerX
--                 , Element.spacing 5
--                 ]
--                 [ Element.paragraph []
--                     [ Element.text "Slide "
--                     , Element.el [ Font.bold ] <| Element.text <| String.fromInt (model.gos + 1)
--                     , Element.text "/"
--                     , Element.el [ Font.bold ] <| Element.text <| String.fromInt <| List.length model.details.slides
--                     ]
--                 ]
--     in
--     Element.column [ Element.spacing 10, Element.padding 20, Element.width (Element.fillPortion 6), Element.height Element.fill ]
--         [ Element.row [ Element.spacing 10 ]
--             [ recordingsView model
--             , topView global model
--             ]
--         , Element.row [ Element.centerX, Element.spacing 10 ]
--             [ recordingButton model.cameraReady model.recording (List.length model.records), nextButton ]
--         , slidePos
--         ]


topView : Core.Global -> Acquisition.Model -> Element Core.Msg
topView global model =
    Element.row [ Element.centerX, Element.width Element.fill, Element.spacing 20 ]
        [ Element.column []
            [ backgroundView global model
            , videoView
            ]
        , case List.head (List.drop model.currentSlide (Maybe.withDefault [] model.slides)) of
            Just h ->
                Element.image
                    [ Element.width (Element.fill |> Element.maximum 800)
                    , Element.centerX
                    , Border.color Colors.artIrises
                    , Border.rounded 5
                    , Border.width 1
                    ]
                    { src = h.asset.asset_path, description = "Slide" }

            _ ->
                Element.none
        ]


videoView : Element Core.Msg
videoView =
    Element.el
        [ Element.centerX
        , Element.width (Element.px 400)
        ]
        (Element.html (Html.video [ Html.Attributes.id elementId ] []))


recordingButton : Bool -> Bool -> Int -> Element Core.Msg
recordingButton cameraReady recording nbRecords =
    let
        ( button, t, msg ) =
            if recording then
                ( Ui.stopRecordButton, "Arrêter l'enregistrement", Just Acquisition.StopRecording )

            else
                let
                    m =
                        if cameraReady then
                            Just Acquisition.StartRecording

                        else
                            Nothing

                    buttonText =
                        if nbRecords > 0 then
                            "Refaire un enregistrement"

                        else
                            "Démarrer l'enregistrement"
                in
                ( Ui.startRecordButton, buttonText, m )
    in
    button (msg |> Maybe.map LoggedIn.AcquisitionMsg |> Maybe.map Core.LoggedInMsg) t


nextSlideButton : Element Core.Msg
nextSlideButton =
    Ui.simpleButton (Just (Core.LoggedInMsg (LoggedIn.AcquisitionMsg (Acquisition.NextSlide True)))) "Next slide"


recordingsView : Acquisition.Model -> Element Core.Msg
recordingsView model =
    let
        webcam =
            if model.recording then
                Ui.primaryButtonDisabled "Voir flux webcam"

            else
                Ui.successButton (Just <| Core.LoggedInMsg <| LoggedIn.AcquisitionMsg <| Acquisition.GoToWebcam) "Voir flux webcam"

        msg : Acquisition.Record -> Maybe Core.Msg
        msg i =
            if model.recording then
                Nothing

            else
                Just (Core.LoggedInMsg (LoggedIn.AcquisitionMsg (Acquisition.GoToStream i.id)))

        button : Acquisition.Record -> Element Core.Msg
        button x =
            case model.currentVideo of
                Just v ->
                    if v == x.id then
                        Ui.successButton (msg x) ("Lire l'" ++ text x)

                    else
                        Ui.simpleButton (msg x) ("Lire l'" ++ text x)

                _ ->
                    Ui.simpleButton (msg x) ("Lire l'" ++ text x)
    in
    Element.column
        [ Background.color Colors.whiteDark
        , Element.alignTop
        , Element.spacing 5
        , Element.padding 10
        , Element.width
            (Element.fill
                |> Element.maximum 300
                |> Element.minimum 250
            )
        , Border.color Colors.whiteDarker
        , Border.rounded 5
        , Border.width 1
        , Element.centerX
        , Font.center
        ]
        [ webcam
        , if List.length model.records > 0 then
            Element.el [ Element.paddingXY 0 4, Element.centerX, Font.size 16 ] <|
                Element.text
                    " Enregistrements : "

          else
            Element.none
        , Element.column [ Element.alignLeft, Element.paddingXY 2 10, Element.spacing 10 ]
            (List.reverse (List.map button model.records))
        , Element.el [ Font.size 16, Font.center, Element.centerX ] <|
            uploadView model
        ]


uploadView : Acquisition.Model -> Element Core.Msg
uploadView { details, gos, currentVideo, recording, records, status } =
    case currentVideo of
        Nothing ->
            Element.none

        Just v ->
            let
                record =
                    List.head (List.drop v (List.reverse records))

                t =
                    Maybe.map String.toLower (Maybe.map text record)
            in
            case ( t, status ) of
                ( Nothing, _ ) ->
                    Element.none

                ( _, Status.Sent ) ->
                    Element.row [] [ Ui.spinner, Element.text "Envoi de l'enregistrement" ]

                ( Just s, _ ) ->
                    if recording then
                        Ui.primaryButtonDisabled ("Valider \n l'" ++ s)

                    else
                        Ui.successButton (Just (Acquisition.UploadStream (url details.capsule.id gos) v)) ("Valider \n l'" ++ s)
                            |> Element.map LoggedIn.AcquisitionMsg
                            |> Element.map Core.LoggedInMsg


backgroundView : Core.Global -> Acquisition.Model -> Element Core.Msg
backgroundView global model =
    if global.mattingEnabled then
        let
            button =
                case model.secondsRemaining of
                    Nothing ->
                        Ui.primaryButton (Just Acquisition.CaptureBackground) "Capturer le fond"
                            |> Element.map LoggedIn.AcquisitionMsg
                            |> Element.map Core.LoggedInMsg

                    Just n ->
                        Ui.primaryButton Nothing ("Photo du fond prise dans " ++ String.fromInt n ++ " secondes")

            currentBackground =
                case model.background of
                    Nothing ->
                        Element.text "Aucun fond"

                    Just s ->
                        Element.image [ Element.width (Element.px 100) ] { src = s, description = "Background" }
        in
        Element.row [] [ currentBackground, button ]

    else
        Element.none



-- CONSTANTS AND UTILS


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
