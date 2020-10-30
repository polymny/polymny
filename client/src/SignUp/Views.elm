module SignUp.Views exposing (view)

import Core.Types as Core
import Element exposing (Element)
import Element.Input as Input
import SignUp.Types as SignUp
import Status
import Ui.Ui as Ui


isAllowedChar : Char -> Bool
isAllowedChar char =
    Char.isAlphaNum char || char == '_' || char == '-' || char == '.'


view : SignUp.Model -> Element Core.Msg
view { username, password, passwordConfirmation, email, status } =
    let
        isUsernameValid =
            List.all isAllowedChar (String.toList username) && String.length username > 3

        isPasswordValid =
            password == passwordConfirmation

        submitIfUsernameValid =
            if isUsernameValid && isPasswordValid then
                Just SignUp.Submitted

            else
                Nothing

        submitOnEnter =
            case ( status, isUsernameValid ) of
                ( Status.Sent, _ ) ->
                    []

                ( Status.Success (), _ ) ->
                    []

                ( _, False ) ->
                    []

                _ ->
                    [ Ui.onEnter SignUp.Submitted ]

        submitButton =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "Inscription en cours ..."

                Status.Success () ->
                    Ui.primaryButtonDisabled "Inscription terminée !"

                _ ->
                    Ui.primaryButton submitIfUsernameValid "S'inscrire"

        message =
            case ( status, isUsernameValid, isPasswordValid ) of
                ( Status.Success (), _, _ ) ->
                    Just (Ui.successModal "Un email vous a été envoyé !")

                ( Status.Error m, _, _ ) ->
                    Just (Ui.errorModal m)

                ( _, False, _ ) ->
                    Just (Ui.errorModal "Votre nom d'utilisateur ne doit contenir que des lettres, chiffres, points, tirets et traits et doit faire plus de 3 caractères")

                ( _, _, False ) ->
                    Just (Ui.errorModal "Les deux mots de passe ne correspondent pas")

                _ ->
                    Nothing

        header =
            Element.row [ Element.centerX ] [ Element.text "S'inscrire" ]

        fields =
            [ Input.username submitOnEnter
                { label = Input.labelAbove [] (Element.text "Nom d'utilisateur")
                , onChange = SignUp.UsernameChanged
                , placeholder = Nothing
                , text = username
                }
            , Input.email submitOnEnter
                { label = Input.labelAbove [] (Element.text "Email")
                , onChange = SignUp.EmailChanged
                , placeholder = Nothing
                , text = email
                }
            , Input.newPassword submitOnEnter
                { label = Input.labelAbove [] (Element.text "Mot de passe")
                , onChange = SignUp.PasswordChanged
                , placeholder = Nothing
                , text = password
                , show = False
                }
            , Input.currentPassword submitOnEnter
                { label = Input.labelAbove [] (Element.text "Confirmez votre mot de passe")
                , onChange = SignUp.PasswordConfirmationChanged
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
    Element.map Core.SignUpMsg <|
        Element.column
            [ Element.centerX, Element.padding 10, Element.spacing 10, Element.width Element.fill ]
            form
