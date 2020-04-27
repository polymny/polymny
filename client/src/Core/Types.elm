module Core.Types exposing (..)

import Api
import Login.Types as Login


type Model
    = Home
    | Login Login.Model
    | LoggedIn LoggedInModel


type alias LoggedInModel =
    { session : Api.Session
    , page : LoggedInPage
    }


type LoggedInPage
    = LoggedInHome


type Msg
    = Noop
    | LoginMsg Login.Msg
