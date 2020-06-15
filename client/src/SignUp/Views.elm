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
view { username, password, email, status } =
    let
        isUsernameValid =
            List.all isAllowedChar (String.toList username) && String.length username > 3

        submitIfUsernameValid =
            if isUsernameValid then
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
                    Ui.primaryButtonDisabled "Submitting ..."

                Status.Success () ->
                    Ui.primaryButtonDisabled "Submitted!"

                _ ->
                    Ui.primaryButton submitIfUsernameValid "Submit"

        message =
            case ( status, isUsernameValid ) of
                ( Status.Success (), _ ) ->
                    Just (Ui.successModal "An email has been sent to your address!")

                ( Status.Error (), _ ) ->
                    Just (Ui.errorModal "Sign up failed")

                ( _, False ) ->
                    Just (Ui.errorModal "Your username must contain only letters, numbers, ., - and _")

                _ ->
                    Nothing

        header =
            Element.row [ Element.centerX ] [ Element.text "Sign up" ]

        fields =
            [ Input.username submitOnEnter
                { label = Input.labelAbove [] (Element.text "Username")
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
            , Input.currentPassword submitOnEnter
                { label = Input.labelAbove [] (Element.text "Password")
                , onChange = SignUp.PasswordChanged
                , placeholder = Nothing
                , text = password
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
            [ Element.centerX, Element.padding 10, Element.spacing 10 ]
            form
