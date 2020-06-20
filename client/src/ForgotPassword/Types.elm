module ForgotPassword.Types exposing (Model, Msg(..), init)

import Api
import Status exposing (Status)


type alias Model =
    { status : Status () ()
    , email : String
    }


init : Model
init =
    Model Status.NotSent ""


type Msg
    = EmailChanged String
    | Submitted
    | Success
    | Failed
