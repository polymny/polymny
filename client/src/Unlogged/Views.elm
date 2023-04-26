module Unlogged.Views exposing (..)

{-| This module contains the view for the unlogged part of the app.
-}

import Element exposing (Element)
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Html.Attributes
import Http
import Lang
import RemoteData
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Utils as Ui
import Unlogged.Types as Unlogged
import Utils


{-| The view of the form.
-}
view : Unlogged.Model -> Element Unlogged.Msg
view model =
    let
        lang =
            model.lang

        ( password, layout ) =
            case model.page of
                Unlogged.SignUp ->
                    ( Input.newPassword, Element.column )

                Unlogged.ResetPassword _ ->
                    ( Input.newPassword, Element.column )

                _ ->
                    ( Input.currentPassword, Element.row )

        only : List Unlogged.Page -> Element Unlogged.Msg -> Element Unlogged.Msg
        only pages element =
            if List.any (Unlogged.comparePage model.page) pages then
                element

            else
                Element.none

        buttonText : Element msg
        buttonText =
            case ( model.page, ( ( model.loginRequest, model.newPasswordRequest ), ( model.resetPasswordRequest, model.signUpRequest ) ) ) of
                ( _, ( ( RemoteData.Loading _, _ ), ( _, _ ) ) ) ->
                    Ui.spinningSpinner [ Ui.cx ] 20

                ( _, ( ( _, RemoteData.Loading _ ), ( _, _ ) ) ) ->
                    Ui.spinningSpinner [ Ui.cx ] 20

                ( _, ( ( _, _ ), ( RemoteData.Loading _, _ ) ) ) ->
                    Ui.spinningSpinner [ Ui.cx ] 20

                ( _, ( ( _, _ ), ( _, RemoteData.Loading _ ) ) ) ->
                    Ui.spinningSpinner [ Ui.cx ] 20

                ( Unlogged.Login, ( ( _, _ ), ( _, _ ) ) ) ->
                    Strings.loginLogin lang |> Element.text

                ( Unlogged.SignUp, ( ( _, _ ), ( _, _ ) ) ) ->
                    Strings.loginSignUp lang |> Element.text

                ( Unlogged.ForgotPassword, ( ( _, _ ), ( _, _ ) ) ) ->
                    Strings.loginRequestNewPassword lang |> Element.text

                ( Unlogged.ResetPassword _, ( ( _, _ ), ( _, _ ) ) ) ->
                    Strings.loginResetPassword lang |> Element.text

        strength =
            Utils.passwordStrength model.password

        length =
            String.length model.password

        formatError : Maybe String -> Element msg
        formatError string =
            case string of
                Just s ->
                    Ui.errorModal [ Ui.wf ] (Element.text s)

                Nothing ->
                    Element.none

        errorMessage : Maybe String
        errorMessage =
            case ( model.page, ( ( model.loginRequest, model.newPasswordRequest ), ( model.resetPasswordRequest, model.signUpRequest ) ) ) of
                ( Unlogged.Login, ( ( RemoteData.Failure (Http.BadStatus 401), _ ), ( _, _ ) ) ) ->
                    Just <| Strings.loginWrongUsernameOrPassword lang ++ "."

                ( Unlogged.Login, ( ( RemoteData.Failure _, _ ), ( _, _ ) ) ) ->
                    Just <| Strings.loginUnknownError lang ++ "."

                ( Unlogged.ForgotPassword, ( ( _, RemoteData.Failure _ ), ( _, _ ) ) ) ->
                    Just <| Strings.loginUnknownError lang ++ "."

                ( Unlogged.ResetPassword _, ( ( _, _ ), ( RemoteData.Failure _, _ ) ) ) ->
                    Just <| Strings.loginUnknownError lang ++ "."

                ( Unlogged.SignUp, ( ( _, _ ), ( _, RemoteData.Failure (Http.BadStatus 404) ) ) ) ->
                    Just <| Strings.loginUsernameOrEmailAlreadyExist lang ++ "."

                ( Unlogged.SignUp, ( ( _, _ ), ( _, RemoteData.Failure _ ) ) ) ->
                    Just <| Strings.loginUnknownError lang ++ "."

                _ ->
                    Nothing

        formatSuccess : Maybe String -> Element msg
        formatSuccess string =
            case string of
                Just s ->
                    Ui.successModal [ Ui.wf ] (Element.text s)

                _ ->
                    Element.none

        successMessage : Maybe String
        successMessage =
            case ( model.page, model.newPasswordRequest, model.signUpRequest ) of
                ( Unlogged.ForgotPassword, RemoteData.Success (), _ ) ->
                    Just <| Strings.loginMailSent lang ++ "."

                ( Unlogged.SignUp, _, RemoteData.Success () ) ->
                    Just <| Strings.loginMailSent lang ++ "."

                _ ->
                    Nothing

        ( passwordAttr, passwordError, passwordAccepted ) =
            if model.page == Unlogged.SignUp || Unlogged.comparePage model.page (Unlogged.ResetPassword "") then
                if length < 6 then
                    ( [ Ui.b 1, Border.color Colors.red ]
                    , Strings.loginPasswordTooShort lang
                        |> Element.text
                        |> Element.el [ Font.color Colors.red ]
                    , False
                    )

                else if strength < Utils.minPasswordStrength then
                    ( [ Ui.b 1, Border.color Colors.red ]
                    , Strings.loginInsufficientPasswordComplexity lang
                        |> Element.text
                        |> Element.el [ Font.color Colors.red ]
                    , False
                    )

                else if strength < Utils.minPasswordStrength + 1 then
                    ( []
                    , Strings.loginAcceptablePasswordComplexity lang
                        |> Element.text
                        |> Element.el [ Font.color Colors.orange ]
                    , True
                    )

                else
                    ( []
                    , Strings.loginStrongPasswordComplexity lang
                        |> Element.text
                        |> Element.el [ Font.color Colors.green2 ]
                    , True
                    )

            else
                ( [], Element.none, True )

        ( emailAttr, emailError, emailAccepted ) =
            if model.page == Unlogged.SignUp && not (Utils.checkEmail model.email) then
                ( [ Ui.b 1, Border.color Colors.red ]
                , Strings.loginIncorrectEmailAddress lang |> Element.text |> Element.el [ Font.color Colors.red ]
                , False
                )

            else
                ( [], Element.none, True )

        ( repeatAttr, repeatError, repeatAccepted ) =
            if (model.page == Unlogged.SignUp || Unlogged.comparePage model.page (Unlogged.ResetPassword "")) && model.password /= model.repeatPassword then
                ( [ Ui.b 1, Border.color Colors.red ]
                , Strings.loginPasswordsDontMatch lang
                    |> Element.text
                    |> Element.el [ Font.color Colors.red ]
                , False
                )

            else
                ( [], Element.none, True )

        ( acceptError, acceptAccepted ) =
            if model.page == Unlogged.SignUp && not model.acceptTermsOfService then
                ( Strings.loginMustAcceptTermsOfService lang
                    |> Element.text
                    |> Element.el [ Font.color Colors.red ]
                , False
                )

            else
                ( Element.none, True )

        canSubmit =
            case model.page of
                Unlogged.Login ->
                    True

                Unlogged.SignUp ->
                    passwordAccepted && emailAccepted && repeatAccepted && acceptAccepted

                Unlogged.ForgotPassword ->
                    True

                Unlogged.ResetPassword _ ->
                    passwordAccepted && repeatAccepted

        -- (buttonMsg, mkButton) : (Ui.Action Unlogged.Msg, _)
        ( buttonMsg, mkButton ) =
            case ( model.page, model.newPasswordRequest, canSubmit ) of
                ( _, _, False ) ->
                    ( Ui.None, Ui.secondary )

                ( Unlogged.ForgotPassword, RemoteData.Success _, _ ) ->
                    ( Ui.None, Ui.secondary )

                _ ->
                    ( Ui.Msg Unlogged.ButtonClicked, Ui.primary )
    in
    Element.column [ Ui.p 10, Ui.s 10, Ui.wf ]
        [ layout [ Ui.s 10, Ui.cx, Ui.wf ]
            [ only [ Unlogged.Login, Unlogged.SignUp ] <|
                Input.username [ Ui.cx, Ui.wf ]
                    { label = Input.labelHidden <| Strings.dataUserUsername lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.dataUserUsername lang
                    , onChange = Unlogged.UsernameChanged
                    , text = model.username
                    }
            , only [ Unlogged.ForgotPassword, Unlogged.SignUp ] <|
                Input.email (Ui.cx :: Ui.wf :: emailAttr)
                    { label = Input.labelHidden <| Strings.dataUserEmailAddress lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.dataUserEmailAddress lang
                    , onChange = Unlogged.EmailChanged
                    , text = model.email
                    }
            , only [ Unlogged.SignUp ] emailError
            , only [ Unlogged.Login, Unlogged.SignUp, Unlogged.ResetPassword "" ] <|
                password (Ui.cx :: Ui.wf :: passwordAttr)
                    { label = Input.labelHidden <| Strings.dataUserPassword lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.dataUserPassword lang
                    , onChange = Unlogged.PasswordChanged
                    , text = model.password
                    , show = False
                    }
            , only [ Unlogged.SignUp, Unlogged.ResetPassword "" ] <| Utils.passwordStrengthElement model.password
            , only [ Unlogged.SignUp, Unlogged.ResetPassword "" ] passwordError
            , only [ Unlogged.SignUp, Unlogged.ResetPassword "" ] <|
                Input.newPassword (Ui.cx :: Ui.wf :: repeatAttr)
                    { label = Input.labelHidden <| Strings.dataUserPassword lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.loginRepeatPassword lang
                    , onChange = Unlogged.RepeatPasswordChanged
                    , text = model.repeatPassword
                    , show = False
                    }
            , only [ Unlogged.SignUp, Unlogged.ResetPassword "" ] repeatError
            , only [ Unlogged.SignUp ] <|
                Input.checkbox []
                    { label =
                        Input.labelRight [ Ui.wf ] <|
                            Element.paragraph [ Ui.wf ]
                                [ Element.text <| Strings.loginAcceptTermsOfServiceBegining lang ++ " "
                                , Ui.link []
                                    { label = Strings.loginTermsOfService lang |> String.toLower
                                    , action = Ui.NewTab "https://polymny.studio/cgu-consommateurs/"
                                    }
                                ]
                    , icon = Input.defaultCheckbox
                    , onChange = Unlogged.AcceptTermsOfServiceChanged
                    , checked = model.acceptTermsOfService
                    }
            , only [ Unlogged.SignUp ] acceptError
            , only [ Unlogged.SignUp ] <|
                Input.checkbox []
                    { label = Input.labelRight [] <| Element.text <| Strings.loginSignUpForTheNewsletter lang
                    , icon = Input.defaultCheckbox
                    , onChange = Unlogged.SignUpForNewsletterChanged
                    , checked = model.signUpForNewsletter
                    }
            , mkButton [ Ui.cx, Ui.wf ]
                { action = buttonMsg
                , label = buttonText
                }
            ]
        , only [ Unlogged.Login ] <|
            Element.row [ Ui.s 10, Ui.cx ]
                [ Ui.link []
                    { action =
                        if model.loginRequest == RemoteData.Loading Nothing then
                            Ui.None

                        else
                            Ui.Msg <| Unlogged.PageChanged <| Unlogged.ForgotPassword
                    , label = Lang.question Strings.loginForgottenPassword lang
                    }
                , Ui.link []
                    { action =
                        if model.loginRequest == RemoteData.Loading Nothing then
                            Ui.None

                        else
                            Ui.Msg <| Unlogged.PageChanged <| Unlogged.SignUp
                    , label = Lang.question Strings.loginNotRegisteredYet lang
                    }
                ]
        , formatError errorMessage
        , formatSuccess successMessage
        , Element.html <|
            Html.form
                [ Html.Attributes.method "POST"
                , Html.Attributes.action (model.serverRoot ++ "/login")
                , Html.Attributes.style "display" "none"
                , Html.Attributes.id "loginform"
                ]
                [ Html.input [ Html.Attributes.type_ "text", Html.Attributes.name "username", Html.Attributes.value model.username ] []
                , Html.input [ Html.Attributes.type_ "text", Html.Attributes.name "password", Html.Attributes.value model.password ] []
                ]
        ]


{-| Sup.
-}
viewStandalone : Maybe Unlogged.Model -> Html Unlogged.Msg
viewStandalone model =
    case model of
        Just m ->
            Element.layout
                [ Ui.wf
                , Ui.hf
                , Font.size 18
                , Font.family
                    [ Font.typeface "Urbanist"
                    , Font.typeface "Ubuntu"
                    , Font.typeface "Cantarell"
                    ]
                , Font.color Colors.greyFont
                ]
                (view m)

        _ ->
            Element.layout [] (Element.text "oops")
