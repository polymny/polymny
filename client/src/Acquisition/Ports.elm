port module Acquisition.Ports exposing
    ( bindWebcam
    , goToStream
    , recordingsNumber
    , reset
    , startRecording
    , stopRecording
    )


port reset : () -> Cmd msg


port bindWebcam : String -> Cmd msg


port startRecording : () -> Cmd msg


port stopRecording : () -> Cmd msg


port goToStream : ( String, Int ) -> Cmd msg


port recordingsNumber : (Int -> msg) -> Sub msg
