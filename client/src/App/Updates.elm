module App.Updates exposing (update, updateModel, subs)

{-| This module contains the update function of the polymny application.

@docs update, updateModel, subs

-}

import App.Types as App
import Config
import Home.Updates as Home


{-| Updates the model from a message, and returns the new model as well as the command to send.
-}
update : App.Msg -> Result App.Error App.Model -> ( Result App.Error App.Model, Cmd App.Msg )
update msg model =
    case model of
        Ok m ->
            updateModel msg m |> Tuple.mapFirst Ok

        _ ->
            ( model, Cmd.none )


{-| Updates a well formed model from a message, and returns the new model as well as the command to send.
-}
updateModel : App.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
updateModel msg model =
    case msg of
        App.Noop ->
            ( model, Cmd.none )

        App.ConfigMsg sMsg ->
            let
                ( newConfig, newMsg ) =
                    Config.update sMsg model.config
            in
            ( { model | config = newConfig }, newMsg )

        App.HomeMsg sMsg ->
            Home.update sMsg model


{-| Returns the subscriptions of the app.
-}
subs : Result App.Error App.Model -> Sub App.Msg
subs m =
    case m of
        Err _ ->
            Sub.none

        Ok model ->
            Sub.batch [ Home.subs model ]
