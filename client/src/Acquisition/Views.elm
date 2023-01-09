module Acquisition.Views exposing (view)

{-| The main view for the acquisition page.

@docs view

-}

import Acquisition.Types as Acquisition
import App.Types as App
import Config exposing (Config)
import Data.User exposing (User)
import Element exposing (Element)


{-| The view function for the preparation page.
-}
view : Config -> User -> Acquisition.Model -> ( Element App.Msg, Element App.Msg )
view config user model =
    ( Element.none, Element.none )
