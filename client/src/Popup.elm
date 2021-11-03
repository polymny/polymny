module Popup exposing (..)

type alias Popup msg =
    { title : String
    , message : String
    , onCancel : msg
    , onConfirm : msg
    }

popup : String -> String -> msg -> msg -> Popup msg
popup title message onCancel onConfirm =
    { title = title
    , message = message
    , onCancel = onCancel
    , onConfirm = onConfirm
    }
