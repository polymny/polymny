module Edition.Views exposing (view)

import Api
import Core.Types as Core
import Edition.Types as Edition
import Element exposing (Element)
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
    in
    Element.column [ Element.spacing 10, Element.width Element.fill ]
        [ Element.text ("Coucou Edition " ++ String.fromInt details.capsule.id)
        , message
        ]
