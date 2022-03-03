module NewCapsule.Views exposing (view)

{-| This module contains the new caspule page view.

@docs view

-}

import App.Types as App
import Config exposing (Config)
import Data.User as Data exposing (User)
import Element exposing (Element)
import NewCapsule.Types as NewCapsule


{-| The view function for the new capsule page.
-}
view : Config -> User -> NewCapsule.Model -> Element App.Msg
view config user model =
    Element.none
