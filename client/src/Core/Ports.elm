port module Core.Ports exposing (..)

import Json.Decode as Decode


port setLanguage : String -> Cmd msg


port setZoomLevel : Int -> Cmd msg


port setAcquisitionInverted : Bool -> Cmd msg


port setVideoDeviceId : String -> Cmd msg


port setResolution : String -> Cmd msg


port setAudioDeviceId : String -> Cmd msg


port setSortBy : ( String, Bool ) -> Cmd msg


port copyString : String -> Cmd msg


port scrollIntoView : String -> Cmd msg


port websocketMsg : (Decode.Value -> msg) -> Sub msg


port exportCapsule : Decode.Value -> Cmd msg


port importCapsule : ( Maybe String, Decode.Value ) -> Cmd msg


port select : ( Maybe String, List String ) -> Cmd msg


port selected : (( Maybe String, Decode.Value ) -> msg) -> Sub msg


port setPointerCapture : ( String, Int ) -> Cmd msg


port setOnBeforeUnloadValue : Bool -> Cmd msg
