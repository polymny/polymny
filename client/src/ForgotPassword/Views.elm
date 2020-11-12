module ForgotPassword.Views exposing (view)

import Core.Types as Core
import Element exposing (Element)
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import ForgotPassword.Types as ForgotPassword
import Status
import Ui.Colors as Colors
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
                Status.Success () ->
                    Just (Ui.successModal "Un email vous a été envoyé !")

                Status.Error () ->
                    Just (Ui.errorModal "Connection échouée")

                _ ->
                    Nothing

        header =
            Element.row [ Element.centerX ] [ Element.text "Mot de passe oubilé ?" ]

        fields =
            [ Input.email submitOnEnter
                { label = Input.labelLeft [] Element.none
                , onChange = ForgotPassword.EmailChanged
                , placeholder = Just (Input.placeholder [] (Element.text "Email"))
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
        Element.column
            [ Element.centerX
            , Element.padding 30
            , Element.spacing 10
            , Element.width (Element.px 300)
            , Border.width 1
            , Border.color Colors.black
            , Border.rounded 10
            , Font.alignLeft
            ]
            form
