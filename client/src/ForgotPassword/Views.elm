module ForgotPassword.Views exposing (view)

import Core.Types as Core
import Element exposing (Element)
import Element.Input as Input
import ForgotPassword.Types as ForgotPassword
import Status
import Ui.Ui as Ui


view : ForgotPassword.Model -> Element Core.Msg
view { email, status } =
    let
        submitOnEnter =
            case status of
                Status.Sent ->
                    []

                Status.Success () ->
                    []

                _ ->
                    [ Ui.onEnter ForgotPassword.Submitted ]

        submitButton =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "Demande de nouveau mot de passe en cours..."

                _ ->
                    Ui.primaryButton (Just ForgotPassword.Submitted) "Demander un nouveau mot de passe"

        errorMessage =
            case status of
                Status.Error () ->
                    Just (Ui.errorModal "Connection échouée")

                _ ->
                    Nothing

        header =
            Element.row [ Element.centerX ] [ Element.text "Login" ]

        fields =
            [ Input.email submitOnEnter
                { label = Input.labelAbove [] (Element.text "Email")
                , onChange = ForgotPassword.EmailChanged
                , placeholder = Nothing
                , text = email
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
    Element.map Core.ForgotPasswordMsg <|
        Element.column [ Element.centerX, Element.padding 10, Element.spacing 10 ]
            form
