module SignUp.Updates exposing (update)

import Api
import Core.Types as Core
import SignUp.Types as SignUp
import Status


update : SignUp.Msg -> SignUp.Model -> ( SignUp.Model, Cmd Core.Msg )
update msg content =
    case msg of
        SignUp.UsernameChanged newUsername ->
            ( { content | username = newUsername }, Cmd.none )

        SignUp.PasswordChanged newPassword ->
            ( { content | password = newPassword }, Cmd.none )

        SignUp.EmailChanged newEmail ->
            ( { content | email = newEmail }, Cmd.none )

        SignUp.Submitted ->
            ( { content | status = Status.Sent }
            , Api.signUp (\_ -> Core.SignUpMsg SignUp.Success) content
            )

        SignUp.Success ->
            ( { content | status = Status.Success () }, Cmd.none )
