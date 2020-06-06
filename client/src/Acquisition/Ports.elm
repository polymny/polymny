port module Acquisition.Ports exposing
    ( askNextSlide
    , bindWebcam
    , exit
    , goToNextSlide
    , goToStream
    , init
    , newRecord
    , nextSlideReceived
    , startRecording
    , stopRecording
    , streamUploaded
    , uploadStream
    )

import Json.Encode


port init : String -> Cmd msg


port bindWebcam : String -> Cmd msg


port startRecording : () -> Cmd msg


port stopRecording : () -> Cmd msg


port goToStream : ( String, Int, Maybe (List Int) ) -> Cmd msg


port uploadStream : ( String, Int ) -> Cmd msg


port newRecord : (Int -> msg) -> Sub msg


port streamUploaded : (Json.Encode.Value -> msg) -> Sub msg


port askNextSlide : () -> Cmd msg


port nextSlideReceived : (Int -> msg) -> Sub msg


port goToNextSlide : (() -> msg) -> Sub msg


port exit : () -> Cmd msg
