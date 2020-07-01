module ForgotPassword.Updates exposing (update)

import Api
import Core.Types as Core
import Core.Utils as Core
import ForgotPassword.Types as ForgotPassword
import Status
import Utils


update : ForgotPassword.Msg -> ForgotPassword.Model -> ( Core.Model, Cmd Core.Msg )
update loginMsg content =
    case loginMsg of
        ForgotPassword.EmailChanged newEmail ->
            ( Core.homeForgotPassword { content | email = newEmail }, Cmd.none )

        ForgotPassword.Submitted ->
            ( Core.homeForgotPassword { content | status = Status.Sent }
            , Api.forgotPassword resultToMsg content
            )

        ForgotPassword.Success ->
            ( Core.homeForgotPassword { content | status = Status.Success () }, Cmd.none )

        ForgotPassword.Failed ->
            ( Core.homeForgotPassword { content | status = Status.Error () }, Cmd.none )


resultToMsg : Result e () -> Core.Msg
resultToMsg result =
    Utils.resultToMsg (\_ -> Core.ForgotPasswordMsg ForgotPassword.Success) (\_ -> Core.ForgotPasswordMsg ForgotPassword.Failed) result
