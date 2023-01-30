module Production.Updates exposing (..)

{-| This module deals with the updates of the production page.
-}

import Api.Capsule as Api
import App.Types as App
import Production.Types as Production


{-| Updates the model.
-}
update : Production.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case model.page of
        App.Production m ->
            case msg of
                Production.Produce ->
                    ( model, Api.produceCapsule m.capsule (\_ -> App.Noop) )

        _ ->
            ( model, Cmd.none )
