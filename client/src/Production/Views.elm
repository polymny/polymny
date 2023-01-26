module Production.Views exposing (..)

{-| Views for the production page.
-}

import App.Types as App
import Config exposing (Config)
import Data.User exposing (User)
import Element exposing (Element)
import Production.Types as Production


view : Config -> User -> Production.Model -> ( Element App.Msg, Element App.Msg )
view config user model =
    ( Element.none, Element.none )
