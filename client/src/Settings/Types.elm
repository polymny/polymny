module Settings.Types exposing (..)

import Status exposing (Status)
import User exposing (User)


type alias Model =
    { username : String
    , newPassword : NewPassword
    , newEmail : NewEmail
    , delete : Delete
    }


type alias NewEmail =
    { newEmail : String
    , status : Status
    }


newEmailInit : NewEmail
newEmailInit =
    { newEmail = ""
    , status = Status.NotSent
    }


type alias NewPassword =
    { username : String
    , currentPassword : String
    , newPassword : String
    , newPasswordConfirm : String
    , status : Status
    }


newPasswordInit : User -> NewPassword
newPasswordInit user =
    { username = user.username
    , currentPassword = ""
    , newPassword = ""
    , newPasswordConfirm = ""
    , status = Status.NotSent
    }


type alias Delete =
    { currentPassword : String
    , status : Status
    }


deleteInit : Delete
deleteInit =
    { currentPassword = ""
    , status = Status.NotSent
    }


init : User -> Model
init user =
    { username = user.username
    , newPassword = newPasswordInit user
    , newEmail = newEmailInit
    , delete = deleteInit
    }


type Msg
    = NewPasswordCurrentPasswordChanged String
    | NewPasswordNewPasswordChanged String
    | NewPasswordNewPasswordConfirmChanged String
    | NewPasswordConfirm
    | NewPasswordSuccess
    | NewPasswordFailed
    | NewEmailNewEmailChanged String
    | NewEmailConfirm
    | NewEmailSuccess
    | NewEmailFailed
    | DeletePasswordChanged String
    | DeleteRequested
    | DeleteConfirm
    | DeleteSuccess
    | DeleteFailed
