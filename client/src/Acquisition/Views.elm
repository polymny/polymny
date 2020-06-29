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
        [ slidePos
        , Element.row []
            [ recordingsView model
            , topView
                model
            ]
        , Element.row [ Element.centerX, Element.spacing 10 ] [ recordingButton model.cameraReady model.recording, nextButton ]
        ]


topView : Acquisition.Model -> Element Core.Msg
topView model =
    Element.row [ Element.centerX, Element.width Element.fill, Element.spacing 20 ]
        [ videoView
        , case List.head (List.drop model.currentSlide (Maybe.withDefault [] model.slides)) of
            Just h ->
                Element.image
                    [ Element.width (Element.px 640)
                    , Element.height (Element.px 480)
                    , Element.centerX
                    ]
                    { src = h.asset.asset_path, description = "Slide" }

            _ ->
                Element.none
        ]


videoView : Element Core.Msg
videoView =
    Element.el [ Element.centerX ] (Element.html (Html.video [ Html.Attributes.id elementId ] []))


recordingButton : Bool -> Bool -> Element Core.Msg
recordingButton cameraReady recording =
    let
        ( button, text, msg ) =
            if recording then
                ( Ui.stopRecordButton, "Arrêter l'enregistrement", Just Acquisition.StopRecording )

            else
                let
                    m =
                        if cameraReady then
                            Just Acquisition.StartRecording

                        else
                            Nothing
                in
                ( Ui.startRecordButton, "Démarrer l'enregistrement", m )
    in
    button (msg |> Maybe.map LoggedIn.AcquisitionMsg |> Maybe.map Core.LoggedInMsg) text


nextSlideButton : Element Core.Msg
nextSlideButton =
    Ui.simpleButton (Just (Core.LoggedInMsg (LoggedIn.AcquisitionMsg (Acquisition.NextSlide True)))) "Next slide"


recordingsView : Acquisition.Model -> Element Core.Msg
recordingsView model =
    let
        webcam =
            if model.recording then
                Ui.primaryButtonDisabled "Webcam"

            else if List.length model.records == 0 then
                Ui.successButton (Just <| Core.LoggedInMsg <| LoggedIn.AcquisitionMsg <| Acquisition.GoToStream 0) "Select Webcam"

            else
                Ui.successButton (Just <| Core.LoggedInMsg <| LoggedIn.AcquisitionMsg <| Acquisition.GoToStream 0) "Retour  Webcam"

        texts : List String
        texts =
            List.map (\x -> "Enregistrement #" ++ String.fromInt x) (List.range 1 (List.length model.records))

        msg : Int -> Maybe Core.Msg
        msg i =
            if model.recording then
                Nothing

            else
                Just (Core.LoggedInMsg (LoggedIn.AcquisitionMsg (Acquisition.GoToStream i)))
    in
    Element.column
        [ Background.color Colors.whiteDark
        , Element.spacing 5
        , Element.padding 10
        , Border.color Colors.whiteDarker
        , Border.rounded 5
        , Border.width 1
        ]
        [ webcam
        , Element.text <|
            "current ="
                ++ String.fromInt model.currentStream
        , Element.text
            "Enregsitrements : "
        , Element.column [ Element.paddingXY 10 20, Element.spacing 10 ]
            (List.indexedMap
                (\i ->
                    \x ->
                        if model.currentStream == i + 1 then
                            Ui.successButton (msg (i + 1)) x

                        else
                            Ui.simpleButton (msg (i + 1)) x
                )
                texts
            )
        , Element.el [ Font.size 16, Font.center ] <| uploadView model.details.capsule.id model.gos model.currentStream model.recording
        ]


uploadView : Int -> Int -> Int -> Bool -> Element Core.Msg
uploadView capsuleId gosId stream recording =
    if stream == 0 then
        Element.none

    else if recording then
        Ui.primaryButtonDisabled ("Valider \n l'enregistrement #" ++ String.fromInt stream)

    else
        Ui.successButton (Just (Acquisition.UploadStream (url capsuleId gosId) stream)) ("Valider \n l'enregistrement #" ++ String.fromInt stream)
            |> Element.map LoggedIn.AcquisitionMsg
            |> Element.map Core.LoggedInMsg



-- CONSTANTS


url : Int -> Int -> String
url capsuleId gosId =
    "/api/capsule/" ++ String.fromInt capsuleId ++ "/" ++ String.fromInt gosId ++ "/upload_record"


elementId : String
elementId =
    "video"
