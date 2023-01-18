module Unlogged.Updates exposing (..)

{-| This module contains the unlogged updates of the app.
-}

import Unlogged.Types as Unlogged


update : Unlogged.Msg -> Unlogged.Model -> ( Unlogged.Model, Cmd Unlogged.Msg )
update msg model =
    case msg of
        Unlogged.UsernameChanged newUsername ->
            ( { model | username = newUsername }, Cmd.none )

        Unlogged.EmailChanged newEmail ->
            ( { model | email = newEmail }, Cmd.none )

        Unlogged.PasswordChanged newPassword ->
            ( { model | password = newPassword }, Cmd.none )

        Unlogged.RepeatPasswordChanged newRepeatPassword ->
            ( { model | confirmPassword = newRepeatPassword }, Cmd.none )

        Unlogged.PageChanged newPage ->
            ( { model | page = newPage }, Cmd.none )
