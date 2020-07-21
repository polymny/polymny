module Acquisition.Views exposing (view)

import Acquisition.Types as Acquisition
import Api
import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html
import Html.Attributes
import LoggedIn.Types as LoggedIn
import Status
import Ui.Colors as Colors
import Ui.Ui as Ui
import Utils


view : Core.Global -> Api.Session -> Acquisition.Model -> Element Core.Msg
view _ _ model =
    let
        mainPage =
            mainView model

        element =
            Element.column
                Ui.mainViewAttributes2
                [ Utils.headerView "acquisition" model.details
                , mainPage
                ]
    in
    Element.row Ui.mainViewAttributes1
        [ element ]


viewSlideImage : String -> Element Core.Msg
viewSlideImage urlImage =
    Element.image
        [ Element.width (Element.px 150) ]
        { src = urlImage, description = "One desc" }


slideThumbView : Bool -> Api.Slide -> Element Core.Msg
slideThumbView isActive slide =
    let
        background =
            if isActive then
                Background.color Colors.artIrises

            else
                Background.color Colors.whiteDark

        attributes =
            [ background
            , Border.color Colors.whiteDarker
            , Border.rounded 5
            , Border.width 1
            , Element.padding 10
            ]
    in
    Element.el attributes <|
        viewSlideImage slide.asset.asset_path


slidesThumbView : Acquisition.Model -> Element Core.Msg
slidesThumbView model =
    let
        gosParser : Bool -> Api.Gos -> Element Core.Msg
        gosParser isActive gos =
            Element.row []
                (List.map (slideThumbView isActive) gos.slides)
    in
    Element.row []
        (List.indexedMap (\i x -> gosParser (i == model.gos) x) model.details.structure)


mainView : Acquisition.Model -> Element Core.Msg
mainView model =
    let
        nextButton =
            case model.slides of
                Just x ->
                    case List.length x of
                        0 ->
                            Element.none

                        1 ->
                            Element.none

                        _ ->
                            nextSlideButton

                Nothing ->
                    Element.none

        slidePos =
            Element.column
                [ Element.paddingXY 50 10
                , Font.size 28
                , Font.center
                , Background.color Colors.whiteDark
                , Border.color Colors.whiteDarker
                , Border.rounded 5
                , Border.width 1
                , Element.width Element.shrink
                , Element.centerX
                , Element.spacing 5
                ]
                [ Element.paragraph []
                    [ Element.text "Slide "
                    , Element.el [ Font.bold ] <| Element.text <| String.fromInt (model.gos + 1)
                    , Element.text "/"
                    , Element.el [ Font.bold ] <| Element.text <| String.fromInt <| List.length model.details.slides
                    ]
                , slidesThumbView model
                ]
    in
    Element.column [ Element.spacing 10, Element.padding 20, Element.width Element.fill ]
        [ Element.row [ Element.spacing 10 ]
            [ recordingsView model
            , topView model
            ]
        , Element.row [ Element.centerX, Element.spacing 10 ]
            [ recordingButton model.cameraReady model.recording (List.length model.records), nextButton ]
        , slidePos
        ]


topView : Acquisition.Model -> Element Core.Msg
topView model =
    Element.row [ Element.centerX, Element.width Element.fill, Element.spacing 20 ]
        [ videoView
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
                Ui.primaryButtonDisabled "Flux webcam"

            else
                Ui.successButton (Just <| Core.LoggedInMsg <| LoggedIn.AcquisitionMsg <| Acquisition.GoToWebcam) "Flux webcam"

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
                    Ui.simpleButton (msg x) (text x)
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
        , Element.el [ Font.size 16, Font.center ] <|
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



-- CONSTANTS AND UTILS


text : Acquisition.Record -> String
text record =
    if record.new then
        "enregistrement #" ++ String.fromInt record.id

    else
        "ancien enregistrement"


url : Int -> Int -> String
url capsuleId gosId =
    "/api/capsule/" ++ String.fromInt capsuleId ++ "/" ++ String.fromInt gosId ++ "/upload_record"


elementId : String
elementId =
    "video"
