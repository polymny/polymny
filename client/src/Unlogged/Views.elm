module Unlogged.Views exposing (..)

{-| This module contains the view for the unlogged part of the app.
-}

import Element exposing (Element)
import Element.Input as Input
import Lang exposing (Lang)
import Strings
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

        buttonText : Lang -> String
        buttonText =
            case model.page of
                Unlogged.Login ->
                    Strings.loginLogin

                Unlogged.Register ->
                    Strings.loginSignUp

                Unlogged.ForgotPassword ->
                    Strings.loginRequestNewPassword
    in
    Element.column [ Ui.p 10, Ui.s 10, Ui.cx ]
        [ layout [ Ui.s 10, Ui.cx ]
            [ only2 Unlogged.Login Unlogged.Register <|
                Input.username [ Ui.cx ]
                    { label = Input.labelHidden <| Strings.dataUserUsername lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.dataUserUsername lang
                    , onChange = Unlogged.UsernameChanged
                    , text = model.username
                    }
            , only2 Unlogged.ForgotPassword Unlogged.Register <|
                Input.email [ Ui.cx ]
                    { label = Input.labelHidden <| Strings.dataUserEmailAddress lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.dataUserEmailAddress lang
                    , onChange = Unlogged.EmailChanged
                    , text = model.password
                    }
            , only2 Unlogged.Login Unlogged.Register <|
                password [ Ui.cx ]
                    { label = Input.labelHidden <| Strings.dataUserPassword lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.dataUserPassword lang
                    , onChange = Unlogged.PasswordChanged
                    , text = model.password
                    , show = False
                    }
            , only Unlogged.Register <|
                Input.newPassword [ Ui.cx ]
                    { label = Input.labelHidden <| Strings.dataUserPassword lang
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.loginRepeatPassword lang
                    , onChange = Unlogged.RepeatPasswordChanged
                    , text = model.password
                    , show = False
                    }
            , Ui.primary [ Ui.cx ]
                { action = Ui.None
                , label = buttonText lang
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
        ]
