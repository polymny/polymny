module Main exposing (main)

import App.Types as App
import App.Updates as App
import App.Utils as App
import App.Views as App
import Browser
import Json.Decode as Decode


main : Program Decode.Value App.MaybeModel App.MaybeMsg
main =
    Browser.application
        { init = App.init
        , update = App.update
        , view = App.view
        , subscriptions = App.subs
        , onUrlChange = \x -> App.LoggedMsg (App.OnUrlChange x)
        , onUrlRequest = \x -> App.LoggedMsg (App.onUrlRequest x)
        }
