module Preparation.Updates exposing (..)

{-| This module contains the update function for the preparation page.
-}

import App.Types as App
import Preparation.Types as Preparation


{-| The update function of the preparation page.
-}
update : Preparation.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case msg of
        Preparation.DnD sMsg ->
            updateDnD sMsg model


{-| The update function for the DnD part of the page.
-}
updateDnD : Preparation.DnDMsg -> App.Model -> ( App.Model, Cmd App.Msg )
updateDnD msg model =
    case msg of
        Preparation.SlideMoved sMsg ->
            ( model, Cmd.none )

        Preparation.GosMoved sMsg ->
            ( model, Cmd.none )
