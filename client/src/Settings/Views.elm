module Settings.Views exposing (..)

{-| This module contains the views for the settings page.
-}

import App.Types as App
import Config exposing (Config)
import Data.User as Data exposing (User)
import Element exposing (Element)
import Settings.Types as Settings


{-| The view function for the settings page.
-}
view : Config -> User -> Settings.Model -> ( Element App.Msg, Element App.Msg )
view config user model =
    ( Element.none, Element.none )
