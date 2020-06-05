module Acquisition.Views exposing (view)

import Acquisition.Types as Acquisition
import Api
import Core.Types as Core
import Element exposing (Element)
import Html
import Html.Attributes
import LoggedIn.Types as LoggedIn
import Ui.Ui as Ui


view : Core.Global -> Api.Session -> Acquisition.Model -> Element Core.Msg
view _ _ model =
    let
        mainPage =
            mainView model

        element =
            Element.column
                [ Element.alignTop
                , Element.padding 10
                , Element.width Element.fill
                , Element.scrollbarX
                ]
                [ mainPage ]
    in
    Element.row
        [ Element.height Element.fill
        , Element.width Element.fill
        , Element.spacing 20
        ]
        [ element ]


mainView : Acquisition.Model -> Element Core.Msg
mainView model =
    Element.column [ Element.spacing 10, Element.width Element.fill ]
        [ topView model
        , Element.row [ Element.centerX, Element.spacing 10 ] [ recordingButton model.recording, nextSlideButton ]
        , recordingsView model.recordingsNumber model.currentStream
        , uploadView model.details.capsule.id model.gos model.currentStream
        ]


topView : Acquisition.Model -> Element Core.Msg
topView model =
    Element.row [ Element.centerX, Element.width Element.fill, Element.spacing 20 ]
        [ videoView (model.currentStream /= 0)
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


videoView : Bool -> Element Core.Msg
videoView controls =
    Element.el [ Element.centerX ] (Element.html (Html.video [ Html.Attributes.id elementId, Html.Attributes.controls controls ] []))


recordingButton : Bool -> Element Core.Msg
recordingButton recording =
    let
        ( text, msg ) =
            if recording then
                ( "Stop recording", Acquisition.StopRecording )

            else
                ( "Start recording", Acquisition.StartRecording )
    in
    Ui.simpleButton (Just (Core.LoggedInMsg (LoggedIn.AcquisitionMsg msg))) text


nextSlideButton : Element Core.Msg
nextSlideButton =
    Ui.simpleButton (Just (Core.LoggedInMsg (LoggedIn.AcquisitionMsg Acquisition.NextSlide))) "Next slide"


recordingsView : Int -> Int -> Element Core.Msg
recordingsView n current =
    let
        texts : List String
        texts =
            "Webcam" :: List.map (\x -> "Video " ++ String.fromInt x) (List.range 1 n)

        msg : Int -> Core.Msg
        msg i =
            Core.LoggedInMsg (LoggedIn.AcquisitionMsg (Acquisition.GoToStream i))
    in
    Element.column []
        [ Element.text "Available streams:"
        , Element.row [ Element.spacing 10 ]
            (List.indexedMap
                (\i ->
                    \x ->
                        if current == i then
                            Ui.successButton (Just (msg i)) x

                        else
                            Ui.simpleButton (Just (msg i)) x
                )
                texts
            )
        ]


uploadView : Int -> Int -> Int -> Element Core.Msg
uploadView capsuleId gosId stream =
    if stream == 0 then
        Element.none

    else
        Ui.primaryButton (Just (Acquisition.UploadStream (url capsuleId gosId) stream)) "Valider"
            |> Element.map LoggedIn.AcquisitionMsg
            |> Element.map Core.LoggedInMsg



-- CONSTANTS


url : Int -> Int -> String
url capsuleId gosId =
    "/api/capsule/" ++ String.fromInt capsuleId ++ "/" ++ String.fromInt gosId ++ "/upload_record"


elementId : String
elementId =
    "video"
