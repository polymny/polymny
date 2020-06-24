module Edition.Views exposing (view)

import Api
import Core.Types as Core
import Edition.Types as Edition
import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes
import LoggedIn.Types as LoggedIn
import Status
import Ui.Ui as Ui
import Utils


view : Core.Global -> Api.Session -> Edition.Model -> Element Core.Msg
view global _ model =
    let
        mainPage =
            mainView global model

        element =
            Element.column Ui.mainViewAttributes2
                [ Utils.headerView "edition" model.details
                , mainPage
                ]
    in
    Element.row Ui.mainViewAttributes1
        [ element ]


mainView : Core.Global -> Edition.Model -> Element Core.Msg
mainView global { status, details } =
    let
        video =
            case details.video of
                Just x ->
                    Element.html <| htmlVideo x.asset_path

                Nothing ->
                    Element.none

        button =
            case ( details.capsule.published, details.video ) of
                ( Api.NotPublished, _ ) ->
                    Ui.primaryButton (Just Edition.PublishVideo) "Publier la video"
                        |> Element.map LoggedIn.EditionMsg
                        |> Element.map Core.LoggedInMsg

                ( Api.Publishing, _ ) ->
                    Element.text "Publication en cours..."

                ( Api.Published, Just v ) ->
                    Element.link []
                        { url = global.videoRoot ++ "/?v=" ++ v.uuid
                        , label = Ui.linkButton Nothing "Voir la vidéo publiée"
                        }

                ( _, _ ) ->
                    Element.none

        ( element, publishButton ) =
            case status of
                Status.Sent ->
                    ( Ui.messageWithSpinner "Edition automatique en cours", Element.none )

                Status.Success () ->
                    ( video, button )

                _ ->
                    ( Element.text "Evenement non prevus", Element.none )
    in
    Element.column
        [ Element.centerX ]
        [ element
        , publishButton
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
