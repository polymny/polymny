module ResetPassword.Views exposing (view)

import Core.Types as Core
import Element exposing (Element)
import Element.Input as Input
import ResetPassword.Types as ResetPassword
import Status
import Ui.Ui as Ui


view : ResetPassword.Model -> Element Core.Msg
view { password, passwordConfirmation, status } =
    let
        isPasswordValid =
            password == passwordConfirmation

        submitIfUsernameValid =
            if isPasswordValid then
                Just ResetPassword.Submitted

            else
                Nothing

        submitOnEnter =
            case ( status, isPasswordValid ) of
                ( Status.Sent, _ ) ->
                    []

                ( Status.Success (), _ ) ->
                    []

                ( _, False ) ->
                    []

                _ ->
                    [ Ui.onEnter ResetPassword.Submitted ]

        submitButton =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "Changement du mot de passe en cours ..."

                Status.Success () ->
                    Ui.primaryButtonDisabled "Changement du mot de passe terminé !"

                _ ->
                    Ui.primaryButton submitIfUsernameValid "Changer mon mot de passe"

        message =
            case ( status, isPasswordValid ) of
                ( Status.Success (), _ ) ->
                    Nothing

                ( Status.Error (), _ ) ->
                    Just (Ui.errorModal "Le changement de mot de pass a échoué")

                ( _, False ) ->
                    Just (Ui.errorModal "Les deux mots de passe ne correspondent pas")

                _ ->
                    Nothing

        header =
            Element.row [ Element.centerX ] [ Element.text "Choisissez votre nouveau mot de passe" ]

        fields =
            [ Input.newPassword submitOnEnter
                { label = Input.labelAbove [] (Element.text "Mot de passe")
                , onChange = ResetPassword.PasswordChanged
                , placeholder = Nothing
                , text = password
                , show = False
                }
            , Input.currentPassword submitOnEnter
                { label = Input.labelAbove [] (Element.text "Confirmez votre mot de passe")
                , onChange = ResetPassword.PasswordConfirmationChanged
                , placeholder = Nothing
                , text = passwordConfirmation
                , show = False
                }
            , submitButton
            ]

        form =
            case message of
                Just m ->
                    header :: fields ++ [ m ]

                Nothing ->
                    header :: fields
    in
    Element.map Core.ResetPasswordMsg <|
        Element.column
            [ Element.centerX, Element.padding 10, Element.spacing 10 ]
            form
