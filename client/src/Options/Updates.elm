module Options.Updates exposing (..)

import Api.Capsule as Api
import App.Types as App
import Data.Capsule as Data exposing (Capsule)
import Data.User as Data
import Options.Types as Options


{-| Updates the model.
-}
update : Options.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case model.page of
        App.Options m ->
            case msg of
                Options.SetOpacity opacity ->
                    -- TODO
                    ( model, Cmd.none )

                Options.SetWidth newWidth ->
                    -- TODO
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )
