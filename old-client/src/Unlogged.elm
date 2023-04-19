module Unlogged exposing (main)

import Browser
import Json.Decode as Decode
import Unlogged.Types as Unlogged
import Unlogged.Updates as Unlogged
import Unlogged.Views as Unlogged


main : Program Decode.Value (Maybe Unlogged.Model) Unlogged.Msg
main =
    Browser.application
        { init = Unlogged.init
        , update = Unlogged.update
        , view = Unlogged.view
        , subscriptions = \_ -> Sub.none
        , onUrlChange = \_ -> Unlogged.Noop
        , onUrlRequest = Unlogged.onUrlRequest
        }
