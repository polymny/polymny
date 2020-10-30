module SignUp.Types exposing (Model, Msg(..), init)

import Status exposing (Status)


type alias Model =
    { status : Status () String
    , username : String
    , password : String
    , passwordConfirmation : String
    , email : String
    }


init : Model
init =
    Model Status.NotSent "" "" "" ""


type Msg
    = UsernameChanged String
    | PasswordChanged String
    | PasswordConfirmationChanged String
    | EmailChanged String
    | Submitted
    | Success
    | Failed String
