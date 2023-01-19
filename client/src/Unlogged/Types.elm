module Unlogged.Types exposing (..)

{-| This module contains the login form.
-}

import Config exposing (Config)
import Data.User as Data exposing (User)
import RemoteData
import Url exposing (Url)


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
    , resetPasswordRequest : RemoteData.WebData User
    }


{-| The different states in which the UI can be.
-}
type Page
    = Login
    | Register
    | ForgotPassword
    | ResetPassword String


{-| Checks if two pages are the same.
-}
comparePage : Page -> Page -> Bool
comparePage page1 page2 =
    case ( page1, page2 ) of
        ( Login, Login ) ->
            True

        ( Register, Register ) ->
            True

        ( ForgotPassword, ForgotPassword ) ->
            True

        ( ResetPassword _, ResetPassword _ ) ->
            True

        _ ->
            False


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
    | ResetPasswordRequestChanged (RemoteData.WebData User)
    | ButtonClicked


{-| Initializes the unlogged model.
-}
init : Config -> Maybe Url -> Model
init config url =
    { config = config
    , page = Maybe.map fromUrl url |> Maybe.withDefault Login
    , username = ""
    , email = ""
    , password = ""
    , repeatPassword = ""
    , loginRequest = RemoteData.NotAsked
    , newPasswordRequest = RemoteData.NotAsked
    , resetPasswordRequest = RemoteData.NotAsked
    }


{-| Tries to convert a URL to the corresponding page. Returns Login if the route wasn't found.
-}
fromUrl : Url -> Page
fromUrl url =
    let
        tmp =
            String.split "/" url.path |> List.drop 1

        rev =
            List.reverse tmp

        -- this allows for trailing slash
        split =
            case List.head rev of
                Just x ->
                    if x == "" then
                        List.drop 1 rev |> List.reverse

                    else
                        List.reverse rev

                _ ->
                    tmp
    in
    case split of
        "reset-password" :: id :: [] ->
            ResetPassword id

        _ ->
            Login
