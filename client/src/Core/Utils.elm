module Core.Utils exposing
    ( globalFromFlags
    , home
    , homeForgotPassword
    , homeLogin
    , homeSignUp
    , init
    , isLoggedIn
    , modelFromFlags
    )

import Acquisition.Types as Acquisition
import Api
import Browser.Navigation
import Core.Ports as Ports
import Core.Types as Core
import Edition.Types as Edition
import ForgotPassword.Types as ForgotPassword
import Json.Decode as Decode
import Log
import LoggedIn.Types as LoggedIn
import Login.Types as Login
import Preparation.Types as Preparation
import ResetPassword.Types as ResetPassword
import SignUp.Types as SignUp
import Status
import Task
import Time
import Url


home : Core.Model
home =
    Core.Home (Core.HomeLogin Login.init)


homeLogin : Login.Model -> Core.Model
homeLogin login =
    Core.Home (Core.HomeLogin login)


homeSignUp : SignUp.Model -> Core.Model
homeSignUp signUp =
    Core.Home (Core.HomeSignUp signUp)


homeForgotPassword : ForgotPassword.Model -> Core.Model
homeForgotPassword email =
    Core.Home (Core.HomeForgotPassword email)


isLoggedIn : Core.Model -> Bool
isLoggedIn model =
    case model of
        Core.LoggedIn _ ->
            True

        _ ->
            False


init : Decode.Value -> Url.Url -> Browser.Navigation.Key -> ( Core.FullModel, Cmd Core.Msg )
init flags _ key =
    let
        global =
            globalFromFlags flags key

        initialCommand =
            Task.perform Core.TimeZoneChanged Time.here

        ( initModel, initCmd ) =
            modelFromFlags global flags
    in
    ( Core.FullModel global initModel, Cmd.batch [ initialCommand, initCmd ] )


globalFromFlags : Decode.Value -> Browser.Navigation.Key -> Core.Global
globalFromFlags flags key =
    let
        root =
            case Decode.decodeValue (Decode.field "global" (Decode.field "video_root" Decode.string)) flags of
                Ok r ->
                    r

                Err _ ->
                    "/"

        socketRoot =
            case Decode.decodeValue (Decode.field "global" (Decode.field "socket_root" Decode.string)) flags of
                Ok r ->
                    r

                Err _ ->
                    "/"

        beta =
            case Decode.decodeValue (Decode.field "global" (Decode.field "beta" Decode.bool)) flags of
                Ok b ->
                    b

                Err _ ->
                    False

        mattingEnabled =
            case Decode.decodeValue (Decode.field "global" (Decode.field "matting_enabled" Decode.bool)) flags of
                Ok b ->
                    b

                Err _ ->
                    False

        version =
            case Decode.decodeValue (Decode.field "global" (Decode.field "version" Decode.string)) flags of
                Ok v ->
                    "Version " ++ v

                Err _ ->
                    "Version inconnue"

        commit =
            case Decode.decodeValue (Decode.field "global" (Decode.field "commit" Decode.string)) flags of
                Ok v ->
                    v

                Err _ ->
                    ""
    in
    { zone = Time.utc
    , beta = beta
    , videoRoot = root
    , socketRoot = socketRoot
    , version = version
    , key = key
    , commit = commit
    , mattingEnabled = mattingEnabled
    , numberOfSlidesPerRow = 3
    , expiry = 0
    , showAbout = False
    , notificationPanelVisible = False
    }


modelFromFlags : Core.Global -> Decode.Value -> ( Core.Model, Cmd Core.Msg )
modelFromFlags global flags =
    let
        ( finalModel, finalCmd ) =
            case Decode.decodeValue (Decode.field "flags" (Decode.field "page" Decode.string)) flags of
                Ok "index" ->
                    case Decode.decodeValue (Decode.field "flags" Api.decodeSession) flags of
                        Ok session ->
                            ( Core.LoggedIn
                                { session = session
                                , tab = LoggedIn.init
                                }
                            , Cmd.none
                            )

                        Err _ ->
                            ( home, Cmd.none )

                Ok "reset-password" ->
                    case Decode.decodeValue (Decode.field "flags" (Decode.field "key" Decode.string)) flags of
                        Ok key ->
                            ( Core.ResetPassword (ResetPassword.init key), Cmd.none )

                        Err _ ->
                            ( home, Cmd.none )

                Ok "preparation/capsule" ->
                    case ( Decode.decodeValue (Decode.field "flags" Api.decodeSession) flags, Decode.decodeValue (Decode.field "flags" Api.decodeCapsuleDetails) flags ) of
                        ( Ok session, Ok capsule ) ->
                            ( Core.LoggedIn
                                { session = session
                                , tab =
                                    LoggedIn.Preparation <| Preparation.init capsule
                                }
                            , Cmd.none
                            )

                        ( _, _ ) ->
                            ( home, Cmd.none )

                Ok "acquisition/capsule" ->
                    case
                        ( Decode.decodeValue (Decode.field "flags" Api.decodeSession) flags
                        , Decode.decodeValue (Decode.field "flags" Api.decodeCapsuleDetails) flags
                        )
                    of
                        ( Ok session, Ok capsule ) ->
                            let
                                ( model, cmd ) =
                                    Acquisition.initAtFirstNonRecorded global.mattingEnabled capsule Acquisition.All
                            in
                            ( Core.LoggedIn
                                { session = session
                                , tab = LoggedIn.Acquisition model
                                }
                            , cmd |> Cmd.map LoggedIn.AcquisitionMsg |> Cmd.map Core.LoggedInMsg
                            )

                        ( _, _ ) ->
                            ( home, Cmd.none )

                Ok "edition/capsule" ->
                    case ( Decode.decodeValue (Decode.field "flags" Api.decodeSession) flags, Decode.decodeValue (Decode.field "flags" Api.decodeCapsuleDetails) flags ) of
                        ( Ok session, Ok capsule ) ->
                            ( Core.LoggedIn
                                { session = session
                                , tab = LoggedIn.Edition (Edition.init capsule)
                                }
                            , Cmd.none
                            )

                        ( _, _ ) ->
                            ( home, Cmd.none )

                Ok "settings" ->
                    case
                        Decode.decodeValue (Decode.field "flags" Api.decodeSession) flags
                    of
                        Ok session ->
                            ( Core.LoggedIn { session = session, tab = LoggedIn.Settings { status = Status.NotSent } }, Cmd.none )

                        _ ->
                            ( home, Cmd.none )

                Ok ok ->
                    let
                        _ =
                            Log.debug "Unknown page" ok
                    in
                    -- Still try to log the user
                    case Decode.decodeValue (Decode.field "flags" Api.decodeSession) flags of
                        Ok session ->
                            ( Core.LoggedIn { session = session, tab = LoggedIn.init }, Cmd.none )

                        _ ->
                            ( home, Cmd.none )

                Err err ->
                    let
                        _ =
                            Log.debug "Error" err
                    in
                    -- Still try to log the user
                    case Decode.decodeValue (Decode.field "flags" Api.decodeSession) flags of
                        Ok session ->
                            ( Core.LoggedIn { session = session, tab = LoggedIn.init }, Cmd.none )

                        _ ->
                            ( home, Cmd.none )
    in
    case finalModel of
        Core.LoggedIn { session } ->
            ( finalModel, Cmd.batch [ finalCmd, Ports.initWebSocket ( global.socketRoot, session.cookie ) ] )

        _ ->
            ( finalModel, finalCmd )
