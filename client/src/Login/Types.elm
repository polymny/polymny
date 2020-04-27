module Login.Types exposing (..)

import Api
import Status exposing (Status)


type Msg
    = UsernameChanged String
    | PasswordChanged String
    | Submitted
    | Success Api.Session
    | Failed


type alias Model =
    { status : Status () ()
    , username : String
    , password : String
    }


emptyModel : Model
emptyModel =
    Model Status.NotSent "" ""
