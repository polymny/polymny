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

                _ ->
                    ( Input.currentPassword, Element.row )

        only : Unlogged.Page -> Element Unlogged.Msg -> Element Unlogged.Msg
        only page element =
            if model.page == page then
                element

            else
                Element.none

        only2 : Unlogged.Page -> Unlogged.Page -> Element Unlogged.Msg -> Element Unlogged.Msg
        only2 page1 page2 element =
            if model.page == page1 || model.page == page2 then
                element

            else
                Element.none

        buttonText : Element msg
        buttonText =
            case ( model.page, model.validate ) of
                ( _, RemoteData.Loading _ ) ->
                    Ui.spinningSpinner [] 20

                ( Unlogged.Login, _ ) ->
                    Strings.loginLogin lang |> Element.text

                ( Unlogged.Register, _ ) ->
                    Strings.loginSignUp lang |> Element.text

                ( Unlogged.ForgotPassword, _ ) ->
                    Strings.loginRequestNewPassword lang |> Element.text

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
            case model.validate of
                RemoteData.Failure (Http.BadStatus 401) ->
                    Just <| Strings.loginWrongPassword lang ++ "."

                RemoteData.Failure _ ->
                    Just <| Strings.loginUnknownError lang ++ "."

                _ ->
                    Nothing
    in
    Element.column [ Ui.p 10, Ui.s 10, Ui.wf ]
        [ layout [ Ui.s 10, Ui.cx, Ui.wf ]
            [ only2 Unlogged.Login Unlogged.Register <|
                Input.username [ Ui.cx, Ui.wf ]
                    { label = Input.labelHidden <| Strings.dataUserUsername lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.dataUserUsername lang
                    , onChange = Unlogged.UsernameChanged
                    , text = model.username
                    }
            , only2 Unlogged.ForgotPassword Unlogged.Register <|
                Input.email [ Ui.cx, Ui.wf ]
                    { label = Input.labelHidden <| Strings.dataUserEmailAddress lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.dataUserEmailAddress lang
                    , onChange = Unlogged.EmailChanged
                    , text = model.password
                    }
            , only2 Unlogged.Login Unlogged.Register <|
                password [ Ui.cx, Ui.wf ]
                    { label = Input.labelHidden <| Strings.dataUserPassword lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.dataUserPassword lang
                    , onChange = Unlogged.PasswordChanged
                    , text = model.password
                    , show = False
                    }
            , only Unlogged.Register <|
                Input.newPassword [ Ui.cx, Ui.wf ]
                    { label = Input.labelHidden <| Strings.dataUserPassword lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.loginRepeatPassword lang
                    , onChange = Unlogged.RepeatPasswordChanged
                    , text = model.password
                    , show = False
                    }
            , Ui.primaryGeneric [ Ui.cx, Ui.wf ]
                { action = Ui.Msg Unlogged.ButtonClicked
                , label = buttonText
                }
            ]
        , only Unlogged.Login <|
            Element.row [ Ui.s 10, Ui.cx ]
                [ Ui.link []
                    { action = Ui.Msg <| Unlogged.PageChanged <| Unlogged.ForgotPassword
                    , label = Lang.question Strings.loginForgottenPassword lang
                    }
                , Ui.link []
                    { action = Ui.Msg <| Unlogged.PageChanged <| Unlogged.Register
                    , label = Lang.question Strings.loginNotRegisteredYet lang
                    }
                ]
        , formatError errorMessage
        ]
