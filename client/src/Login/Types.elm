module Login.Types exposing (Model, Msg(..), init)

import Api
import Status exposing (Status)


type alias Model =
    { status : Status () ()
    , username : String
    , password : String
    }


init : Model
init =
    Model Status.NotSent "" ""


type Msg
    = UsernameChanged String
    | PasswordChanged String
    | Submitted
    | Success Api.Session
    | Failed
