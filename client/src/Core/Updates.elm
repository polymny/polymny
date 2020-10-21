module Core.Updates exposing (onUrlChange, onUrlRequest, update)

import Acquisition.Ports as Ports
import Api
import Browser
import Browser.Navigation as Nav
import Core.Ports as Ports
import Core.Types as Core
import Core.Utils as Core
import ForgotPassword.Types as ForgotPassword
import ForgotPassword.Updates as ForgotPassword
import Http
import Json.Decode as Decode
import Log
import LoggedIn.Types as LoggedIn
import LoggedIn.Updates as LoggedIn
import Login.Types as Login
import Login.Updates as Login
import ResetPassword.Types as ResetPassword
import ResetPassword.Updates as ResetPassword
import SignUp.Types as SignUp
import SignUp.Updates as SignUp
import Url


update : Core.Msg -> Core.FullModel -> ( Core.FullModel, Cmd Core.Msg )
update msg { global, model } =
    let
        ( returnModel, returnCmd ) =
            case ( msg, model ) of
                -- INNER MESSAGES
                ( Core.Noop, _ ) ->
                    ( Core.FullModel global model, Cmd.none )

                ( Core.TimeZoneChanged newTimeZone, _ ) ->
                    ( Core.FullModel { global | zone = newTimeZone } model, Cmd.none )

                ( Core.HomeClicked, Core.LoggedIn { session } ) ->
                    ( Core.FullModel global
                        (Core.LoggedIn
                            { session = session
                            , tab = LoggedIn.init
                            }
                        )
                    , Nav.pushUrl global.key "/"
                    )

                ( Core.LoginClicked, _ ) ->
                    ( Core.FullModel global (Core.homeLogin Login.init), Cmd.none )

                ( Core.LogoutClicked, _ ) ->
                    ( Core.FullModel global Core.home, Api.logOut (\_ -> Core.Noop) )

                ( Core.SignUpClicked, _ ) ->
                    ( Core.FullModel global (Core.homeSignUp SignUp.init), Cmd.none )

                ( Core.ForgotPasswordClicked, _ ) ->
                    ( Core.FullModel global (Core.homeForgotPassword ForgotPassword.init), Cmd.none )

                ( Core.AboutClicked, _ ) ->
                    ( Core.FullModel { global | showAbout = True } model, Cmd.none )

                ( Core.AboutClosed, _ ) ->
                    ( Core.FullModel { global | showAbout = False } model, Cmd.none )

                -- OTHER MODULES MESSAGES
                ( Core.LoginMsg loginMsg, Core.Home (Core.HomeLogin loginModel) ) ->
                    let
                        ( m, cmd ) =
                            Login.update loginMsg loginModel
                    in
                    ( Core.FullModel global m, cmd )

                ( Core.ForgotPasswordMsg forgotPasswordMsg, Core.Home (Core.HomeForgotPassword forgotPasswordModel) ) ->
                    let
                        ( m, cmd ) =
                            ForgotPassword.update forgotPasswordMsg forgotPasswordModel
                    in
                    ( Core.FullModel global m, cmd )

                ( Core.ResetPasswordMsg resetPasswordMsg, Core.ResetPassword resetPasswordModel ) ->
                    let
                        ( m, cmd ) =
                            ResetPassword.update resetPasswordMsg resetPasswordModel
                    in
                    ( Core.FullModel global m, cmd )

                ( Core.SignUpMsg signUpMsg, Core.Home (Core.HomeSignUp signUpModel) ) ->
                    let
                        ( m, cmd ) =
                            SignUp.update signUpMsg signUpModel
                    in
                    ( Core.FullModel global (Core.homeSignUp m), cmd )

                ( Core.LoggedInMsg newProjectMsg, Core.LoggedIn { session, tab } ) ->
                    let
                        ( newGlobal, m, cmd ) =
                            LoggedIn.update newProjectMsg global (LoggedIn.Model session tab)
                    in
                    ( Core.FullModel newGlobal (Core.LoggedIn m), cmd )

                -- Url message
                ( Core.UrlRequested (Browser.Internal url), _ ) ->
                    ( Core.FullModel global model
                    , Api.get
                        { url = Url.toString url
                        , body = Http.emptyBody
                        , expect = Http.expectJson (resultToMsg global) Decode.value
                        }
                    )

                ( Core.UrlRequested (Browser.External url), _ ) ->
                    ( Core.FullModel global model, Nav.load url )

                ( Core.UrlReceived m c, _ ) ->
                    ( Core.FullModel global m, c )

                ( Core.CopyUrl url, _ ) ->
                    ( Core.FullModel global model, Ports.copyString url )

                -- Websocket messages
                ( Core.WebSocket wMsg, _ ) ->
                    let
                        _ =
                            Log.debug "websocket msg" wMsg
                    in
                    ( Core.FullModel global model, Cmd.none )

                ( m, _ ) ->
                    let
                        _ =
                            Log.debug "Unhandled message" m
                    in
                    ( Core.FullModel global model, Cmd.none )

        -- If model is acquisition and returnModel is not, we need to turn off the camera
        closeCamera =
            case ( isAcquisition model, isAcquisition returnModel.model ) of
                ( True, False ) ->
                    Ports.exit ()

                _ ->
                    Cmd.none
    in
    ( returnModel, Cmd.batch [ returnCmd, closeCamera ] )


isAcquisition : Core.Model -> Bool
isAcquisition model =
    case model of
        Core.LoggedIn { tab } ->
            case tab of
                LoggedIn.Acquisition _ ->
                    True

                _ ->
                    False

        _ ->
            False


resultToMsg : Core.Global -> Result Http.Error Decode.Value -> Core.Msg
resultToMsg global result =
    case Result.map (\x -> Core.modelFromFlags global x) result of
        Ok ( m, c ) ->
            Core.UrlReceived m c

        Err _ ->
            Core.Noop


onUrlChange : Url.Url -> Core.Msg
onUrlChange url =
    Core.UrlRequested (Browser.Internal url)


onUrlRequest : Browser.UrlRequest -> Core.Msg
onUrlRequest request =
    Core.UrlRequested request
