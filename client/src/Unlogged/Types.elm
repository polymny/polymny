module Unlogged.Types exposing (..)

{-| This module contains the login form.
-}

import Config exposing (Config)
import Data.User as Data exposing (User)
import RemoteData


{-| The model for the login form.
-}
type alias Model =
    { config : Config
    , page : Page
    , username : String
    , email : String
    , password : String
    , repeatPassword : String
    , loginRequest : RemoteData.WebData User
    , newPasswordRequest : RemoteData.WebData ()
    }


{-| The different states in which the UI can be.
-}
type Page
    = Login
    | Register
    | ForgotPassword


{-| Message type.
-}
type Msg
    = UsernameChanged String
    | EmailChanged String
    | PasswordChanged String
    | RepeatPasswordChanged String
    | PageChanged Page
    | LoginRequestChanged (RemoteData.WebData User)
    | NewPasswordRequestChanged (RemoteData.WebData ())
    | ButtonClicked


{-| Initializes the unlogged model.
-}
init : Config -> Model
init config =
    { config = config
    , page = Login
    , username = ""
    , email = ""
    , password = ""
    , repeatPassword = ""
    , loginRequest = RemoteData.NotAsked
    , newPasswordRequest = RemoteData.NotAsked
    }
