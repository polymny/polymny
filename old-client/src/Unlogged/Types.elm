module Unlogged.Types exposing (..)

import Browser
import Browser.Navigation
import Core.Types as Core
import Core.Utils as Core
import Json.Decode as Decode
import Lang exposing (Lang)
import Status exposing (Status)
import Url


type alias Model =
    { global : Core.Global
    , page : Page
    }


type alias LoginForm =
    { username : String
    , password : String
    , status : Status
    }


type alias SignUpForm =
    { username : String
    , password : String
    , repeatPassword : String
    , email : String
    , acceptConditions : Bool
    , registerNewsletter : Bool
    , status : Status
    , showMessage : Bool
    }


type alias ForgotPasswordForm =
    { email : String
    , status : Status
    }


type alias ResetPasswordForm =
    { key : String
    , newPassword : String
    , status : Status
    }


type alias ValidateInvitationForm =
    { key : String
    , password : String
    , repeatPassword : String
    , status : Status
    , showMessage : Bool
    }


type Page
    = Login LoginForm
    | SignUp SignUpForm
    | ForgotPassword ForgotPasswordForm
    | ResetPassword ResetPasswordForm
    | ValidateInvitation ValidateInvitationForm
    | Activated


initLoginForm : LoginForm
initLoginForm =
    { username = "", password = "", status = Status.NotSent }


initSignUpForm : SignUpForm
initSignUpForm =
    { username = ""
    , password = ""
    , repeatPassword = ""
    , email = ""
    , acceptConditions = False
    , registerNewsletter = True
    , status = Status.NotSent
    , showMessage = False
    }


initForgotPasswordForm : ForgotPasswordForm
initForgotPasswordForm =
    { email = "", status = Status.NotSent }


init : Decode.Value -> Url.Url -> Browser.Navigation.Key -> ( Maybe Model, Cmd Msg )
init flags url key =
    let
        global =
            Decode.decodeValue (Decode.field "global" (Core.decodeGlobal key)) flags

        split =
            String.split "/" url.path

        page =
            case split of
                "" :: "reset-password" :: k :: _ ->
                    ResetPassword { key = k, newPassword = "", status = Status.NotSent }

                "" :: "validate-invitation" :: k :: _ ->
                    ValidateInvitation { key = k, password = "", repeatPassword = "", status = Status.NotSent, showMessage = False }

                "" :: "activate" :: _ ->
                    Activated

                "" :: "validate-email" :: _ ->
                    Activated

                _ ->
                    Login initLoginForm

        model =
            case global of
                Ok g ->
                    Just (Model g page)

                _ ->
                    Nothing
    in
    ( model, Cmd.none )


onUrlRequest : Browser.UrlRequest -> Msg
onUrlRequest url =
    case url of
        Browser.Internal u ->
            GoToUrl (Url.toString u)

        Browser.External _ ->
            --ExternalUrl u
            Noop


type Msg
    = Noop
    | LangChanged Lang
    | LoginUsernameChanged String
    | LoginPasswordChanged String
    | LoginSubmitted
    | LoginFailed
    | LoginSuccess
    | SignUpUsernameChanged String
    | SignUpEmailChanged String
    | SignUpPasswordChanged String
    | SignUpRepeatPasswordChanged String
    | SignUpConditionsChanged Bool
    | SignUpRegisterNewsletterChanged Bool
    | SignUpSubmitted
    | SignUpSuccess
    | SignUpFailed
    | SignUpShowMessage
    | ForgotPasswordEmailChanged String
    | ForgotPasswordSubmitted
    | ForgotPasswordFailed
    | ForgotPasswordSuccess
    | ResetPasswordChanged String
    | ResetPasswordSubmitted
    | ResetPasswordSuccess
    | GoToPage Page
    | GoToUrl String
    | ValidateInvitationPasswordChanged String
    | ValidateInvitationRepeatPasswordChanged String
    | ValidateInvitationSubmitted
    | ValidateInvitationSuccess
    | ValidateInvitationFailed
    | ValidateInvitationShowMessage
