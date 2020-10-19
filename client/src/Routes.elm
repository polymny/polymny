module Routes exposing (..)


preparation : Int -> String
preparation id =
    "/capsule/" ++ String.fromInt id ++ "/preparation"


acquisition : Int -> String
acquisition id =
    "/capsule/" ++ String.fromInt id ++ "/acquisition"


edition : Int -> String
edition id =
    "/capsule/" ++ String.fromInt id ++ "/edition"
