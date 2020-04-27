module Utils exposing (resultToMsg)

import Log exposing (debug)


resultToMsg : (x -> msg) -> (e -> msg) -> Result e x -> msg
resultToMsg ifSuccess ifError result =
    case result of
        Ok x ->
            ifSuccess x

        Err e ->
            let
                err =
                    debug "Error" e
            in
            ifError err
