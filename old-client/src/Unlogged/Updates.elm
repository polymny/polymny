module Unlogged.Updates exposing (..)

import Api
import Browser.Navigation as Nav
import Core.Ports as Ports
import Http
import Lang
import Status
import Unlogged.Types as Unlogged


update : Unlogged.Msg -> Maybe Unlogged.Model -> ( Maybe Unlogged.Model, Cmd Unlogged.Msg )
update msg model =
    case model of
        Just m ->
            let
                ( a, b ) =
                    updateInner msg m
            in
            ( Just a, b )

        _ ->
            ( Nothing, Cmd.none )


updateInner : Unlogged.Msg -> Unlogged.Model -> ( Unlogged.Model, Cmd Unlogged.Msg )
updateInner msg { global, page } =
    case ( msg, page ) of
        ( Unlogged.Noop, _ ) ->
            ( { global = global, page = page }, Cmd.none )

        ( Unlogged.LangChanged newLang, _ ) ->
            ( { global = { global | lang = newLang }, page = page }
            , Ports.setLanguage (Lang.toString newLang)
            )

        ( Unlogged.LoginUsernameChanged s, Unlogged.Login form ) ->
            ( { global = global, page = Unlogged.Login { form | username = s } }, Cmd.none )

        ( Unlogged.LoginPasswordChanged s, Unlogged.Login form ) ->
            ( { global = global, page = Unlogged.Login { form | password = s } }, Cmd.none )

        ( Unlogged.LoginSubmitted, Unlogged.Login form ) ->
            ( { global = global, page = Unlogged.Login { form | status = Status.Sent } }
            , Api.login (successError Unlogged.LoginSuccess Unlogged.LoginFailed) form
            )

        ( Unlogged.LoginFailed, Unlogged.Login form ) ->
            ( { global = global, page = Unlogged.Login { form | status = Status.Error } }, Cmd.none )

        ( Unlogged.LoginSuccess, Unlogged.Login form ) ->
            ( { global = global, page = Unlogged.Login form }, Nav.reload )

        ( Unlogged.SignUpUsernameChanged s, Unlogged.SignUp form ) ->
            ( { global = global, page = Unlogged.SignUp { form | username = s } }, Cmd.none )

        ( Unlogged.SignUpPasswordChanged s, Unlogged.SignUp form ) ->
            ( { global = global, page = Unlogged.SignUp { form | password = s } }, Cmd.none )

        ( Unlogged.SignUpRepeatPasswordChanged s, Unlogged.SignUp form ) ->
            ( { global = global, page = Unlogged.SignUp { form | repeatPassword = s } }, Cmd.none )

        ( Unlogged.SignUpEmailChanged s, Unlogged.SignUp form ) ->
            ( { global = global, page = Unlogged.SignUp { form | email = s } }, Cmd.none )

        ( Unlogged.SignUpConditionsChanged s, Unlogged.SignUp form ) ->
            ( { global = global, page = Unlogged.SignUp { form | acceptConditions = s } }, Cmd.none )

        ( Unlogged.SignUpRegisterNewsletterChanged s, Unlogged.SignUp form ) ->
            ( { global = global, page = Unlogged.SignUp { form | registerNewsletter = s } }, Cmd.none )

        ( Unlogged.SignUpSubmitted, Unlogged.SignUp form ) ->
            ( { global = global, page = Unlogged.SignUp { form | status = Status.Sent } }
            , Api.signUp (successError Unlogged.SignUpSuccess Unlogged.SignUpFailed) form
            )

        ( Unlogged.SignUpSuccess, Unlogged.SignUp form ) ->
            ( { global = global, page = Unlogged.SignUp { form | status = Status.Success } }, Cmd.none )

        ( Unlogged.SignUpFailed, Unlogged.SignUp form ) ->
            ( { global = global, page = Unlogged.SignUp { form | status = Status.Error } }, Cmd.none )

        ( Unlogged.SignUpShowMessage, Unlogged.SignUp form ) ->
            ( { global = global, page = Unlogged.SignUp { form | status = Status.Error, showMessage = True } }, Cmd.none )

        ( Unlogged.ForgotPasswordEmailChanged s, Unlogged.ForgotPassword form ) ->
            ( { global = global, page = Unlogged.ForgotPassword { form | email = s } }, Cmd.none )

        ( Unlogged.ForgotPasswordSubmitted, Unlogged.ForgotPassword form ) ->
            ( { global = global, page = Unlogged.ForgotPassword { form | status = Status.Sent } }
            , Api.requestNewPassword (successError Unlogged.ForgotPasswordSuccess Unlogged.ForgotPasswordFailed) form
            )

        ( Unlogged.ForgotPasswordFailed, Unlogged.ForgotPassword form ) ->
            ( { global = global, page = Unlogged.ForgotPassword { form | status = Status.Error } }, Cmd.none )

        ( Unlogged.ForgotPasswordSuccess, Unlogged.ForgotPassword form ) ->
            ( { global = global, page = Unlogged.ForgotPassword { form | status = Status.Success } }, Cmd.none )

        ( Unlogged.ResetPasswordChanged new, Unlogged.ResetPassword form ) ->
            ( { global = global, page = Unlogged.ResetPassword { form | newPassword = new } }, Cmd.none )

        ( Unlogged.ResetPasswordSubmitted, Unlogged.ResetPassword form ) ->
            ( { global = global, page = Unlogged.ResetPassword { form | status = Status.Sent } }
            , Api.changePasswordFromKey (successError Unlogged.ResetPasswordSuccess Unlogged.Noop) form
            )

        ( Unlogged.ResetPasswordSuccess, Unlogged.ResetPassword _ ) ->
            ( { global = global, page = page }, Nav.load "/" )

        ( Unlogged.GoToPage p, _ ) ->
            ( { global = global, page = p }, Cmd.none )

        ( Unlogged.GoToUrl u, _ ) ->
            ( { global = global, page = page }, Nav.load u )

        ( Unlogged.ValidateInvitationPasswordChanged s, Unlogged.ValidateInvitation form ) ->
            ( { global = global, page = Unlogged.ValidateInvitation { form | password = s } }, Cmd.none )

        ( Unlogged.ValidateInvitationRepeatPasswordChanged s, Unlogged.ValidateInvitation form ) ->
            ( { global = global, page = Unlogged.ValidateInvitation { form | repeatPassword = s } }, Cmd.none )

        ( Unlogged.ValidateInvitationSubmitted, Unlogged.ValidateInvitation form ) ->
            ( { global = global, page = Unlogged.ValidateInvitation { form | status = Status.Sent } }
            , Api.validateInvitation (successError Unlogged.ValidateInvitationSuccess Unlogged.ValidateInvitationFailed) form
            )

        ( Unlogged.ValidateInvitationSuccess, Unlogged.ValidateInvitation form ) ->
            ( { global = global, page = Unlogged.ValidateInvitation { form | status = Status.Success } }, Nav.load "/" )

        ( Unlogged.ValidateInvitationFailed, Unlogged.ValidateInvitation form ) ->
            ( { global = global, page = Unlogged.ValidateInvitation { form | status = Status.Error } }, Cmd.none )

        ( Unlogged.ValidateInvitationShowMessage, Unlogged.ValidateInvitation form ) ->
            ( { global = global, page = Unlogged.ValidateInvitation { form | status = Status.Error, showMessage = True } }, Cmd.none )

        ( _, _ ) ->
            ( { global = global, page = page }, Cmd.none )


successError : Unlogged.Msg -> Unlogged.Msg -> Result Http.Error () -> Unlogged.Msg
successError onSuccess onError result =
    case result of
        Ok _ ->
            onSuccess

        _ ->
            onError
