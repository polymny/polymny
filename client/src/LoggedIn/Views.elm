module LoggedIn.Views exposing (view)

import Acquisition.Types as Acquisition
import Acquisition.Views as Acquisition
import Api
import Core.Types as Core
import Element exposing (Element)
import Element.Font as Font
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

        preparationClickedMsg =
            Just <|
                Core.LoggedInMsg <|
                    LoggedIn.PreparationMsg <|
                        Preparation.PreparationClicked

        acquisitionClickedMsg =
            Just <|
                Core.LoggedInMsg <|
                    LoggedIn.AcquisitionMsg <|
                        Acquisition.AcquisitionClicked

        menuTab =
            Element.row Ui.menuTabAttributes
                [ (if LoggedIn.isPreparation tab then
                    Ui.tabButtonActive

                   else
                    Ui.tabButton
                        preparationClickedMsg
                  )
                  <|
                    "Préparation"
                , (if LoggedIn.isAcquisition tab then
                    Ui.tabButtonActive

                   else
                    Ui.tabButton
                        acquisitionClickedMsg
                  )
                  <|
                    "Acquisition"
                , Ui.tabButton Nothing "Edition"
                ]

        element =
            Element.column
                [ Element.alignTop
                , Element.padding 10
                , Element.width Element.fill
                , Element.scrollbarX
                ]
                [ welcomeHeading session.username
                , menuTab
                , mainTab
                ]
    in
    Element.row
        [ Element.height Element.fill
        , Element.width Element.fill
        , Element.spacing 20
        ]
        [ element ]


welcomeHeading : String -> Element Core.Msg
welcomeHeading name =
    Element.el [ Font.size 20, Element.padding 10 ] (Element.text ("Welcome " ++ name ++ "!"))
