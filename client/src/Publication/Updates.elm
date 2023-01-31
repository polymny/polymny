module Publication.Updates exposing (..)

{-| This module contains the updates for the publication view.
-}

import App.Types as App
import Publication.Types as Publication


update : Publication.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case model.page of
        App.Publication m ->
            case msg of
                Publication.Noop ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )
