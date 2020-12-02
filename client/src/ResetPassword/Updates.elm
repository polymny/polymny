module ResetPassword.Updates exposing (update)

import Api
import Browser.Navigation as Nav
import Core.Types as Core
import LoggedIn.Types as LoggedIn
import ResetPassword.Types as ResetPassword
import Status
import Utils


update : Core.Global -> ResetPassword.Msg -> ResetPassword.Model -> ( Core.Model, Cmd Core.Msg )
update global msg content =
    case msg of
        ResetPassword.PasswordChanged newPassword ->
            ( Core.ResetPassword { content | password = newPassword }, Cmd.none )

        ResetPassword.PasswordConfirmationChanged newPasswordConfirmation ->
            ( Core.ResetPassword { content | passwordConfirmation = newPasswordConfirmation }, Cmd.none )

        ResetPassword.Submitted ->
            ( Core.ResetPassword { content | status = Status.Sent }
            , Api.resetPassword resultToMsg content
            )

        ResetPassword.Success s ->
            ( Core.ResetPassword content, Nav.pushUrl global.key "/" )

        ResetPassword.Failed ->
            ( Core.ResetPassword { content | status = Status.Error () }, Cmd.none )


resultToMsg : Result e Api.Session -> Core.Msg
resultToMsg result =
    Utils.resultToMsg
        (\x -> Core.ResetPasswordMsg (ResetPassword.Success x))
        (\_ -> Core.ResetPasswordMsg ResetPassword.Failed)
        result
