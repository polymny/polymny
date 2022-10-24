port module Acquisition.Ports exposing (..)

import Json.Encode


port findDevices : Bool -> Cmd msg


port playWebcam : () -> Cmd msg


port bindWebcam : ( Json.Encode.Value, Json.Encode.Value ) -> Cmd msg


port unbindWebcam : () -> Cmd msg


port webcamBound : (() -> msg) -> Sub msg


port bindPointer : () -> Cmd msg


port pointerBound : (() -> msg) -> Sub msg


port devicesReceived : (Json.Encode.Value -> msg) -> Sub msg


port startRecording : () -> Cmd msg


port stopRecording : () -> Cmd msg


port recordArrived : (Json.Encode.Value -> msg) -> Sub msg


port startPointerRecording : Json.Encode.Value -> Cmd msg


port pointerRecordArrived : (Json.Encode.Value -> msg) -> Sub msg


port askNextSlide : () -> Cmd msg


port askNextSentence : () -> Cmd msg


port playRecord : Json.Encode.Value -> Cmd msg


port stopPlayingRecord : () -> Cmd msg


port nextSlideReceived : (() -> msg) -> Sub msg


port playRecordFinished : (() -> msg) -> Sub msg


port uploadRecord : ( String, Int, Json.Encode.Value ) -> Cmd msg


port capsuleUpdated : (Json.Encode.Value -> msg) -> Sub msg


port progressReceived : (Float -> msg) -> Sub msg


port deviceDetectionFailed : (() -> msg) -> Sub msg


port bindingWebcamFailed : (() -> msg) -> Sub msg


port uploadRecordFailed : (() -> msg) -> Sub msg


port setPromptSize : Int -> Cmd msg


port setCanvas : Json.Encode.Value -> Cmd msg
