module Edition.Views exposing (view)

import Api
import Core.Types as Core
import Edition.Types as Edition
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input
import Html exposing (Html)
import Html.Attributes
import LoggedIn.Types as LoggedIn
import Status
import Ui.Attributes as Attributes
import Ui.Colors as Colors
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
mainView global model =
    let
        details =
            model.details

        status =
            model.status

        video =
            case details.video of
                Just x ->
                    Element.el
                        [ Border.color Colors.artEvening
                        , Border.rounded 0
                        , Border.width 2
                        , Element.padding 2
                        , Element.centerX
                        , Element.centerY
                        ]
                    <|
                        Element.html <|
                            htmlVideo x.asset_path

                Nothing ->
                    Element.none

        url_video : Api.Asset -> String
        url_video asset =
            global.videoRoot ++ "/?v=" ++ asset.uuid ++ "/"

        button =
            case ( details.capsule.published, details.video ) of
                ( Api.NotPublished, Just _ ) ->
                    Ui.primaryButton (Just Edition.PublishVideo) "Publier la video"
                        |> Element.map LoggedIn.EditionMsg
                        |> Element.map Core.LoggedInMsg

                ( Api.Publishing, _ ) ->
                    Ui.messageWithSpinner "Publication de vidéo en cours..."

                ( Api.Published, Just v ) ->
                    Element.column
                        (Attributes.boxAttributes
                            ++ [ Element.spacing 20 ]
                        )
                        [ Element.newTabLink
                            [ Element.centerX
                            ]
                            { url = url_video v
                            , label = Ui.primaryButton Nothing "Voir la vidéo publiée"
                            }
                        , Element.text "Lien vers la vidéo publiée : "
                        , Element.el
                            [ Background.color Colors.white
                            , Border.color Colors.whiteDarker
                            , Border.rounded 5
                            , Border.width 1
                            , Element.paddingXY 10 10
                            , Attributes.fontMono
                            ]
                          <|
                            Element.text <|
                                url_video v
                        ]

                ( _, _ ) ->
                    Element.none

        ( element, publishButton ) =
            case status of
                Status.Sent ->
                    ( Ui.messageWithSpinner "Edition automatique en cours", Element.none )

                Status.Success () ->
                    ( video, button )

                Status.Error () ->
                    ( Element.text "Problème rencontré lors de la compostion de la vidéo. Merci de nous contacter", Element.none )

                _ ->
                    ( Element.text "Evenement non prevus", Element.none )
    in
    Element.column
        [ Element.centerX, Element.spacing 20, Element.padding 10 ]
        [ editionOptionView model
        , element
        , publishButton
        ]


editionOptionView : Edition.Model -> Element Core.Msg
editionOptionView { status, withVideo } =
    let
        submitOnEnter =
            case status of
                Status.Sent ->
                    []

                Status.Success () ->
                    []

                _ ->
                    [ Ui.onEnter Edition.OptionsSubmitted ]

        submitButton =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "en cours ...."

                _ ->
                    Ui.primaryButton (Just Edition.OptionsSubmitted) "Soumettre"

        fields =
            [ Input.checkbox []
                { onChange = Edition.WithVideoChanged
                , icon = Input.defaultCheckbox
                , checked = withVideo
                , label =
                    Input.labelRight []
                        (Element.text "Audio + Video")
                }
            , submitButton
            ]

        header =
            Element.row [ Element.centerX ] [ Element.text "Option de génération de la vidéo" ]

        form =
            header :: fields
    in
    Element.map Core.LoggedInMsg <|
        Element.map LoggedIn.EditionMsg <|
            Element.column [ Element.centerX, Element.padding 10, Element.spacing 10 ]
                form


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
