module Login.Updates exposing (update)

import Api
import Core.Types as Core
import Core.Utils as Core
import LoggedIn.Types as LoggedIn
import Login.Types as Login
import Status
import Utils


update : Login.Msg -> Login.Model -> ( Core.Model, Cmd Core.Msg )
update loginMsg content =
    case loginMsg of
        Login.UsernameChanged newUsername ->
            ( Core.homeLogin { content | username = newUsername }, Cmd.none )

        Login.PasswordChanged newPassword ->
            ( Core.homeLogin { content | password = newPassword }, Cmd.none )

        Login.Submitted ->
            ( Core.homeLogin { content | status = Status.Sent }
            , Api.login resultToMsg content
            )

        Login.Success s ->
            ( Core.LoggedIn (LoggedIn.Model s LoggedIn.init), Cmd.none )

        Login.Failed ->
            ( Core.homeLogin { content | status = Status.Error () }, Cmd.none )


resultToMsg : Result e Api.Session -> Core.Msg
resultToMsg result =
    Utils.resultToMsg (\x -> Core.LoginMsg (Login.Success x)) (\_ -> Core.LoginMsg Login.Failed) result
