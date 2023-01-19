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
            case ( model.page, model.loginRequest, model.newPasswordRequest ) of
                ( _, RemoteData.Loading _, _ ) ->
                    Ui.spinningSpinner [] 20

                ( _, _, RemoteData.Loading _ ) ->
                    Ui.spinningSpinner [] 20

                ( Unlogged.Login, _, _ ) ->
                    Strings.loginLogin lang |> Element.text

                ( Unlogged.Register, _, _ ) ->
                    Strings.loginSignUp lang |> Element.text

                ( Unlogged.ForgotPassword, _, _ ) ->
                    Strings.loginRequestNewPassword lang |> Element.text

                ( Unlogged.ResetPassword _, _, _ ) ->
                    Strings.loginResetPassword lang |> Element.text

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
            case ( model.page, model.loginRequest, model.newPasswordRequest ) of
                ( Unlogged.Login, RemoteData.Failure (Http.BadStatus 401), _ ) ->
                    Just <| Strings.loginWrongPassword lang ++ "."

                ( Unlogged.Login, RemoteData.Failure _, _ ) ->
                    Just <| Strings.loginUnknownError lang ++ "."

                ( Unlogged.ForgotPassword, _, RemoteData.Failure _ ) ->
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
                Input.newPassword [ Ui.cx, Ui.wf ]
                    { label = Input.labelHidden <| Strings.dataUserPassword lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.loginRepeatPassword lang
                    , onChange = Unlogged.RepeatPasswordChanged
                    , text = model.password
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
