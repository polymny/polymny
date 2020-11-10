port module Core.Ports exposing (copyString, initWebSocket, onWebSocketMessage, scrollIntoView)

import Json.Decode


port initWebSocket : ( String, String ) -> Cmd msg


port copyString : String -> Cmd msg


port onWebSocketMessage : (Json.Decode.Value -> msg) -> Sub msg


port scrollIntoView : String -> Cmd msg
