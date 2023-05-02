module Unlogged exposing (..)

{-| Module that makes the login form available as a standalone element.
-}

import Browser
import Json.Decode as Decode
import Unlogged.Types as Unlogged
import Unlogged.Updates as Unlogged
import Unlogged.Views as Unlogged


{-| A main app for displaying the login form in another page (such as our portal).
-}
main : Program Decode.Value (Maybe Unlogged.Model) Unlogged.Msg
main =
    Browser.element
        { init = Unlogged.initStandalone
        , subscriptions = \_ -> Unlogged.subs
        , update = Unlogged.updateStandalone
        , view = Unlogged.viewStandalone
        }
