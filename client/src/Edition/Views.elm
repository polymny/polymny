module Edition.Views exposing (view)

import Api
import Core.Types as Core
import Edition.Types as Edition
import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes
import Status
import Ui.Ui as Ui
import Utils


view : Core.Global -> Api.Session -> Edition.Model -> Element Core.Msg
view _ _ model =
    let
        mainPage =
            mainView model

        element =
            Element.column Ui.mainViewAttributes2
                [ Utils.headerView "edition" model.details
                , mainPage
                ]
    in
    Element.row Ui.mainViewAttributes1
        [ element ]


mainView : Edition.Model -> Element Core.Msg
mainView { status, details } =
    let
        video =
            case details.video of
                Just x ->
                    Element.html <| htmlVideo x.asset_path

                Nothing ->
                    Element.none

        element =
            case status of
                Status.Sent ->
                    Ui.messageWithSpinner "Edition automatique en cours"

                Status.Success () ->
                    video

                _ ->
                    Element.text "Evenement non prevus"
    in
    Element.column
        [ Element.centerX ]
        [ element
        ]


htmlVideo : String -> Html msg
htmlVideo url =
    Html.video
        [ Html.Attributes.controls True
        , Html.Attributes.width 600
        ]
        [ Html.source
            [ Html.Attributes.src url ]
            []
        ]
