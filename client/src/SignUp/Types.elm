module SignUp.Types exposing (Model, Msg(..), init)

import Status exposing (Status)


type alias Model =
    { status : Status () ()
    , username : String
    , password : String
    , email : String
    }


init : Model
init =
    Model Status.NotSent "" "" ""


type Msg
    = UsernameChanged String
    | PasswordChanged String
    | EmailChanged String
    | Submitted
    | Success
