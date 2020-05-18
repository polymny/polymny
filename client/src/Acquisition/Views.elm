module Acquisition.Views exposing (view)

import Acquisition.Types as Acquisition
import Api
import Core.Types as Core
import Element exposing (Element)


view : Core.Global -> Api.Session -> Acquisition.Model -> Element Core.Msg
view global session preparationModel =
    let
        mainPage =
            case preparationModel of
                Acquisition.Home ->
                    homeView global session

        element =
            Element.column
                [ Element.alignTop
                , Element.padding 10
                , Element.width Element.fill
                , Element.scrollbarX
                ]
                [ mainPage ]
    in
    Element.row
        [ Element.height Element.fill
        , Element.width Element.fill
        , Element.spacing 20
        ]
        [ element ]


homeView : Core.Global -> Api.Session -> Element Core.Msg
homeView _ session =
    Element.column []
        [ Element.el [] <| Element.text "Welcome on acquisition Tab !"
        ]
