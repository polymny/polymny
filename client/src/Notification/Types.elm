module Notification.Types exposing (..)

import Element exposing (Element)


type alias Notification =
    { title : String
    , content : String
    , read : Bool
    , style : Style
    }


type Style
    = Info


info : String -> String -> Notification
info title content =
    Notification title content False Info
