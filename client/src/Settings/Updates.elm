module Settings.Updates exposing (..)

{-| This module contains the updates of the settings page.
-}

import App.Types as App
import Settings.Types as Settings


{-| Update function for the settings page.
-}
update : Settings.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case model.page of
        App.Settings m ->
            case msg of
                Settings.Noop ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )
