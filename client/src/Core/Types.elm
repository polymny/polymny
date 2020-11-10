module Core.Types exposing
    ( FullModel
    , Global
    , HomeModel(..)
    , Model(..)
    , Msg(..)
    , NotificationMsg(..)
    , decodeWebSocketMsg
    )

import Browser
import Browser.Navigation
import Element
import ForgotPassword.Types as ForgotPassword
import Json.Decode as Decode
import LoggedIn.Types as LoggedIn
import Login.Types as Login
import Notification.Types as Notification exposing (Notification)
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
    , socketRoot : String
    , videoRoot : String
    , version : String
    , commit : String
    , key : Browser.Navigation.Key
    , numberOfSlidesPerRow : Int
    , expiry : Int
    , showAbout : Bool
    , notificationPanelVisible : Bool
    , device : Element.Device
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
    | WebSocket WebSocketMsg
    | NotificationMsg NotificationMsg
    | WithNotification Notification Msg
    | SizeReceived Int Int


type alias WebSocketMsg =
    { content : String
    }


decodeWebSocketMsg : Decode.Decoder WebSocketMsg
decodeWebSocketMsg =
    Decode.map WebSocketMsg Decode.string


type NotificationMsg
    = NewNotification Notification
    | ToggleNotificationPanel
    | MarkNotificationRead Notification Int
