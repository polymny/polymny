module Settings.Views exposing (view)

import Api
import Core.Types as Core
import Element exposing (Element)
import Element.Font as Font
import Element.Input as Input
import LoggedIn.Types as LoggedIn
import Settings.Types as Settings
import Status
import Ui.Ui as Ui
import Webcam


view : Core.Global -> Api.Session -> Settings.Model -> Element Core.Msg
view global session model =
    let
        mainPage =
            mainView global session model

        element =
            Element.column Ui.mainViewAttributes2
                [ mainPage
                ]
    in
    Element.row Ui.mainViewAttributes1
        [ element ]


mainView : Core.Global -> Api.Session -> Settings.Model -> Element Core.Msg
mainView global session model =
    Element.column
        [ Element.padding 10
        , Element.spacing 20
        ]
        [ Element.el [] <| Element.text <| "Coucou Settings " ++ session.username
        , webcamOptionsView session model
        ]


webcamOptionsView : Api.Session -> Settings.Model -> Element Core.Msg
webcamOptionsView session { status } =
    let
        withVideo =
            Maybe.withDefault True session.withVideo

        webcamSize =
            Maybe.withDefault Webcam.Medium session.webcamSize

        webcamPosition =
            Maybe.withDefault Webcam.BottomLeft session.webcamPosition

        message =
            case status of
                Status.Error () ->
                    Just (Ui.errorModal "La mise à jours des options à échouée")

                Status.Success () ->
                    Just (Ui.successModal "Options mises à jour!")

                _ ->
                    Nothing

        submitOnEnter =
            case status of
                Status.Sent ->
                    []

                Status.Success () ->
                    []

                _ ->
                    [ Ui.onEnter Settings.OptionsSubmitted ]

        submitButton =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "en cours ...."

                _ ->
                    Ui.primaryButton (Just Settings.OptionsSubmitted) "Valider les Options"

        videoFields =
            [ Input.radio
                [ Element.padding 10
                , Element.spacing 20
                ]
                { onChange = Settings.WebcamSizeChanged
                , selected = Just webcamSize
                , label = Input.labelAbove [] (Element.text "taille de l'incrustation webcam")
                , options =
                    [ Input.option Webcam.Small (Element.text "Petit")
                    , Input.option Webcam.Medium (Element.text "Moyen")
                    , Input.option Webcam.Large (Element.text "Grand")
                    ]
                }
            , Input.radio
                [ Element.padding 10
                , Element.spacing 20
                ]
                { onChange = Settings.WebcamPositionChanged
                , selected = Just webcamPosition
                , label = Input.labelAbove [] (Element.text "Position de l'incrustation")
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
                { onChange = Settings.WithVideoChanged
                , icon = Input.defaultCheckbox
                , checked = withVideo
                , label =
                    Input.labelRight [] <|
                        Element.text <|
                            if withVideo then
                                "Audio + vidéo . La vidéo et l'audio seront utilisés"

                            else
                                "Audio. Uniquement l'audio sera utilisé"
                }

        fields =
            if withVideo then
                (commmonFields :: videoFields) ++ [ submitButton ]

            else
                [ commmonFields, submitButton ]

        header =
            Element.row [ Element.centerX, Font.bold ] [ Element.text "Options d'édition de la vidéo" ]

        form =
            case message of
                Just m ->
                    header :: m :: fields

                Nothing ->
                    header :: fields
    in
    Element.map Core.LoggedInMsg <|
        Element.map LoggedIn.SettingsMsg <|
            Element.column [ Element.centerX, Element.padding 10, Element.spacing 10 ]
                form
