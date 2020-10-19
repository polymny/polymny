module Core.Types exposing
    ( FullModel
    , Global
    , HomeModel(..)
    , Model(..)
    , Msg(..)
    )

import Browser
import Browser.Navigation
import ForgotPassword.Types as ForgotPassword
import LoggedIn.Types as LoggedIn
import Login.Types as Login
import ResetPassword.Types as ResetPassword
import SignUp.Types as SignUp
import Time
import Url


type alias FullModel =
    { global : Global
    , model : Model
    }


type alias Global =
    { zone : Time.Zone
    , beta : Bool
    , mattingEnabled : Bool
    , videoRoot : String
    , version : String
    , commit : String
    , key : Browser.Navigation.Key
    , numberOfSlidesPerRow : Int
    , expiry : Int
    , showAbout : Bool
    }


type Model
    = Home HomeModel
    | ResetPassword ResetPassword.Model
    | LoggedIn LoggedIn.Model


type HomeModel
    = HomeLogin Login.Model
    | HomeSignUp SignUp.Model
    | HomeForgotPassword ForgotPassword.Model
    | HomeAbout


type Msg
    = Noop
    | HomeClicked
    | LoginClicked
    | LogoutClicked
    | SignUpClicked
    | ForgotPasswordClicked
    | NewProjectClicked
    | AboutClicked
    | AboutClosed
    | TimeZoneChanged Time.Zone
    | LoginMsg Login.Msg
    | SignUpMsg SignUp.Msg
    | LoggedInMsg LoggedIn.Msg
    | ForgotPasswordMsg ForgotPassword.Msg
    | ResetPasswordMsg ResetPassword.Msg
    | UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | UrlReceived Model (Cmd Msg)
    | CopyUrl String
