module Collaboration.Updates exposing (..)

{-| This module helps us deal with collaboration updates.
-}

import App.Types as App
import App.Utils as App
import Collaboration.Types as Collaboration


{-| Update function for the collaboration page.
-}
update : Collaboration.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    let
        ( maybeCapsule, maybeGos ) =
            App.capsuleAndGos model.user model.page
    in
    case ( model.page, maybeCapsule ) of
        ( App.Collaboration m, Just capsule ) ->
            case msg of
                _ ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )
