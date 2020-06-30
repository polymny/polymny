module Core.Types exposing
    ( FullModel
    , Global
    , HomeModel(..)
    , Model(..)
    , Msg(..)
    , home
    , homeForgotPassword
    , homeLogin
    , homeSignUp
    , init
    , isLoggedIn
    )

import Acquisition.Types as Acquisition
import Api
import Edition.Types as Edition
import ForgotPassword.Types as ForgotPassword
import Json.Decode as Decode
import Log exposing (debug)
import LoggedIn.Types as LoggedIn
import Login.Types as Login
import Preparation.Types as Preparation
import ResetPassword.Types as ResetPassword
import SignUp.Types as SignUp
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
            globalFromFlags flags

        initialCommand =
            Task.perform TimeZoneChanged Time.here

        ( initModel, initCmd ) =
            modelFromFlags flags
    in
    ( FullModel global initModel, Cmd.batch [ initialCommand, initCmd ] )


globalFromFlags : Decode.Value -> Global
globalFromFlags flags =
    let
        root =
            case Decode.decodeValue (Decode.field "video_root" Decode.string) flags of
                Ok r ->
                    r

                Err _ ->
                    "/"

        beta =
            case Decode.decodeValue (Decode.field "beta" Decode.bool) flags of
                Ok b ->
                    b

                Err _ ->
                    False

        version =
            case Decode.decodeValue (Decode.field "version" Decode.string) flags of
                Ok v ->
                    "Version " ++ v

                Err _ ->
                    "Unkown version"
    in
    { zone = Time.utc, beta = beta, videoRoot = root, version = version }


modelFromFlags : Decode.Value -> ( Model, Cmd Msg )
modelFromFlags flags =
    case Decode.decodeValue (Decode.field "page" Decode.string) flags of
        Ok "index" ->
            case Decode.decodeValue Api.decodeSession flags of
                Ok session ->
                    ( LoggedIn
                        { session = session
                        , tab = LoggedIn.init
                        }
                    , Cmd.none
                    )

                Err _ ->
                    ( home, Cmd.none )

        Ok "reset-password" ->
            case Decode.decodeValue (Decode.field "key" Decode.string) flags of
                Ok key ->
                    ( ResetPassword (ResetPassword.init key), Cmd.none )

                Err _ ->
                    ( home, Cmd.none )

        Ok "preparation/capsule" ->
            case ( Decode.decodeValue Api.decodeSession flags, Decode.decodeValue Api.decodeCapsuleDetails flags ) of
                ( Ok session, Ok capsule ) ->
                    ( LoggedIn
                        { session = session
                        , tab =
                            LoggedIn.Preparation <| Preparation.init capsule
                        }
                    , Cmd.none
                    )

                ( _, _ ) ->
                    ( home, Cmd.none )

        Ok "acquisition/capsule" ->
            case ( Decode.decodeValue Api.decodeSession flags, Decode.decodeValue Api.decodeCapsuleDetails flags ) of
                ( Ok session, Ok capsule ) ->
                    let
                        ( model, cmd ) =
                            Acquisition.initAtFirstNonRecorded capsule Acquisition.All
                    in
                    ( LoggedIn
                        { session = session
                        , tab = LoggedIn.Acquisition model
                        }
                    , cmd |> Cmd.map LoggedIn.AcquisitionMsg |> Cmd.map LoggedInMsg
                    )

                ( _, _ ) ->
                    ( home, Cmd.none )

        Ok "edition/capsule" ->
            case ( Decode.decodeValue Api.decodeSession flags, Decode.decodeValue Api.decodeCapsuleDetails flags ) of
                ( Ok session, Ok capsule ) ->
                    ( LoggedIn
                        { session = session
                        , tab = LoggedIn.Edition (Edition.init capsule)
                        }
                    , Cmd.none
                    )

                ( _, _ ) ->
                    ( home, Cmd.none )

        Ok ok ->
            let
                _ =
                    debug "Unknown page" ok
            in
            ( home, Cmd.none )

        Err err ->
            let
                _ =
                    debug "Error" err
            in
            ( home, Cmd.none )


type alias Global =
    { zone : Time.Zone
    , beta : Bool
    , videoRoot : String
    , version : String
    }


type Model
    = Home HomeModel
    | ResetPassword ResetPassword.Model
    | LoggedIn LoggedIn.Model


type HomeModel
    = HomeLogin Login.Model
    | HomeSignUp SignUp.Model
    | HomeForgotPassword ForgotPassword.Model


home : Model
home =
    Home (HomeLogin Login.init)


homeLogin : Login.Model -> Model
homeLogin login =
    Home (HomeLogin login)


homeSignUp : SignUp.Model -> Model
homeSignUp signUp =
    Home (HomeSignUp signUp)


homeForgotPassword : ForgotPassword.Model -> Model
homeForgotPassword email =
    Home (HomeForgotPassword email)


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
    | ForgotPasswordClicked
    | NewProjectClicked
    | TimeZoneChanged Time.Zone
    | LoginMsg Login.Msg
    | SignUpMsg SignUp.Msg
    | LoggedInMsg LoggedIn.Msg
    | ForgotPasswordMsg ForgotPassword.Msg
    | ResetPasswordMsg ResetPassword.Msg
