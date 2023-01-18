module Unlogged.Types exposing (..)

{-| This module contains the login form.
-}

import Config exposing (Config)


{-| The model for the login form.
-}
type alias Model =
    { config : Config
    , page : Page
    , username : String
    , email : String
    , password : String
    , confirmPassword : String
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


{-| Initializes the unlogged model.
-}
init : Config -> Model
init config =
    { config = config
    , page = Login
    , username = ""
    , email = ""
    , password = ""
    , confirmPassword = ""
    }
