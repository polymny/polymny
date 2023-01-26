module Production.Updates exposing (..)

{-| This module deals with the updates of the production page.
-}

import App.Types as App
import Production.Types as Production


{-| Updates the model.
-}
update : Production.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case msg of
        Production.Noop ->
            ( model, Cmd.none )
