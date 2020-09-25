module Edition.Views exposing (view)

import Api
import Core.Types as Core
import Edition.Types as Edition
import Element exposing (Element)
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import LoggedIn.Types as LoggedIn
import Preparation.Views as Preparation
import Status
import Ui.Colors as Colors
import Ui.Ui as Ui
import Webcam


view : Core.Global -> Api.Session -> Edition.Model -> ( Element Core.Msg, Maybe (Element Core.Msg) )
view global _ model =
    let
        element =
            model.details.capsule.capsuleEditionOptions
                |> Maybe.withDefault Edition.defaultGosProductionChoices
                |> productionForm Nothing
                |> Ui.popup "Options d'édition de la capsule"

        inFront =
            if model.editCapsuleOptions then
                Just element

            else
                Nothing
    in
    ( Element.row
        [ Element.width Element.fill, Element.height Element.fill, Element.scrollbarY ]
        [ Preparation.leftColumnView model.details (Just model.currentGos)
        , centerView global model
        ]
    , inFront
    )


centerView : Core.Global -> Edition.Model -> Element Core.Msg
centerView global model =
    let
        gos =
            List.head (List.drop model.currentGos model.details.structure)
    in
    Element.column [ Element.width (Element.fillPortion 7), Element.height Element.fill ]
        [ gosProductionView model gos
        , bottomRow global model
        ]


gosProductionView : Edition.Model -> Maybe Api.Gos -> Element Core.Msg
gosProductionView model gos =
    let
        resultView =
            case gos of
                Just _ ->
                    Element.row
                        [ Element.width Element.fill
                        , Element.height Element.fill
                        ]
                        [ gosProductionChoicesView model
                        , gosPrevisualisation model
                        ]

                Nothing ->
                    Element.none
    in
    resultView


gosProductionChoicesView : Edition.Model -> Element Core.Msg
gosProductionChoicesView model =
    let
        gos : Maybe Api.Gos
        gos =
            List.head (List.drop model.currentGos model.details.structure)

        gosProductionChoices : Maybe Api.CapsuleEditionOptions
        gosProductionChoices =
            case Maybe.map .production_choices gos of
                Just (Just v) ->
                    Just v

                _ ->
                    Nothing

        productionChoices : Maybe Api.CapsuleEditionOptions
        productionChoices =
            case ( gosProductionChoices, model.details.capsule.capsuleEditionOptions ) of
                ( Just a, _ ) ->
                    Just a

                ( _, Just a ) ->
                    Just a

                _ ->
                    Nothing

        p : Api.CapsuleEditionOptions
        p =
            Maybe.withDefault Edition.defaultGosProductionChoices productionChoices

        useDefault : Bool
        useDefault =
            gosProductionChoices == Nothing

        useGlobalConfig =
            Input.checkbox []
                { onChange = Edition.GosUseDefaultChanged model.currentGos >> LoggedIn.EditionMsg >> Core.LoggedInMsg
                , icon = Input.defaultCheckbox
                , checked = useDefault
                , label = Input.labelRight [] (Element.text "Utiliser les paramètres par défaut de la capsule")
                }

        editGlobalConfig =
            Ui.simpleButton (Just (Core.LoggedInMsg (LoggedIn.EditionMsg Edition.ToggleEditDefault))) "Changer les paramètres par défaut"

        header =
            Element.el [ Element.centerX, Font.bold ] (Element.text "Options d'édition de la vidéo")
    in
    Element.column
        [ Element.alignLeft, Element.padding 10, Element.spacing 30 ]
        [ header, useGlobalConfig, editGlobalConfig, productionForm (Just ( model.currentGos, useDefault )) p ]


productionForm : Maybe ( Int, Bool ) -> Api.CapsuleEditionOptions -> Element Core.Msg
productionForm currentGos p =
    let
        useDefault =
            Maybe.map Tuple.second currentGos == Just True

        msgIfNotDefault : (a -> Edition.Msg) -> (a -> Core.Msg)
        msgIfNotDefault onEvent =
            if useDefault then
                \_ ->
                    Core.Noop

            else
                \x ->
                    Core.LoggedInMsg (LoggedIn.EditionMsg (onEvent x))

        attr =
            if useDefault then
                [ Font.color Colors.grey ]

            else
                []

        withVideo =
            p.withVideo

        webcamSize =
            p.webcamSize

        webcamPosition =
            p.webcamPosition

        videoFieldsAttributesTmp =
            [ Element.padding 10
            , Element.spacing 10
            ]

        videoFieldsAttributes =
            if withVideo then
                videoFieldsAttributesTmp

            else
                Element.htmlAttribute (Html.Attributes.style "visibility" "hidden") :: videoFieldsAttributesTmp

        videoFields =
            [ Input.radio
                videoFieldsAttributes
                { onChange =
                    (case currentGos of
                        Just ( c, _ ) ->
                            Edition.GosWebcamSizeChanged c

                        _ ->
                            Edition.WebcamSizeChanged
                    )
                        |> msgIfNotDefault
                , selected = webcamSize
                , label =
                    Input.labelAbove
                        [ Element.centerX
                        , Font.bold
                        , Element.padding 1
                        ]
                        (Element.text "Taille de l'incrustation webcam:")
                , options =
                    [ Input.option Webcam.Small (Element.text "Petit")
                    , Input.option Webcam.Medium (Element.text "Moyen")
                    , Input.option Webcam.Large (Element.text "Grand")
                    ]
                }
            , Input.radio
                videoFieldsAttributes
                { onChange =
                    (case currentGos of
                        Just ( c, _ ) ->
                            Edition.GosWebcamPositionChanged c

                        _ ->
                            Edition.WebcamPositionChanged
                    )
                        |> msgIfNotDefault
                , selected = webcamPosition
                , label =
                    Input.labelAbove
                        [ Element.centerX
                        , Font.bold
                        , Element.padding 1
                        ]
                        (Element.text "Position de l'incrustation:")
                , options =
                    [ Input.option Webcam.TopLeft (Element.text "En haut à gauche.")
                    , Input.option Webcam.TopRight (Element.text "En haut à droite.")
                    , Input.option Webcam.BottomLeft (Element.text "En bas à gauche.")
                    , Input.option Webcam.BottomRight (Element.text "En bas à droite.")
                    ]
                }
            ]

        commmonFields =
            Input.checkbox []
                { onChange =
                    (case currentGos of
                        Just ( c, _ ) ->
                            Edition.GosWithVideoChanged c

                        _ ->
                            Edition.WithVideoChanged
                    )
                        |> msgIfNotDefault
                , icon = Input.defaultCheckbox
                , checked = withVideo
                , label = Input.labelRight [] (Element.text "Incruster la vidéo")
                }

        fields =
            Element.column (Element.spacing 30 :: attr) (commmonFields :: videoFields)

        exitButton =
            if currentGos == Nothing then
                Ui.simpleButton (Just (Core.LoggedInMsg (LoggedIn.EditionMsg Edition.ToggleEditDefault))) "Valider"

            else
                Element.none
    in
    Element.column
        [ Element.width Element.fill, Element.padding 10, Element.spacing 30 ]
        [ fields, exitButton ]


gosPrevisualisation : Edition.Model -> Element Core.Msg
gosPrevisualisation model =
    let
        currentGos : Maybe Api.Gos
        currentGos =
            List.head (List.drop model.currentGos model.details.structure)

        productionChoices : Api.CapsuleEditionOptions
        productionChoices =
            case ( Maybe.map .production_choices currentGos, model.details.capsule.capsuleEditionOptions ) of
                ( Just (Just c), _ ) ->
                    c

                ( _, Just c ) ->
                    c

                _ ->
                    Edition.defaultGosProductionChoices

        currentSlide : Maybe Api.Slide
        currentSlide =
            Maybe.withDefault Nothing (Maybe.map (\x -> List.head x.slides) currentGos)

        position : List (Element.Attribute Core.Msg)
        position =
            case ( productionChoices.withVideo, Maybe.withDefault Webcam.BottomLeft productionChoices.webcamPosition ) of
                ( True, Webcam.TopLeft ) ->
                    [ Element.alignTop, Element.alignLeft ]

                ( True, Webcam.TopRight ) ->
                    [ Element.alignTop, Element.alignRight ]

                ( True, Webcam.BottomLeft ) ->
                    [ Element.alignBottom, Element.alignLeft ]

                ( True, Webcam.BottomRight ) ->
                    [ Element.alignBottom, Element.alignRight ]

                _ ->
                    []

        size : Int
        size =
            case ( productionChoices.withVideo, Maybe.withDefault Webcam.Medium productionChoices.webcamSize ) of
                ( True, Webcam.Small ) ->
                    1

                ( True, Webcam.Medium ) ->
                    2

                ( True, Webcam.Large ) ->
                    4

                _ ->
                    0

        inFront : Element Core.Msg
        inFront =
            if productionChoices.withVideo then
                Element.el position
                    (Element.image
                        [ Element.width (Element.px (100 * size)) ]
                        { src = "/dist/silhouette.png", description = "" }
                    )

            else
                Element.none

        currentSlideView : Element Core.Msg
        currentSlideView =
            case currentSlide of
                Just s ->
                    Element.image
                        [ Element.width Element.fill
                        , Element.inFront inFront
                        ]
                        { src = s.asset.asset_path, description = "" }

                _ ->
                    Element.none
    in
    Element.el [ Element.width Element.fill ] currentSlideView


bottomRow : Core.Global -> Edition.Model -> Element Core.Msg
bottomRow global model =
    let
        msg =
            Just (Core.LoggedInMsg (LoggedIn.EditionClicked model.details True))

        button =
            Ui.primaryButton msg "Produire la vidéo"

        video =
            case model.details.capsule.video of
                Just x ->
                    Element.newTabLink
                        [ Font.color Colors.link
                        , Border.color Colors.link
                        , Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
                        ]
                        { url = x.asset_path
                        , label = Element.text "Voir la vidéo"
                        }

                Nothing ->
                    Element.text "Pas de vidéo éditée pour l'instant"

        ( element, editButton ) =
            case model.status of
                Status.Sent ->
                    ( Ui.messageWithSpinner "Edition automatique en cours", Element.none )

                Status.Success () ->
                    ( video, button )

                Status.Error () ->
                    ( Element.text "Problème rencontré lors de la compostion de la vidéo. Merci de nous contacter", Element.none )

                Status.NotSent ->
                    ( video, button )

        videoUrl : Api.Asset -> String
        videoUrl asset =
            global.videoRoot ++ "/?v=" ++ asset.uuid ++ "/"

        publishButton =
            case ( model.details.capsule.published, model.details.capsule.video ) of
                ( Api.NotPublished, Just _ ) ->
                    Ui.primaryButton (Just Edition.PublishVideo) "Publier la vidéo"
                        |> Element.map LoggedIn.EditionMsg
                        |> Element.map Core.LoggedInMsg

                ( Api.Publishing, _ ) ->
                    Ui.messageWithSpinner "Publication de vidéo en cours..."

                ( Api.Published, Just v ) ->
                    Element.row [ Element.spacing 10 ]
                        [ Element.newTabLink []
                            { url = videoUrl v
                            , label =
                                Element.el
                                    [ Font.color Colors.link
                                    , Border.color Colors.link
                                    , Border.widthEach { bottom = 1, top = 0, left = 0, right = 0 }
                                    ]
                                    (Element.text "Vidéo publiée")
                            }
                        , Ui.chainButton (Just (Core.LoggedInMsg (LoggedIn.EditionMsg (Edition.CopyUrl (videoUrl v))))) "" "Copier l'url de la vidéo"
                        ]

                ( _, _ ) ->
                    Element.none
    in
    Element.row
        [ Element.alignRight, Element.padding 10, Element.spacing 10 ]
        [ element, editButton, publishButton ]
