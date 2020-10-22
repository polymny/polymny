module Utils exposing (resultToMsg)

import Api
import Core.Types as Core
import Element exposing (Element)
import Log exposing (debug)
import LoggedIn.Types as LoggedIn
import Ui.Attributes as Attributes
import Ui.Ui as Ui


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
