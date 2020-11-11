module SignUp.Views exposing (view)

import Core.Types as Core
import Element exposing (Element)
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import SignUp.Types as SignUp
import Status
import Ui.Colors as Colors
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
                { label = Input.labelAbove [] Element.none
                , onChange = SignUp.UsernameChanged
                , placeholder = Just (Input.placeholder [] <| Element.text "Nom d'utilisateur")
                , text = username
                }
            , Input.email submitOnEnter
                { label = Input.labelAbove [] Element.none
                , onChange = SignUp.EmailChanged
                , placeholder = Just (Input.placeholder [] <| Element.text "Email")
                , text = email
                }
            , Input.newPassword submitOnEnter
                { label = Input.labelAbove [] Element.none
                , onChange = SignUp.PasswordChanged
                , placeholder = Just (Input.placeholder [] <| Element.text "Mot de passe")
                , text = password
                , show = False
                }
            , Input.currentPassword submitOnEnter
                { label = Input.labelAbove [] Element.none
                , onChange = SignUp.PasswordConfirmationChanged
                , placeholder = Just (Input.placeholder [] <| Element.text "Confirmez votre mot de passe")
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
            [ Element.centerX
            , Element.padding 30
            , Element.spacing 10
            , Border.width 1
            , Border.color Colors.black
            , Border.rounded 10
            , Font.alignLeft
            ]
            form
