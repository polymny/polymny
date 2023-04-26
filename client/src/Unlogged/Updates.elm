port module Unlogged.Updates exposing (..)

{-| This module contains the unlogged updates of the app.
-}

import Api.User as Api
import Browser.Navigation
import Data.Types as Data
import Keyboard
import RemoteData
import Unlogged.Types as Unlogged


{-| Updates the unlogged part of the app.
-}
update : Unlogged.Msg -> Unlogged.Model -> ( Unlogged.Model, Cmd Unlogged.Msg )
update msg model =
    let
        root =
            model.serverRoot

        sortBy =
            { key = Data.Name, ascending = False }
    in
    case ( msg, model.page ) of
        ( Unlogged.UsernameChanged newUsername, _ ) ->
            ( { model | username = newUsername }, Cmd.none )

        ( Unlogged.EmailChanged newEmail, _ ) ->
            ( { model | email = newEmail }, Cmd.none )

        ( Unlogged.PasswordChanged newPassword, _ ) ->
            ( { model | password = newPassword }, Cmd.none )

        ( Unlogged.RepeatPasswordChanged newRepeatPassword, _ ) ->
            ( { model | repeatPassword = newRepeatPassword }, Cmd.none )

        ( Unlogged.AcceptTermsOfServiceChanged v, _ ) ->
            ( { model | acceptTermsOfService = v }, Cmd.none )

        ( Unlogged.SignUpForNewsletterChanged v, _ ) ->
            ( { model | signUpForNewsletter = v }, Cmd.none )

        ( Unlogged.PageChanged newPage, _ ) ->
            ( { model | page = newPage }, Cmd.none )

        ( Unlogged.ButtonClicked, Unlogged.Login ) ->
            ( { model | loginRequest = RemoteData.Loading Nothing }
            , Api.login
                root
                sortBy
                model.username
                model.password
                (\x -> Unlogged.LoginRequestChanged x)
            )

        ( Unlogged.ButtonClicked, Unlogged.ForgotPassword ) ->
            ( { model | newPasswordRequest = RemoteData.Loading Nothing }
            , Api.requestNewPassword root model.email (\x -> Unlogged.NewPasswordRequestChanged x)
            )

        ( Unlogged.ButtonClicked, Unlogged.ResetPassword key ) ->
            ( { model | newPasswordRequest = RemoteData.Loading Nothing }
            , Api.resetPassword
                sortBy
                key
                model.password
                (\x -> Unlogged.ResetPasswordRequestChanged x)
            )

        ( Unlogged.ButtonClicked, Unlogged.SignUp ) ->
            ( { model | signUpRequest = RemoteData.Loading Nothing }
            , Api.signUp root model (\x -> Unlogged.SignUpRequestChanged x)
            )

        ( Unlogged.LoginRequestChanged (RemoteData.Success _), _ ) ->
            -- This never happens on the full app, it only happens when embedding the form on the portal (in the full
            -- app, this case is caught in App.Updates).
            ( model, submitForm "loginform" )

        ( Unlogged.LoginRequestChanged data, _ ) ->
            ( { model | loginRequest = data }, Cmd.none )

        ( Unlogged.NewPasswordRequestChanged data, _ ) ->
            ( { model | newPasswordRequest = data }, Cmd.none )

        ( Unlogged.ResetPasswordRequestChanged (RemoteData.Success _), _ ) ->
            ( model, Browser.Navigation.load model.serverRoot )

        ( Unlogged.ResetPasswordRequestChanged data, _ ) ->
            ( { model | resetPasswordRequest = data }, Cmd.none )

        ( Unlogged.SignUpRequestChanged data, _ ) ->
            ( { model | signUpRequest = data }, Cmd.none )

        ( Unlogged.Noop, _ ) ->
            ( model, Cmd.none )


port submitForm : String -> Cmd msg


{-| Sup.
-}
updateStandalone : Unlogged.Msg -> Maybe Unlogged.Model -> ( Maybe Unlogged.Model, Cmd Unlogged.Msg )
updateStandalone msg model =
    case model of
        Just m ->
            update msg m |> Tuple.mapFirst Just

        _ ->
            ( Nothing, Cmd.none )


{-| Keyboard shortcuts of the unlogged page.
-}
shortcuts : Keyboard.RawKey -> Unlogged.Msg
shortcuts msg =
    case Keyboard.rawValue msg of
        "Enter" ->
            Unlogged.ButtonClicked

        _ ->
            Unlogged.Noop


{-| Subscriptions of the page.
-}
subs : Sub Unlogged.Msg
subs =
    Sub.batch
        [ Keyboard.ups shortcuts
        ]
