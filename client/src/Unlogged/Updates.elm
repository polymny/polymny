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
    case msg of
        Unlogged.UsernameChanged newUsername ->
            ( App.Unlogged { model | username = newUsername }, Cmd.none )

        Unlogged.EmailChanged newEmail ->
            ( App.Unlogged { model | email = newEmail }, Cmd.none )

        Unlogged.PasswordChanged newPassword ->
            ( App.Unlogged { model | password = newPassword }, Cmd.none )

        Unlogged.RepeatPasswordChanged newRepeatPassword ->
            ( App.Unlogged { model | repeatPassword = newRepeatPassword }, Cmd.none )

        Unlogged.PageChanged newPage ->
            ( App.Unlogged { model | page = newPage }, Cmd.none )

        Unlogged.ButtonClicked ->
            ( App.Unlogged { model | validate = RemoteData.Loading Nothing }
            , Api.login model.config.clientConfig.sortBy model.username model.password Unlogged.DataChanged
                |> Cmd.map App.UnloggedMsg
            )

        Unlogged.DataChanged (RemoteData.Success user) ->
            App.pageFromRoute model.config user Route.Home
                |> Tuple.mapBoth
                    (\x -> App.Logged { config = model.config, user = user, page = x })
                    (Cmd.map App.LoggedMsg)

        Unlogged.DataChanged data ->
            ( App.Unlogged { model | validate = data }, Cmd.none )
