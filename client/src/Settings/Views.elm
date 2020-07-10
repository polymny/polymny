module Settings.Views exposing (view)

import Api
import Core.Types as Core
import Element exposing (Element)
import Settings.Types as Settings
import Ui.Ui as Ui


view : Core.Global -> Api.Session -> Settings.Model -> Element Core.Msg
view global session model =
    let
        mainPage =
            mainView global session model

        element =
            Element.column Ui.mainViewAttributes2
                [ mainPage
                ]
    in
    Element.row Ui.mainViewAttributes1
        [ element ]


mainView : Core.Global -> Api.Session -> Settings.Model -> Element Core.Msg
mainView global session model =
    Element.el [] <| Element.text <| "Coucou Settings " ++ session.username
