module Unlogged.Types exposing (..)

{-| This module contains the login form.
-}

import Config exposing (Config)
import Data.User as Data exposing (User)
import Json.Decode as Decode
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
    , acceptTermsOfService : Bool
    , signUpForNewsletter : Bool
    , loginRequest : RemoteData.WebData User
    , newPasswordRequest : RemoteData.WebData ()
    , resetPasswordRequest : RemoteData.WebData User
    , signUpRequest : RemoteData.WebData ()
    }


{-| The different states in which the UI can be.
-}
type Page
    = Login
    | SignUp
    | ForgotPassword
    | ResetPassword String


{-| Checks if two pages are the same.
-}
comparePage : Page -> Page -> Bool
comparePage page1 page2 =
    case ( page1, page2 ) of
        ( Login, Login ) ->
            True

        ( SignUp, SignUp ) ->
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
    | AcceptTermsOfServiceChanged Bool
    | SignUpForNewsletterChanged Bool
    | PageChanged Page
    | LoginRequestChanged (RemoteData.WebData User)
    | NewPasswordRequestChanged (RemoteData.WebData ())
    | ResetPasswordRequestChanged (RemoteData.WebData User)
    | SignUpRequestChanged (RemoteData.WebData ())
    | ButtonClicked
    | Noop


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
    , acceptTermsOfService = False
    , signUpForNewsletter = False
    , loginRequest = RemoteData.NotAsked
    , newPasswordRequest = RemoteData.NotAsked
    , resetPasswordRequest = RemoteData.NotAsked
    , signUpRequest = RemoteData.NotAsked
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


{-| Initializes the model for a standalone use.
-}
initStandalone : Decode.Value -> ( Maybe Model, Cmd Msg )
initStandalone flags =
    let
        serverConfig =
            Decode.decodeValue (Decode.field "global" (Decode.field "serverConfig" Config.decodeServerConfig)) flags

        clientConfig =
            Decode.decodeValue (Decode.field "global" (Decode.field "clientConfig" Config.decodeClientConfig)) flags

        clientState =
            Config.initClientState Nothing (clientConfig |> Result.toMaybe |> Maybe.andThen .lang)
    in
    case ( clientConfig, serverConfig ) of
        ( Ok c, Ok s ) ->
            ( Just <| init { serverConfig = s, clientConfig = c, clientState = clientState } Nothing
            , Cmd.none
            )

        _ ->
            ( Nothing, Cmd.none )
