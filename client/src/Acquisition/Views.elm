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
    Element.column [ Element.spacing 10 ]
        [ topView model
        , recordingButton model.recording
        , recordingsView model.recordingsNumber model.currentStream
        ]


topView : Acquisition.Model -> Element Core.Msg
topView model =
    Element.row []
        [ videoView (model.currentStream /= 0)
        , case model.slides of
            Just (h :: _) ->
                Element.image
                    [ Element.width (Element.px 640)
                    , Element.height (Element.px 480)
                    ]
                    { src = h.asset.asset_path, description = "Slide" }

            _ ->
                Element.none
        ]


videoView : Bool -> Element Core.Msg
videoView controls =
    Element.html (Html.video [ Html.Attributes.id elementId, Html.Attributes.controls controls ] [])


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



-- CONSTANTS


elementId : String
elementId =
    "video"
