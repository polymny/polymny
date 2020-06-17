module Preparation.Views exposing (view)

import Api
import Capsule.Views as Capsule
import Core.Types as Core
import Element exposing (Element)
import Preparation.Types as Preparation


view : Core.Global -> Api.Session -> Preparation.Model -> Element Core.Msg
view global session preparationModel =
    let
        mainPage =
            case preparationModel of
                Preparation.Capsule capsule ->
                    Capsule.view session capsule []

        element =
            Element.column
                [ Element.alignTop
                , Element.padding 10
                , Element.width Element.fill
                , Element.scrollbarX
                ]
                [ mainPage
                ]
    in
    Element.row
        [ Element.height Element.fill
        , Element.width Element.fill
        , Element.spacing 20
        ]
        [ element ]
