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
import Http
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

                Settings.DeleteAccount s ->
                    deleteAccount config user model s
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
info _ _ =
    ( Element.none, Element.none )


{-| The view that lets users change their email..
-}
changeEmail : Config -> User -> Settings.Model -> Settings.ChangeEmailModel -> ( Element App.Msg, Element App.Msg )
changeEmail config user _ m =
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
        ( newEmailButtonText, outcomeInfo, canSend ) =
            case m.data of
                RemoteData.Loading _ ->
                    ( Ui.spinningSpinner [] 20
                    , Element.none
                    , False
                    )

                RemoteData.Success _ ->
                    ( Element.text <| Strings.uiConfirm lang
                    , Strings.loginMailSent lang
                        ++ "."
                        |> Ui.paragraph []
                        |> Ui.successModal [ Ui.wf ]
                    , False
                    )

                RemoteData.Failure _ ->
                    ( Element.text <| Strings.uiConfirm lang
                    , Strings.loginUnknownError lang
                        ++ "."
                        |> Ui.paragraph []
                        |> Ui.errorModal [ Ui.wf ]
                    , True
                    )

                RemoteData.NotAsked ->
                    ( Element.text <| Strings.uiConfirm lang
                    , Element.none
                    , True
                    )

        -- Button to request the email address change
        newEmailButton =
            Utils.tern (newEmailValid && canSend)
                Ui.primary
                Ui.secondary
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
                , outcomeInfo
                ]
    in
    ( content, Element.none )


{-| View that lets the user change their password.
-}
changePassword : Config -> User -> Settings.Model -> Settings.ChangePasswordModel -> ( Element App.Msg, Element App.Msg )
changePassword config _ _ m =
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
        ( changePasswordButtonText, outcomeMessage, canSend ) =
            case m.data of
                RemoteData.Loading _ ->
                    ( Ui.spinningSpinner [] 20
                    , Element.none
                    , False
                    )

                RemoteData.Success _ ->
                    ( Element.text <| Strings.uiConfirm lang
                    , Strings.loginPasswordChanged lang
                        ++ "."
                        |> Ui.paragraph []
                        |> Ui.successModal [ Ui.wf ]
                    , False
                    )

                RemoteData.Failure (Http.BadStatus 401) ->
                    ( Element.text <| Strings.uiConfirm lang
                    , Strings.loginWrongPassword lang
                        ++ "."
                        |> Ui.paragraph []
                        |> Ui.errorModal [ Ui.wf ]
                    , True
                    )

                RemoteData.Failure _ ->
                    ( Element.text <| Strings.uiConfirm lang
                    , Strings.loginUnknownError lang
                        ++ "."
                        |> Ui.paragraph []
                        |> Ui.errorModal [ Ui.wf ]
                    , True
                    )

                RemoteData.NotAsked ->
                    ( Element.text <| Strings.uiConfirm lang
                    , Element.none
                    , True
                    )

        -- Button to request the password change
        changePasswordButton =
            Utils.tern (canSend && passwordAccepted && newPasswordRepeatAccepted)
                Ui.primary
                Ui.secondary
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
                , outcomeMessage
                ]
    in
    ( content, Element.none )


{-| View that lets the user delete their account.
-}
deleteAccount : Config -> User -> Settings.Model -> Settings.DeleteAccountModel -> ( Element App.Msg, Element App.Msg )
deleteAccount config _ _ m =
    let
        lang =
            config.clientState.lang

        -- Current password field
        currentPassword =
            Input.currentPassword []
                { onChange = \x -> App.SettingsMsg <| Settings.DeleteAccountPasswordChanged x
                , label = Input.labelAbove titleAttr <| Element.text <| Strings.dataUserPassword lang
                , placeholder = Nothing
                , show = False
                , text = m.password
                }

        -- Helper info to create the button to request the account deletion
        ( deleteAccountButtonText, outcomeMessage, canSend ) =
            case m.data of
                RemoteData.Loading _ ->
                    ( Ui.spinningSpinner [] 20
                    , Element.none
                    , False
                    )

                RemoteData.Success _ ->
                    ( Element.text <| Strings.loginDeleteAccount lang
                    , Strings.loginPasswordChanged lang
                        ++ "."
                        |> Ui.paragraph []
                        |> Ui.successModal [ Ui.wf ]
                    , False
                    )

                RemoteData.Failure (Http.BadStatus 401) ->
                    ( Element.text <| Strings.loginDeleteAccount lang
                    , Strings.loginWrongPassword lang
                        ++ "."
                        |> Ui.paragraph []
                        |> Ui.errorModal [ Ui.wf ]
                    , True
                    )

                RemoteData.Failure _ ->
                    ( Element.text <| Strings.loginDeleteAccount lang
                    , Strings.loginUnknownError lang
                        ++ "."
                        |> Ui.paragraph []
                        |> Ui.errorModal [ Ui.wf ]
                    , True
                    )

                RemoteData.NotAsked ->
                    ( Element.text <| Strings.loginDeleteAccount lang
                    , Element.none
                    , True
                    )

        -- Button to request the password change
        deleteAccountButton =
            Utils.tern canSend
                Ui.primary
                Ui.secondary
                [ Ui.wf ]
                { action =
                    Utils.tern
                        canSend
                        (Ui.Msg <| App.SettingsMsg <| Settings.DeleteAccountConfirm)
                        Ui.None
                , label = deleteAccountButtonText
                }

        -- Account deletion confirm popup
        popup =
            if m.showPopup then
                Ui.popup 1 (Strings.uiWarning lang) <|
                    Element.column [ Ui.wf, Ui.hf ]
                        [ Ui.paragraph [ Ui.cy ] <| Strings.loginConfirmDeleteAccount lang ++ "."
                        , Element.row [ Ui.s 10, Ui.ab, Ui.ar ]
                            [ Ui.secondary [] { label = Element.text <| Strings.uiCancel lang, action = Ui.Msg <| App.SettingsMsg <| Settings.DeleteAccountCancel }
                            , Ui.primary [] { label = Element.text <| Strings.uiConfirm lang, action = Ui.Msg <| App.SettingsMsg <| Settings.DeleteAccountConfirmTwice }
                            ]
                        ]

            else
                Element.none

        -- Content
        content =
            Element.column [ Ui.wf, Ui.s 30 ]
                [ currentPassword
                , deleteAccountButton
                , outcomeMessage
                ]
    in
    ( content, popup )


{-| Column to navigate in tabs.
-}
tabs : Config -> User -> Settings.Model -> Element App.Msg
tabs config _ _ =
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
            , link (Strings.loginDeleteAccount lang) Settings.initDeleteAccount
            ]


{-| Title attributes.
-}
titleAttr : List (Element.Attribute msg)
titleAttr =
    [ Font.size 20, Font.bold, Ui.pb 5 ]
