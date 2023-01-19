module Unlogged.Updates exposing (..)

{-| This module contains the unlogged updates of the app.
-}

import Api.User as Api
import App.Types as App
import App.Utils as App
import RemoteData
import Route
import Unlogged.Types as Unlogged


update : Unlogged.Msg -> Unlogged.Model -> ( App.MaybeModel, Cmd App.MaybeMsg )
update msg model =
    case ( msg, model.page ) of
        ( Unlogged.UsernameChanged newUsername, _ ) ->
            ( App.Unlogged { model | username = newUsername }, Cmd.none )

        ( Unlogged.EmailChanged newEmail, _ ) ->
            ( App.Unlogged { model | email = newEmail }, Cmd.none )

        ( Unlogged.PasswordChanged newPassword, _ ) ->
            ( App.Unlogged { model | password = newPassword }, Cmd.none )

        ( Unlogged.RepeatPasswordChanged newRepeatPassword, _ ) ->
            ( App.Unlogged { model | repeatPassword = newRepeatPassword }, Cmd.none )

        ( Unlogged.PageChanged newPage, _ ) ->
            ( App.Unlogged { model | page = newPage }, Cmd.none )

        ( Unlogged.ButtonClicked, Unlogged.Login ) ->
            ( App.Unlogged { model | loginRequest = RemoteData.Loading Nothing }
            , Api.login
                model.config.clientConfig.sortBy
                model.username
                model.password
                (\x -> App.UnloggedMsg (Unlogged.LoginRequestChanged x))
            )

        ( Unlogged.ButtonClicked, Unlogged.ForgotPassword ) ->
            ( App.Unlogged { model | newPasswordRequest = RemoteData.Loading Nothing }
            , Api.requestNewPassword model.email (\x -> App.UnloggedMsg (Unlogged.NewPasswordRequestChanged x))
            )

        ( Unlogged.ButtonClicked, Unlogged.ResetPassword key ) ->
            ( App.Unlogged { model | newPasswordRequest = RemoteData.Loading Nothing }
            , Api.resetPassword
                model.config.clientConfig.sortBy
                key
                model.password
                (\x -> App.UnloggedMsg (Unlogged.ResetPasswordRequestChanged x))
            )

        ( Unlogged.ButtonClicked, _ ) ->
            ( App.Unlogged model, Cmd.none )

        ( Unlogged.LoginRequestChanged (RemoteData.Success user), _ ) ->
            App.pageFromRoute model.config user Route.Home
                |> Tuple.mapBoth
                    (\x -> App.Logged { config = model.config, user = user, page = x })
                    (Cmd.map App.LoggedMsg)

        ( Unlogged.LoginRequestChanged data, _ ) ->
            ( App.Unlogged { model | loginRequest = data }, Cmd.none )

        ( Unlogged.NewPasswordRequestChanged data, _ ) ->
            ( App.Unlogged { model | newPasswordRequest = data }, Cmd.none )

        ( Unlogged.ResetPasswordRequestChanged (RemoteData.Success user), _ ) ->
            App.pageFromRoute model.config user Route.Home
                |> Tuple.mapBoth
                    (\x -> App.Logged { config = model.config, user = user, page = x })
                    (Cmd.map App.LoggedMsg)

        ( Unlogged.ResetPasswordRequestChanged data, _ ) ->
            ( App.Unlogged { model | resetPasswordRequest = data }, Cmd.none )
