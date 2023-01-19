module Unlogged.Updates exposing (..)

{-| This module contains the unlogged updates of the app.
-}

import Api.User as Api
import RemoteData
import Unlogged.Types as Unlogged


{-| Updates the unlogged part of the app.
-}
update : Unlogged.Msg -> Unlogged.Model -> ( Unlogged.Model, Cmd Unlogged.Msg )
update msg model =
    case ( msg, model.page ) of
        ( Unlogged.UsernameChanged newUsername, _ ) ->
            ( { model | username = newUsername }, Cmd.none )

        ( Unlogged.EmailChanged newEmail, _ ) ->
            ( { model | email = newEmail }, Cmd.none )

        ( Unlogged.PasswordChanged newPassword, _ ) ->
            ( { model | password = newPassword }, Cmd.none )

        ( Unlogged.RepeatPasswordChanged newRepeatPassword, _ ) ->
            ( { model | repeatPassword = newRepeatPassword }, Cmd.none )

        ( Unlogged.PageChanged newPage, _ ) ->
            ( { model | page = newPage }, Cmd.none )

        ( Unlogged.ButtonClicked, Unlogged.Login ) ->
            ( { model | loginRequest = RemoteData.Loading Nothing }
            , Api.login
                model.config.clientConfig.sortBy
                model.username
                model.password
                (\x -> Unlogged.LoginRequestChanged x)
            )

        ( Unlogged.ButtonClicked, Unlogged.ForgotPassword ) ->
            ( { model | newPasswordRequest = RemoteData.Loading Nothing }
            , Api.requestNewPassword model.email (\x -> Unlogged.NewPasswordRequestChanged x)
            )

        ( Unlogged.ButtonClicked, Unlogged.ResetPassword key ) ->
            ( { model | newPasswordRequest = RemoteData.Loading Nothing }
            , Api.resetPassword
                model.config.clientConfig.sortBy
                key
                model.password
                (\x -> Unlogged.ResetPasswordRequestChanged x)
            )

        ( Unlogged.ButtonClicked, _ ) ->
            ( model, Cmd.none )

        ( Unlogged.LoginRequestChanged data, _ ) ->
            ( { model | loginRequest = data }, Cmd.none )

        ( Unlogged.NewPasswordRequestChanged data, _ ) ->
            ( { model | newPasswordRequest = data }, Cmd.none )

        ( Unlogged.ResetPasswordRequestChanged data, _ ) ->
            ( { model | resetPasswordRequest = data }, Cmd.none )
