module Notification.Types exposing (..)

import Element exposing (Element)
import Json.Decode as Decode


type alias Notification =
    { id : Maybe Int
    , title : String
    , content : String
    , read : Bool
    , style : Style
    }


type Style
    = Info
    | Warning
    | Error


info : String -> String -> Notification
info title content =
    Notification Nothing title content False Info


decodeStyle : Decode.Decoder Style
decodeStyle =
    Decode.andThen
        (\x ->
            case x of
                "warning" ->
                    Decode.succeed Warning

                "error" ->
                    Decode.succeed Error

                _ ->
                    Decode.succeed Info
        )
        Decode.string


decode : Decode.Decoder Notification
decode =
    Decode.map5 Notification
        (Decode.map Just (Decode.field "id" Decode.int))
        (Decode.field "title" Decode.string)
        (Decode.field "content" Decode.string)
        (Decode.field "read" Decode.bool)
        (Decode.field "style" decodeStyle)
