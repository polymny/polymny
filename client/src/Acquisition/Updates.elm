module Acquisition.Updates exposing (update)

{-| This module contains the update function for the preparation page.

@docs update, subs

-}

import Acquisition.Types as Acquisition
import App.Types as App


{-| The update function of the preparation page.
-}
update : Acquisition.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    ( model, Cmd.none )
