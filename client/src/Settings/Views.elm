module Settings.Views exposing (..)

{-| This module contains the views for the settings page.
-}

import App.Types as App
import Config exposing (Config)
import Data.User as Data exposing (User)
import Element exposing (Element)
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import RemoteData
import Settings.Types as Settings
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Utils as Ui
import Utils


{-| The view function for the settings page.
-}
view : Config -> User -> Settings.Model -> ( Element App.Msg, Element App.Msg )
view config user model =
    let
        ( content, popup ) =
            case model of
                Settings.Info ->
                    info config user

                Settings.ChangeEmail s ->
                    changeEmail config user model s

                Settings.ChangePassword s ->
                    changePassword config user model s
    in
    ( Element.row [ Ui.wf, Ui.hf ]
        [ Element.el [ Ui.wfp 2 ] Element.none
        , Element.el [ Ui.wfp 1, Ui.hf ] <| tabs config user model
        , Element.row [ Ui.wfp 5, Ui.at, Ui.p 10 ] [ content, Element.el [ Ui.wf ] Element.none ]
        , Element.el [ Ui.wfp 2 ] Element.none
        ]
    , popup
    )


{-| The info view, that displays global information on the user.
-}
info : Config -> User -> ( Element App.Msg, Element App.Msg )
info confg user =
    ( Element.none, Element.none )


{-| The view that lets users change their email..
-}
changeEmail : Config -> User -> Settings.Model -> Settings.ChangeEmailModel -> ( Element App.Msg, Element App.Msg )
changeEmail config user model m =
    let
        -- Shortcut for lang
        lang =
            config.clientState.lang

        -- Field with the username
        username =
            Input.username
                [ Font.color Colors.greyFontDisabled
                , Element.htmlAttribute <| Html.Attributes.disabled True
                ]
                { label = Input.labelAbove titleAttr <| Element.text <| Strings.dataUserUsername lang
                , onChange = \_ -> App.Noop
                , placeholder = Nothing
                , text = user.username
                }

        -- Field with the email address
        email =
            Input.email
                [ Font.color Colors.greyFontDisabled
                , Element.htmlAttribute <| Html.Attributes.disabled True
                ]
                { label = Input.labelAbove titleAttr <| Element.text <| Strings.dataUserCurrentEmailAddress lang
                , onChange = \_ -> App.Noop
                , placeholder = Nothing
                , text = user.email
                }

        -- Helper to create the new email field
        ( newEmailValid, newEmailAttr, newEmailErrorMsg ) =
            if Utils.checkEmail m.newEmail then
                ( True, [ Ui.b 1, Border.color Colors.greyBorder ], Element.none )

            else
                ( False
                , [ Ui.b 1, Border.color Colors.red ]
                , Strings.loginIncorrectEmailAddress lang
                    ++ "."
                    |> Element.text
                    |> Element.el [ Font.color Colors.red ]
                )

        -- New email field
        newEmail =
            Input.email newEmailAttr
                { label = Input.labelAbove titleAttr <| Element.text <| Strings.dataUserNewEmailAddress lang
                , onChange = \x -> App.SettingsMsg <| Settings.ChangeEmailNewEmailChanged x
                , placeholder = Nothing
                , text = m.newEmail
                }

        -- Helper info to create the button to request the email address change
        ( newEmailButtonText, canSend ) =
            case m.data of
                RemoteData.Loading _ ->
                    ( Ui.spinningSpinner [] 20, False )

                RemoteData.Success _ ->
                    ( Element.text <| Strings.loginMailSent lang, False )

                _ ->
                    ( Element.text <| Strings.uiConfirm lang, True )

        -- Button to request the email address change
        newEmailButton =
            Utils.tern newEmailValid
                Ui.primaryGeneric
                Ui.secondaryGeneric
                [ Ui.wf ]
                { action = Utils.tern (newEmailValid && canSend) (Ui.Msg <| App.SettingsMsg <| Settings.ChangeEmailConfirm) Ui.None
                , label = newEmailButtonText
                }

        -- Content
        content =
            Element.column [ Ui.wf, Ui.s 30 ]
                [ username
                , email
                , Element.column [ Ui.wf, Ui.s 10 ]
                    [ newEmail
                    , newEmailErrorMsg
                    ]
                , newEmailButton
                ]
    in
    ( content, Element.none )


{-| View that lets the user change their password.
-}
changePassword : Config -> User -> Settings.Model -> Settings.ChangePasswordModel -> ( Element App.Msg, Element App.Msg )
changePassword config user model m =
    let
        lang =
            config.clientState.lang

        -- Current password field
        currentPassword =
            Input.currentPassword []
                { onChange = \x -> App.SettingsMsg <| Settings.ChangePasswordCurrentPasswordChanged x
                , label = Input.labelAbove titleAttr <| Element.text <| Strings.loginCurrentPassword lang
                , placeholder = Nothing
                , show = False
                , text = m.currentPassword
                }

        -- New password field
        newPassword =
            Input.newPassword passwordAttr
                { onChange = \x -> App.SettingsMsg <| Settings.ChangePasswordNewPasswordChanged x
                , label = Input.labelAbove titleAttr <| Element.text <| Strings.loginNewPassword lang
                , placeholder = Nothing
                , show = False
                , text = m.newPassword
                }

        length =
            String.length m.newPassword

        strength =
            Utils.passwordStrength m.newPassword

        ( passwordAttr, passwordError, passwordAccepted ) =
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

        -- Password strength element
        passwordStrengthElement =
            Utils.passwordStrengthElement m.newPassword

        ( newPasswordRepeatAttr, newPasswordRepeatError, newPasswordRepeatAccepted ) =
            if m.newPassword == m.newPasswordRepeat then
                ( [ Ui.b 1, Border.color Colors.greyBorder ], Element.none, True )

            else
                ( [ Ui.b 1, Border.color Colors.red ]
                , Strings.loginPasswordsDontMatch lang
                    |> Element.text
                    |> Element.el [ Font.color Colors.red ]
                , True
                )

        -- New password repeat
        newPasswordRepeat =
            Input.newPassword newPasswordRepeatAttr
                { onChange = \x -> App.SettingsMsg <| Settings.ChangePasswordNewPasswordRepeatChanged x
                , label = Input.labelAbove titleAttr <| Element.text <| Strings.loginRepeatPassword lang
                , placeholder = Nothing
                , show = False
                , text = m.newPasswordRepeat
                }

        -- Helper info to create the button to request the password change
        ( changePasswordButtonText, canSend ) =
            case m.data of
                RemoteData.Loading _ ->
                    ( Ui.spinningSpinner [] 20, False )

                RemoteData.Success _ ->
                    ( Element.text <| Strings.loginPasswordChanged lang, False )

                _ ->
                    ( Element.text <| Strings.uiConfirm lang, True )

        -- Button to request the password change
        changePasswordButton =
            Utils.tern (canSend && passwordAccepted && newPasswordRepeatAccepted)
                Ui.primaryGeneric
                Ui.secondaryGeneric
                [ Ui.wf ]
                { action =
                    Utils.tern
                        (canSend && passwordAccepted && newPasswordRepeatAccepted)
                        (Ui.Msg <| App.SettingsMsg <| Settings.ChangePasswordConfirm)
                        Ui.None
                , label = changePasswordButtonText
                }

        -- Content
        content =
            Element.column [ Ui.wf, Ui.s 30 ]
                [ currentPassword
                , Element.column [ Ui.wf, Ui.s 10 ]
                    [ newPassword
                    , passwordStrengthElement
                    , passwordError
                    ]
                , Element.column [ Ui.wf, Ui.s 10 ]
                    [ newPasswordRepeat
                    , newPasswordRepeatError
                    ]
                , changePasswordButton
                ]
    in
    ( content, Element.none )


{-| Column to navigate in tabs.
-}
tabs : Config -> User -> Settings.Model -> Element App.Msg
tabs config user model =
    let
        lang =
            config.clientState.lang

        link : String -> Settings.Model -> Element App.Msg
        link label tab =
            Ui.link []
                { action = Ui.Msg <| App.SettingsMsg <| Settings.TabChanged tab
                , label = label
                }
    in
    Element.el [ Ui.p 10, Ui.wf, Ui.hf ] <|
        Element.column [ Ui.wf, Ui.hf, Ui.s 10, Ui.br 1, Border.color Colors.greyBorder ]
            [ Element.el [ Font.bold, Font.size 23 ] <| Element.text <| Strings.navigationSettings lang
            , link (Strings.dataUserEmailAddress lang) Settings.initChangeEmail
            , link (Strings.dataUserPassword lang) Settings.initChangePassword
            ]


{-| Title attributes.
-}
titleAttr : List (Element.Attribute msg)
titleAttr =
    [ Font.size 20, Font.bold, Ui.pb 5 ]
