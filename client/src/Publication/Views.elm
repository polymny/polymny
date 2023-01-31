module Publication.Views exposing (..)

{-| This module contains the view of the publication page.
-}

import App.Types as App
import Config exposing (Config)
import Data.User as Data exposing (User)
import Element exposing (Element)
import Publication.Types as Publication


view : Config -> User -> Publication.Model -> ( Element App.Msg, Element App.Msg )
view config user model =
    ( Element.none
    , Element.none
    )
