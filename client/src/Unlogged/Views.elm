module Unlogged.Views exposing (..)

{-| This module contains the view for the unlogged part of the app.
-}

import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Http
import Lang
import RemoteData
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Utils as Ui
import Unlogged.Types as Unlogged


{-| The view of the form.
-}
view : Unlogged.Model -> Element Unlogged.Msg
view model =
    let
        lang =
            model.config.clientState.lang

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
                    Ui.spinningSpinner [] 20

                ( _, ( ( _, RemoteData.Loading _ ), ( _, _ ) ) ) ->
                    Ui.spinningSpinner [] 20

                ( _, ( ( _, _ ), ( RemoteData.Loading _, _ ) ) ) ->
                    Ui.spinningSpinner [] 20

                ( _, ( ( _, _ ), ( _, RemoteData.Loading _ ) ) ) ->
                    Ui.spinningSpinner [] 20

                ( Unlogged.Login, ( ( _, _ ), ( _, _ ) ) ) ->
                    Strings.loginLogin lang |> Element.text

                ( Unlogged.SignUp, ( ( _, _ ), ( _, _ ) ) ) ->
                    Strings.loginSignUp lang |> Element.text

                ( Unlogged.ForgotPassword, ( ( _, _ ), ( _, _ ) ) ) ->
                    Strings.loginRequestNewPassword lang |> Element.text

                ( Unlogged.ResetPassword _, ( ( _, _ ), ( _, _ ) ) ) ->
                    Strings.loginResetPassword lang |> Element.text

        strength =
            passwordStrength model.password

        length =
            String.length model.password

        passwordStrengthElement : Element msg
        passwordStrengthElement =
            let
                color =
                    if strength < 5 then
                        Colors.red

                    else if strength < 6 then
                        Colors.orange

                    else
                        Colors.green2

                firstAttr =
                    if strength == 7 then
                        Ui.r 10

                    else
                        Ui.rl 10

                secondAttr =
                    if strength == 0 then
                        Ui.r 10

                    else
                        Ui.rr 10
            in
            Element.row [ Ui.wf, Ui.hpx 10 ]
                [ Element.el [ firstAttr, Ui.hf, Background.color color, Ui.wfp strength ] Element.none
                , Element.el [ secondAttr, Ui.hf, Background.color Colors.greyBorder, Ui.wfp (7 - strength) ] Element.none
                ]

        formatError : Maybe String -> Element msg
        formatError string =
            case string of
                Just s ->
                    Element.el
                        [ Ui.wf
                        , Border.color Colors.red
                        , Ui.b 1
                        , Ui.r 5
                        , Ui.p 10
                        , Background.color Colors.redLight
                        , Font.color Colors.red
                        ]
                        (Element.text s)

                Nothing ->
                    Element.none

        errorMessage : Maybe String
        errorMessage =
            case ( model.page, ( ( model.loginRequest, model.newPasswordRequest ), ( model.resetPasswordRequest, model.signUpRequest ) ) ) of
                ( Unlogged.Login, ( ( RemoteData.Failure (Http.BadStatus 401), _ ), ( _, _ ) ) ) ->
                    Just <| Strings.loginWrongPassword lang ++ "."

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
                    Element.el
                        [ Ui.wf
                        , Border.color Colors.green2
                        , Ui.b 1
                        , Ui.r 5
                        , Ui.p 10
                        , Background.color Colors.greenLight
                        , Font.color Colors.green2
                        ]
                        (Element.text s)

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
            case model.page of
                Unlogged.SignUp ->
                    if length < 6 then
                        ( [ Ui.b 1, Border.color Colors.red ]
                        , Strings.loginPasswordTooShort lang
                            |> Element.text
                            |> Element.el [ Font.color Colors.red ]
                        , False
                        )

                    else if strength < 5 then
                        ( [ Ui.b 1, Border.color Colors.red ]
                        , Strings.loginInsufficientPasswordComplexity lang
                            |> Element.text
                            |> Element.el [ Font.color Colors.red ]
                        , False
                        )

                    else if strength < 6 then
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

                _ ->
                    ( [], Element.none, True )

        ( emailAttr, emailError, emailAccepted ) =
            if model.page == Unlogged.SignUp && not (checkEmail model.email) then
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
                    True

        -- (buttonMsg, mkButton) : (Ui.Action Unlogged.Msg, _)
        ( buttonMsg, mkButton ) =
            case ( model.page, model.newPasswordRequest, canSubmit ) of
                ( _, _, False ) ->
                    ( Ui.None, Ui.secondaryGeneric )

                ( Unlogged.ForgotPassword, RemoteData.Success _, _ ) ->
                    ( Ui.None, Ui.secondaryGeneric )

                _ ->
                    ( Ui.Msg Unlogged.ButtonClicked, Ui.primaryGeneric )
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
            , only [ Unlogged.SignUp, Unlogged.ResetPassword "" ] passwordStrengthElement
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
        ]


{-| Returns the strength of the password. A strength less than 5 is refused, and less than 6 gives a warning.
-}
passwordStrength : String -> Int
passwordStrength password =
    let
        specialChars =
            "[!@#$%^&*()_+-=[]{};':\"|,.<>\\/?]" |> String.toList

        passwordLength =
            String.length password

        lengthStrength =
            if passwordLength > 9 then
                3

            else if passwordLength > 7 then
                2

            else
                1

        boolToInt : Bool -> Int
        boolToInt bool =
            if bool then
                1

            else
                0

        hasLowerCase =
            boolToInt <| String.any Char.isLower password

        hasUpperCase =
            boolToInt <| String.any Char.isUpper password

        hasDigit =
            boolToInt <| String.any Char.isDigit password

        hasSpecial =
            boolToInt <| String.any (\x -> List.member x specialChars) password
    in
    if passwordLength == 0 then
        0

    else if passwordLength < 6 then
        1

    else
        lengthStrength + hasLowerCase + hasUpperCase + hasDigit + hasSpecial


{-| Checks whether an email address has a correct syntax.
-}
checkEmail : String -> Bool
checkEmail email =
    let
        splitAt =
            String.split "@" email

        host =
            List.drop 1 splitAt |> List.head |> Maybe.map (String.split "." >> List.length)
    in
    case ( List.length splitAt == 2, not (String.contains " " email), host ) of
        ( True, True, Just x ) ->
            x > 1

        _ ->
            False
