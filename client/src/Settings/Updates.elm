module Settings.Updates exposing (..)

{-| This module contains the updates of the settings page.
-}

import Api.User as Api
import App.Types as App
import RemoteData
import Settings.Types as Settings


{-| Update function for the settings page.
-}
update : Settings.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case model.page of
        App.Settings (Settings.Info s) ->
            case msg of
                Settings.InfoNewEmailChanged newEmail ->
                    ( { model | page = App.Settings <| Settings.Info { s | newEmail = newEmail } }
                    , Cmd.none
                    )

                Settings.InfoNewEmailConfirm ->
                    ( { model | page = App.Settings <| Settings.Info <| { s | data = RemoteData.Loading Nothing } }
                    , Api.changeEmail s.newEmail (\x -> App.SettingsMsg <| Settings.InfoNewEmailDataChanged x)
                    )

                Settings.InfoNewEmailDataChanged d ->
                    ( { model | page = App.Settings <| Settings.Info { s | data = d } }, Cmd.none )

        _ ->
            ( model, Cmd.none )
