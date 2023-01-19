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
                Unlogged.Register ->
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

        buttonMsg : Ui.Action Unlogged.Msg
        buttonMsg =
            case ( model.page, model.newPasswordRequest ) of
                ( Unlogged.ForgotPassword, RemoteData.Success _ ) ->
                    Ui.None

                _ ->
                    Ui.Msg Unlogged.ButtonClicked

        buttonText : Element msg
        buttonText =
            case ( model.page, ( model.loginRequest, model.newPasswordRequest, model.resetPasswordRequest ) ) of
                ( _, ( RemoteData.Loading _, _, _ ) ) ->
                    Ui.spinningSpinner [] 20

                ( _, ( _, RemoteData.Loading _, _ ) ) ->
                    Ui.spinningSpinner [] 20

                ( _, ( _, _, RemoteData.Loading _ ) ) ->
                    Ui.spinningSpinner [] 20

                ( Unlogged.Login, ( _, _, _ ) ) ->
                    Strings.loginLogin lang |> Element.text

                ( Unlogged.Register, ( _, _, _ ) ) ->
                    Strings.loginSignUp lang |> Element.text

                ( Unlogged.ForgotPassword, ( _, _, _ ) ) ->
                    Strings.loginRequestNewPassword lang |> Element.text

                ( Unlogged.ResetPassword _, ( _, _, _ ) ) ->
                    Strings.loginResetPassword lang |> Element.text

        passwordStrengthElement : Element msg
        passwordStrengthElement =
            let
                strength =
                    passwordStrength model.password

                color =
                    if strength < 6 then
                        Colors.red

                    else if strength < 5 then
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
            case ( model.page, ( model.loginRequest, model.newPasswordRequest, model.resetPasswordRequest ) ) of
                ( Unlogged.Login, ( RemoteData.Failure (Http.BadStatus 401), _, _ ) ) ->
                    Just <| Strings.loginWrongPassword lang ++ "."

                ( Unlogged.Login, ( RemoteData.Failure _, _, _ ) ) ->
                    Just <| Strings.loginUnknownError lang ++ "."

                ( Unlogged.ForgotPassword, ( _, RemoteData.Failure _, _ ) ) ->
                    Just <| Strings.loginUnknownError lang ++ "."

                ( Unlogged.ResetPassword _, ( _, _, RemoteData.Failure _ ) ) ->
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
            case ( model.page, model.newPasswordRequest ) of
                ( Unlogged.ForgotPassword, RemoteData.Success () ) ->
                    Just <| Strings.loginMailSent lang ++ "."

                _ ->
                    Nothing
    in
    Element.column [ Ui.p 10, Ui.s 10, Ui.wf ]
        [ layout [ Ui.s 10, Ui.cx, Ui.wf ]
            [ only [ Unlogged.Login, Unlogged.Register ] <|
                Input.username [ Ui.cx, Ui.wf ]
                    { label = Input.labelHidden <| Strings.dataUserUsername lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.dataUserUsername lang
                    , onChange = Unlogged.UsernameChanged
                    , text = model.username
                    }
            , only [ Unlogged.ForgotPassword, Unlogged.Register ] <|
                Input.email [ Ui.cx, Ui.wf ]
                    { label = Input.labelHidden <| Strings.dataUserEmailAddress lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.dataUserEmailAddress lang
                    , onChange = Unlogged.EmailChanged
                    , text = model.email
                    }
            , only [ Unlogged.Login, Unlogged.Register, Unlogged.ResetPassword "" ] <|
                password [ Ui.cx, Ui.wf ]
                    { label = Input.labelHidden <| Strings.dataUserPassword lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.dataUserPassword lang
                    , onChange = Unlogged.PasswordChanged
                    , text = model.password
                    , show = False
                    }
            , only [ Unlogged.Register, Unlogged.ResetPassword "" ] <|
                passwordStrengthElement
            , only [ Unlogged.Register, Unlogged.ResetPassword "" ] <|
                Input.newPassword [ Ui.cx, Ui.wf ]
                    { label = Input.labelHidden <| Strings.dataUserPassword lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.loginRepeatPassword lang
                    , onChange = Unlogged.RepeatPasswordChanged
                    , text = model.repeatPassword
                    , show = False
                    }
            , Ui.primaryGeneric [ Ui.cx, Ui.wf ]
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
                            Ui.Msg <| Unlogged.PageChanged <| Unlogged.Register
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
