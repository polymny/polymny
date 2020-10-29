module SignUp.Updates exposing (update)

import Api
import Core.Types as Core
import Http
import SignUp.Types as SignUp
import Status


update : SignUp.Msg -> SignUp.Model -> ( SignUp.Model, Cmd Core.Msg )
update msg content =
    case msg of
        SignUp.UsernameChanged newUsername ->
            ( { content | username = newUsername }, Cmd.none )

        SignUp.PasswordChanged newPassword ->
            ( { content | password = newPassword }, Cmd.none )

        SignUp.PasswordConfirmationChanged newPasswordConfirmation ->
            ( { content | passwordConfirmation = newPasswordConfirmation }, Cmd.none )

        SignUp.EmailChanged newEmail ->
            ( { content | email = newEmail }, Cmd.none )

        SignUp.Submitted ->
            ( { content | status = Status.Sent }
            , Api.signUp resultToMsg content
            )

        SignUp.Success ->
            ( { content | status = Status.Success () }, Cmd.none )

        SignUp.Failed message ->
            ( { content | status = Status.Error message }, Cmd.none )


resultToMsg result =
    case result of
        Ok _ ->
            Core.SignUpMsg SignUp.Success

        Err (Http.BadStatus 404) ->
            Core.SignUpMsg (SignUp.Failed "Le nom d'utilisateur ou l'addresse e-mail est déjà utilisée")

        Err _ ->
            Core.SignUpMsg (SignUp.Failed "L'inscription a échouée pour une raison inconnue")
