port module Acquisition.Ports exposing
    ( askNextSlide
    , bindWebcam
    , cameraReady
    , captureBackground
    , exit
    , goToNextSlide
    , goToStream
    , goToWebcam
    , init
    , newRecord
    , nextSlideReceived
    , startRecording
    , stopRecording
    , streamUploaded
    , uploadStream
    )

import Json.Encode


port init : ( String, Maybe String ) -> Cmd msg


port bindWebcam : String -> Cmd msg


port cameraReady : (() -> msg) -> Sub msg


port startRecording : () -> Cmd msg


port stopRecording : () -> Cmd msg


port goToWebcam : String -> Cmd msg


port goToStream : ( String, Int, Maybe (List Int) ) -> Cmd msg


port uploadStream : ( String, Int, Json.Encode.Value ) -> Cmd msg


port newRecord : (Int -> msg) -> Sub msg


port streamUploaded : (Json.Encode.Value -> msg) -> Sub msg


port askNextSlide : () -> Cmd msg


port nextSlideReceived : (Int -> msg) -> Sub msg


port goToNextSlide : (() -> msg) -> Sub msg


port exit : () -> Cmd msg


port captureBackground : String -> Cmd msg
