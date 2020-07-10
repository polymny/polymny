module Settings.Types exposing (Model, init)

import Status exposing (Status)


type alias Model =
    { status : Status () ()
    }


init : Model
init =
    Model Status.NotSent
