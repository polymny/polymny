module CapsuleSettings.Types exposing (..)

import Capsule exposing (Capsule)
import Status exposing (Status)


type alias Model =
    { capsule : Capsule
    , username : String
    , role : Capsule.Role
    , status : Status
    }


init : Capsule -> Model
init capsule =
    { capsule = capsule
    , username = ""
    , role = Capsule.Read
    , status = Status.NotSent
    }


type Msg
    = ChangeRole Capsule.User Capsule.Role
    | RemoveUser Capsule.User
    | ShareUsernameChanged String
    | ShareRoleChanged Capsule.Role
    | ShareConfirm
    | ShareSuccess
    | ShareError
