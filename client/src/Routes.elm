module Routes exposing (..)


preparation : Int -> String
preparation id =
    "/capsule/" ++ String.fromInt id ++ "/preparation"
