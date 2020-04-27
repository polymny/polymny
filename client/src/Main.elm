module Main exposing (main)

import Browser
import Core.Types as Core
import Core.Updates as Core
import Core.Views as Core
import Json.Decode as Decode


main : Program Decode.Value Core.FullModel Core.Msg
main =
    Browser.element
        { init = Core.init
        , update = Core.update
        , view = Core.view
        , subscriptions = Core.subscriptions
        }
