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

        isEmailValid =
            case String.split "@" email of
                a :: b :: [] ->
                    if not (String.isEmpty a) then
                        case String.split "." b of
                            a2 :: b2 :: c2 ->
                                List.all (String.isEmpty >> not) (a2 :: b2 :: c2)

                            _ ->
                                False

                    else
                        False

                _ ->
                    False

        submitOnEnter =
            case ( status, canSend ) of
                ( Status.Sent, _ ) ->
                    []

                ( Status.Success (), _ ) ->
                    []

                ( _, False ) ->
                    []

                ( _, True ) ->
                    [ Ui.onEnter SignUp.Submitted ]

        submitButton =
            case ( status, canSend ) of
                ( Status.Sent, _ ) ->
                    Ui.primaryButtonDisabled "Inscription en cours ..."

                ( Status.Success (), _ ) ->
                    Ui.primaryButtonDisabled "Inscription terminée !"

                ( _, False ) ->
                    Element.none

                ( _, True ) ->
                    Ui.primaryButton submitIfUsernameValid "S'inscrire"

        ( message, canSend ) =
            case ( ( status, isUsernameValid ), ( isEmailValid, isPasswordValid ) ) of
                ( ( Status.Success (), _ ), ( _, _ ) ) ->
                    ( Just (Ui.successModal "Un email vous a été envoyé !"), False )

                ( ( Status.Error m, _ ), ( _, _ ) ) ->
                    ( Just (Ui.errorModal m), True )

                ( ( _, False ), ( _, _ ) ) ->
                    ( Just (Ui.errorModal "Votre nom d'utilisateur ne doit contenir que des lettres non accentuées, chiffres, points, tirets et traits et doit faire plus de 3 caractères"), False )

                ( ( _, _ ), ( False, _ ) ) ->
                    ( Just (Ui.errorModal "Votre adresse e-mail n'est pas correcte"), False )

                ( ( _, _ ), ( _, False ) ) ->
                    ( Just (Ui.errorModal "Les deux mots de passe ne correspondent pas"), False )

                _ ->
                    ( Nothing, True )

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
            , Element.width (Element.px 300)
            , Border.width 1
            , Border.color Colors.black
            , Border.rounded 10
            , Font.alignLeft
            ]
            form
