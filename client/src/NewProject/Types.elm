module NewProject.Types exposing (Model, Msg(..), init)

import Api
import Status exposing (Status)


type alias Model =
    { status : Status () ()
    , name : String
    }


init : Model
init =
    Model Status.NotSent ""


type Msg
    = NameChanged String
    | Submitted
    | Success Api.Project
