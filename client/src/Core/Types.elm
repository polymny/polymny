module Core.Types exposing
    ( FullModel
    , Global
    , HomeModel(..)
    , Model(..)
    , Msg(..)
    , home
    , homeLogin
    , homeSignUp
    , init
    , isLoggedIn
    )

import Acquisition.Types as Acquisition
import Api
import Json.Decode as Decode
import Log exposing (debug)
import LoggedIn.Types as LoggedIn
import Login.Types as Login
import Preparation.Types as Preparation
import SignUp.Types as SignUp
import Status
import Task
import Time


type alias FullModel =
    { global : Global
    , model : Model
    }


init : Decode.Value -> ( FullModel, Cmd Msg )
init flags =
    let
        global =
            { zone = Time.utc, dummy = "" }

        initialCommand =
            Task.perform TimeZoneChanged Time.here
    in
    ( FullModel global (modelFromFlags flags), initialCommand )


modelFromFlags : Decode.Value -> Model
modelFromFlags flags =
    case Decode.decodeValue (Decode.field "page" Decode.string) flags of
        Ok "index" ->
            case Decode.decodeValue Api.decodeSession flags of
                Ok session ->
                    LoggedIn
                        { session = session
                        , tab = LoggedIn.init
                        }

                Err _ ->
                    home

        Ok "preparation/capsule" ->
            case ( Decode.decodeValue Api.decodeSession flags, Decode.decodeValue Api.decodeCapsuleDetails flags ) of
                ( Ok session, Ok capsule ) ->
                    LoggedIn
                        { session = session
                        , tab =
                            LoggedIn.Preparation <| Preparation.init capsule
                        }

                ( _, _ ) ->
                    home

        Ok "acquisition/capsule" ->
            case ( Decode.decodeValue Api.decodeSession flags, Decode.decodeValue Api.decodeCapsuleDetails flags ) of
                ( Ok session, Ok capsule ) ->
                    let
                        ( model, _ ) =
                            Acquisition.init capsule Acquisition.All 0
                    in
                    LoggedIn
                        { session = session
                        , tab = LoggedIn.Acquisition model
                        }

                ( _, _ ) ->
                    home

        Ok "edition/capsule" ->
            case ( Decode.decodeValue Api.decodeSession flags, Decode.decodeValue Api.decodeCapsuleDetails flags ) of
                ( Ok session, Ok capsule ) ->
                    LoggedIn
                        { session = session
                        , tab = LoggedIn.Edition { status = Status.Success (), details = capsule }
                        }

                ( _, _ ) ->
                    home

        Ok ok ->
            let
                _ =
                    debug "Unknown page" ok
            in
            home

        Err err ->
            let
                _ =
                    debug "Error" err
            in
            home


type alias Global =
    { zone : Time.Zone
    , dummy : String
    }


type Model
    = Home HomeModel
    | LoggedIn LoggedIn.Model


type HomeModel
    = HomeLogin Login.Model
    | HomeSignUp SignUp.Model


home : Model
home =
    Home (HomeLogin Login.init)


homeLogin : Login.Model -> Model
homeLogin login =
    Home (HomeLogin login)


homeSignUp : SignUp.Model -> Model
homeSignUp signUp =
    Home (HomeSignUp signUp)


isLoggedIn : Model -> Bool
isLoggedIn model =
    case model of
        LoggedIn _ ->
            True

        _ ->
            False


type Msg
    = Noop
    | HomeClicked
    | LoginClicked
    | LogoutClicked
    | SignUpClicked
    | NewProjectClicked
    | TimeZoneChanged Time.Zone
    | LoginMsg Login.Msg
    | SignUpMsg SignUp.Msg
    | LoggedInMsg LoggedIn.Msg
