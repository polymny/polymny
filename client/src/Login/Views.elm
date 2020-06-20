module Login.Views exposing (view)

import Core.Types as Core
import Element exposing (Element)
import Element.Input as Input
import Login.Types as Login
import Status
import Ui.Ui as Ui


view : Login.Model -> Element Core.Msg
view { username, password, status } =
    let
        submitOnEnter =
            case status of
                Status.Sent ->
                    []

                Status.Success () ->
                    []

                _ ->
                    [ Ui.onEnter Login.Submitted ]

        submitButton =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "Connection en cours..."

                _ ->
                    Ui.primaryButton (Just Login.Submitted) "Se connecter"

        errorMessage =
            case status of
                Status.Error () ->
                    Just (Ui.errorModal "Connection échouée")

                _ ->
                    Nothing

        header =
            Element.row [ Element.centerX ] [ Element.text "Login" ]

        fields =
            [ Input.username submitOnEnter
                { label = Input.labelAbove [] (Element.text "Nom d'utilisateur")
                , onChange = Login.UsernameChanged
                , placeholder = Nothing
                , text = username
                }
            , Input.currentPassword submitOnEnter
                { label = Input.labelAbove [] (Element.text "Mot de passe")
                , onChange = Login.PasswordChanged
                , placeholder = Nothing
                , text = password
                , show = False
                }
            , submitButton
            ]

        form =
            case errorMessage of
                Just message ->
                    header :: message :: fields

                Nothing ->
                    header :: fields
    in
    Element.map Core.LoginMsg <|
        Element.column [ Element.centerX, Element.padding 10, Element.spacing 10 ]
            form
