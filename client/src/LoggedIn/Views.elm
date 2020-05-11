module LoggedIn.Views exposing (view)

import Acquisition.Types as Acquisition
import Acquisition.Views as Acquisition
import Api
import Core.Types as Core
import Element exposing (Element)
import LoggedIn.Types as LoggedIn
import Preparation.Types as Preparation
import Preparation.Views as Preparation
import Ui.Ui as Ui


view : Core.Global -> Api.Session -> LoggedIn.Tab -> Element Core.Msg
view global session tab =
    let
        mainTab =
            case tab of
                LoggedIn.Home ->
                    Preparation.view global session Preparation.Home

                LoggedIn.Preparation preparationModel ->
                    Preparation.view global session preparationModel

                LoggedIn.Acquisition acquisitionModel ->
                    Acquisition.view global session acquisitionModel

                LoggedIn.Edition ->
                    Preparation.view global session Preparation.Home

                LoggedIn.Publication ->
                    Preparation.view global session Preparation.Home

        menuTab =
            Element.row []
                [ Element.el [] <| Element.text "Preparation | "
                , Ui.linkButton
                    (Just <|
                        Core.LoggedInMsg <|
                            LoggedIn.AcquisitionMsg <|
                                Acquisition.AcquisitionClicked
                    )
                    "Acquisition |"
                , Element.el [] <| Element.text "Edition"
                ]

        element =
            Element.column
                [ Element.alignTop
                , Element.padding 10
                , Element.width Element.fill
                , Element.scrollbarX
                ]
                [ menuTab
                , mainTab
                ]
    in
    Element.row
        [ Element.height Element.fill
        , Element.width Element.fill
        , Element.spacing 20
        ]
        [ element ]
