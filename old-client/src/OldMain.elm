module OldMain exposing (main)

import Browser
import Core.Subscriptions as Core
import Core.Types as Core
import Core.Updates as Core
import Core.Utils as Core
import Core.Views as Core
import Json.Decode as Decode


main : Program Decode.Value (Maybe Core.Model) Core.Msg
main =
    Browser.application
        { init = Core.init
        , update = Core.update
        , view = Core.view
        , subscriptions = Core.subscriptions
        , onUrlChange = Core.OnUrlChange
        , onUrlRequest = Core.onUrlRequest
        }
