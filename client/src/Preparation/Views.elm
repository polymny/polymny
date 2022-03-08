module Preparation.Views exposing (..)

{-| The main view for the preparation page.
-}

import App.Types as App
import Config exposing (Config)
import Data.User exposing (User)
import Element exposing (Element)
import Preparation.Types as Preparation


{-| The view function for the preparation page.
-}
view : Config -> User -> Preparation.Model -> Element App.Msg
view config user model =
    Element.none
