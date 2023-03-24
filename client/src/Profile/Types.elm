module Profile.Types exposing (..)

{-| This module contains everything required for the settings view.
-}

import RemoteData exposing (WebData)


{-| The different tabs on which the settings page can be.
-}
type Model
    = Info
    | ChangeEmail ChangeEmailModel
    | ChangePassword ChangePasswordModel
    | DeleteAccount DeleteAccountModel


{-| Checks whether the model is the same type as another.
-}
isSameTab : Model -> Model -> Bool
isSameTab m1 m2 =
    case ( m1, m2 ) of
        ( Info, Info ) ->
            True

        ( ChangeEmail _, ChangeEmail _ ) ->
            True

        ( ChangePassword _, ChangePassword _ ) ->
            True

        ( DeleteAccount _, DeleteAccount _ ) ->
            True

        _ ->
            False


{-| Initializes a model.
-}
init : Model
init =
    initInfo


{-| Initializes model as info.
-}
initInfo : Model
initInfo =
    Info


{-| The data required to change email address.
-}
type alias ChangeEmailModel =
    { newEmail : String
    , data : WebData ()
    }


{-| Inits an email model.
-}
initChangeEmail : Model
initChangeEmail =
    ChangeEmail { newEmail = "", data = RemoteData.NotAsked }


{-| The data required to change the password.
-}
type alias ChangePasswordModel =
    { currentPassword : String
    , newPassword : String
    , newPasswordRepeat : String
    , data : WebData ()
    }


{-| Initializes a change password model.
-}
initChangePassword : Model
initChangePassword =
    ChangePassword
        { currentPassword = ""
        , newPassword = ""
        , newPasswordRepeat = ""
        , data = RemoteData.NotAsked
        }


{-| The data to delete the account.
-}
type alias DeleteAccountModel =
    { password : String
    , showPopup : Bool
    , data : WebData ()
    }


{-| Initializes a delete account model.
-}
initDeleteAccount : Model
initDeleteAccount =
    DeleteAccount
        { password = ""
        , showPopup = False
        , data = RemoteData.NotAsked
        }


{-| This type contains the different messages that can happen on the settings page.
-}
type Msg
    = TabChanged Model
    | ChangeEmailNewEmailChanged String
    | ChangeEmailConfirm
    | ChangeEmailDataChanged (WebData ())
    | ChangePasswordCurrentPasswordChanged String
    | ChangePasswordNewPasswordChanged String
    | ChangePasswordNewPasswordRepeatChanged String
    | ChangePasswordConfirm
    | ChangePasswordDataChanged (WebData ())
    | DeleteAccountPasswordChanged String
    | DeleteAccountConfirm
    | DeleteAccountCancel
    | DeleteAccountConfirmTwice
    | DeleteAccountDataChanged (WebData ())
