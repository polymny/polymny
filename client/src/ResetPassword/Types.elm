module ResetPassword.Types exposing (Model, Msg(..), init)

import Api
import Status exposing (Status)


type alias Model =
    { status : Status () ()
    , key : String
    , password : String
    , passwordConfirmation : String
    }


init : String -> Model
init key =
    Model Status.NotSent key "" ""


type Msg
    = PasswordChanged String
    | PasswordConfirmationChanged String
    | Submitted
    | Success Api.Session
    | Failed
