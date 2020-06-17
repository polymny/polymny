module Preparation.Views exposing (view)

import Api
import Capsule.Views as Capsule
import Core.Types as Core
import Element exposing (Element)
import LoggedIn.Types as LoggedIn
import Preparation.Types as Preparation
import Ui.Ui as Ui


view : Core.Global -> Api.Session -> Preparation.Model -> Element Core.Msg
view global session preparationModel =
    let
        preparationClickedMsg =
            Just <|
                Core.LoggedInMsg <|
                    LoggedIn.PreparationMsg <|
                        Preparation.PreparationClicked

        clicktab =
            headerView [] <| Ui.linkButton preparationClickedMsg "Préparation"

        mainPage =
            case preparationModel of
                Preparation.Capsule capsule ->
                    Capsule.view session capsule clicktab

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


homeView : Core.Global -> Api.Session -> Element Core.Msg
homeView global session =
    Element.column []
        [ Element.el []
            (Element.text "Welcome")
        ]


headerView : List (Element Core.Msg) -> Element Core.Msg -> List (Element Core.Msg)
headerView header el =
    case List.length header of
        0 ->
            [ el ]

        _ ->
            header ++ [ el ]
