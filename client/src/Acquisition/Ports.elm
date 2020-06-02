port module Acquisition.Ports exposing
    ( bindWebcam
    , exit
    , goToStream
    , init
    , recordingsNumber
    , startRecording
    , stopRecording
    , uploadStream
    )


port init : String -> Cmd msg


port bindWebcam : String -> Cmd msg


port startRecording : () -> Cmd msg


port stopRecording : () -> Cmd msg


port goToStream : ( String, Int ) -> Cmd msg


port uploadStream : ( String, Int ) -> Cmd msg


port recordingsNumber : (Int -> msg) -> Sub msg


port exit : () -> Cmd msg
