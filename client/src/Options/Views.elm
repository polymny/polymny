module Options.Views exposing (..)

import App.Types as App
import Config exposing (Config)
import Data.User exposing (User)
import Element exposing (Element)
import Options.Types as Options
import Ui.Elements as Ui
import Ui.Utils as Ui


view : Config -> User -> Options.Model -> ( Element App.Msg, Element App.Msg )
view config user model =
    ( Element.row [ Ui.wf, Ui.hf, Ui.s 10, Ui.p 10 ]
        [ Element.column [ Ui.wf, Ui.hf, Ui.s 10, Ui.p 10 ]
            [ Element.text "Options" ]
        ]
    , Element.none
    )
