module Core.Types exposing
    ( FullModel
    , Global
    , HomeModel(..)
    , Model(..)
    , Msg(..)
    , decodeWebSocketMsg
    )

import Browser
import Browser.Navigation
import ForgotPassword.Types as ForgotPassword
import Json.Decode as Decode
import LoggedIn.Types as LoggedIn
import Login.Types as Login
import ResetPassword.Types as ResetPassword
import SignUp.Types as SignUp
import Time


type alias FullModel =
    { global : Global
    , model : Model
    }


type alias Global =
    { zone : Time.Zone
    , beta : Bool
    , mattingEnabled : Bool
    , socketRoot : String
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
    | UrlReceived Model (Cmd Msg)
    | CopyUrl String
    | WebSocket WebSocketMsg


type alias WebSocketMsg =
    { content : String
    }


decodeWebSocketMsg : Decode.Decoder WebSocketMsg
decodeWebSocketMsg =
    Decode.map WebSocketMsg Decode.string
