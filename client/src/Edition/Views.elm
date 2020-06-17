module Edition.Views exposing (view)

import Acquisition.Types as Acquisition
import Api
import Core.Types as Core
import Edition.Types as Edition
import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes
import LoggedIn.Types as LoggedIn
import Preparation.Types as Preparation
import Status
import Ui.Ui as Ui


view : Core.Global -> Api.Session -> Edition.Model -> Element Core.Msg
view _ _ model =
    let
        mainPage =
            mainView model

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


mainView : Edition.Model -> Element Core.Msg
mainView { status, details } =
    let
        message =
            case status of
                Status.Sent ->
                    Ui.messageWithSpinner "Edition automatique en cours"

                Status.Success () ->
                    Element.text "Edition auto terrminée"

                _ ->
                    Element.text "Evenement non prevus"

        video =
            case details.video of
                Just x ->
                    Element.html <| htmlVideo x.asset_path

                Nothing ->
                    Element.none
    in
    Element.column [ Element.spacing 10, Element.width Element.fill ]
        [ Element.text ("Coucou Edition " ++ String.fromInt details.capsule.id)
        , headerView details
        , message
        , video
        ]


headerView : Api.CapsuleDetails -> Element Core.Msg
headerView details =
    let
        msgPreparation =
            Just <|
                Core.LoggedInMsg <|
                    LoggedIn.PreparationClicked details

        msgAcquisition =
            Just <|
                Core.LoggedInMsg <|
                    LoggedIn.AcquisitionClicked details
    in
    Element.row []
        [ Ui.primaryButton msgPreparation "Preparation"
        , Ui.primaryButton msgAcquisition "Acquisition"
        , Ui.primaryButtonDisabled "Edition"
        ]


htmlVideo : String -> Html msg
htmlVideo url =
    Html.video
        [ Html.Attributes.controls True
        , Html.Attributes.width 400
        ]
        [ Html.source
            [ Html.Attributes.src url ]
            []
        ]
