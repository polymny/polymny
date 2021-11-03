module Settings.Views exposing (..)

import Core.Types as Core
import Element exposing (Element)
import Element.Input as Input
import Lang
import Settings.Types as Settings
import Status
import Ui.Utils as Ui
import User exposing (User)
import Utils exposing (checkEmail)


view : Core.Global -> User -> Settings.Model -> Element Core.Msg
view global user model =
    Element.row [ Ui.wf, Ui.hf, Element.padding 10 ]
        [ Element.el [ Ui.hf, Ui.wfp 1 ] Element.none
        , Element.column [ Element.spacing 20, Ui.hf, Ui.wfp 2 ]
            [ Input.text Ui.disabled
                { label = Input.labelAbove Ui.formTitle (Element.text (Lang.username global.lang))
                , onChange = \_ -> Core.Noop
                , placeholder = Nothing
                , text = user.username
                }
                |> Element.el []
            , Ui.horizontalDelimiter
            , changeEmailView global user model.newEmail
            , Ui.horizontalDelimiter
            , changePasswordView global model.newPassword
            , Ui.horizontalDelimiter
            , deleteView global model.delete
            ]
        , Element.el [ Ui.wf, Ui.wfp 1 ] Element.none
        ]


changePasswordView : Core.Global -> Settings.NewPassword -> Element Core.Msg
changePasswordView global model =
    let
        changePasswordFormCorrect =
            model.newPassword == model.newPasswordConfirm

        changePasswordConfirm =
            case ( model.status, changePasswordFormCorrect ) of
                ( Status.Sent, _ ) ->
                    Nothing

                ( _, False ) ->
                    Nothing

                _ ->
                    Just (Core.SettingsMsg Settings.NewPasswordConfirm)

        changePasswordModal =
            case ( model.status, changePasswordFormCorrect ) of
                ( Status.Error, _ ) ->
                    Lang.incorrectPassword global.lang |> Element.text |> Ui.p |> Ui.error

                ( Status.Success, _ ) ->
                    Lang.passwordChanged global.lang |> Element.text |> Ui.p |> Ui.success

                ( _, False ) ->
                    Lang.passwordsDontMatch global.lang |> Element.text |> Ui.p |> Ui.error

                _ ->
                    Element.none
    in
    Element.column [ Element.spacing 10 ]
        [ Element.el Ui.formTitle (Element.text (Lang.changePassword global.lang))
        , Input.currentPassword []
            { label = Input.labelAbove Ui.labelAttr (Element.text (Lang.currentPassword global.lang))
            , onChange = \x -> Core.SettingsMsg (Settings.NewPasswordCurrentPasswordChanged x)
            , placeholder = Just (Input.placeholder [] (Element.text (Lang.currentPassword global.lang)))
            , show = False
            , text = model.currentPassword
            }
        , Input.newPassword []
            { label = Input.labelAbove Ui.labelAttr (Element.text (Lang.newPassword global.lang))
            , onChange = \x -> Core.SettingsMsg (Settings.NewPasswordNewPasswordChanged x)
            , placeholder = Just (Input.placeholder [] (Element.text (Lang.newPassword global.lang)))
            , show = False
            , text = model.newPassword
            }
        , Input.newPassword []
            { label = Input.labelAbove Ui.labelAttr (Element.text (Lang.repeatPassword global.lang))
            , onChange = \x -> Core.SettingsMsg (Settings.NewPasswordNewPasswordConfirmChanged x)
            , placeholder = Just (Input.placeholder [] (Element.text (Lang.repeatPassword global.lang)))
            , show = False
            , text = model.newPasswordConfirm
            }
        , changePasswordModal
        , Element.el [ Element.centerX ]
            (if changePasswordFormCorrect then
                Ui.primaryButton
                    { onPress = changePasswordConfirm
                    , label =
                        case model.status of
                            Status.Sent ->
                                Ui.spinner

                            _ ->
                                Element.text (Lang.confirm global.lang)
                    }

             else
                Element.none
            )
        ]


changeEmailView : Core.Global -> User -> Settings.NewEmail -> Element Core.Msg
changeEmailView global user model =
    let
        changeEmailModal =
            case ( model.status, checkEmail model.newEmail || model.newEmail == "" ) of
                ( _, False ) ->
                    let
                        s =
                            Lang.invalidEmail global.lang

                        content =
                            (String.left 1 s |> String.toUpper) ++ String.dropLeft 1 s
                    in
                    content |> Element.text |> Ui.p |> Ui.error

                ( Status.Success, _ ) ->
                    Lang.mailSent global.lang |> Element.text |> Ui.p |> Ui.success

                _ ->
                    Element.none

        changeEmailMsg =
            case ( model.status, checkEmail model.newEmail ) of
                ( Status.Sent, _ ) ->
                    Nothing

                ( _, True ) ->
                    Just (Core.SettingsMsg Settings.NewEmailConfirm)

                _ ->
                    Nothing
    in
    Element.column [ Element.spacing 10 ]
        [ Element.el Ui.formTitle (Element.text (Lang.newEmail global.lang))
        , Input.email Ui.disabled
            { label = Input.labelAbove Ui.labelAttr (Element.text (Lang.currentEmail global.lang))
            , onChange = \_ -> Core.Noop
            , placeholder = Nothing
            , text = user.email
            }
        , Input.email []
            { label = Input.labelAbove Ui.labelAttr (Element.text (Lang.newEmail global.lang))
            , onChange = \x -> Core.SettingsMsg (Settings.NewEmailNewEmailChanged x)
            , placeholder = Just (Input.placeholder [] (Element.text (Lang.newEmail global.lang)))
            , text = model.newEmail
            }
        , changeEmailModal
        , Element.el [ Element.centerX ]
            (case ( model.status, changeEmailMsg ) of
                ( Status.Sent, _ ) ->
                    Ui.primaryButton { onPress = Nothing, label = Ui.spinner }

                ( _, Just _ ) ->
                    Ui.primaryButton { onPress = changeEmailMsg, label = Element.text (Lang.confirm global.lang) }

                _ ->
                    Element.none
            )
        ]


deleteView : Core.Global -> Settings.Delete -> Element Core.Msg
deleteView global model =
    let
        changePasswordConfirm =
            Just (Core.SettingsMsg Settings.DeleteRequested)

        changePasswordModal =
            case model.status of
                Status.Error ->
                    Lang.incorrectPassword global.lang |> Element.text |> Ui.p |> Ui.error

                Status.Success ->
                    Lang.passwordChanged global.lang |> Element.text |> Ui.p |> Ui.success

                _ ->
                    Element.none
    in
    Element.column [ Element.spacing 10 ]
        [ Element.el Ui.formTitle (Element.text (Lang.deleteAccount global.lang))
        , Input.currentPassword []
            { label = Input.labelAbove Ui.labelAttr (Element.text (Lang.currentPassword global.lang))
            , onChange = \x -> Core.SettingsMsg (Settings.DeletePasswordChanged x)
            , placeholder = Just (Input.placeholder [] (Element.text (Lang.currentPassword global.lang)))
            , show = False
            , text = model.currentPassword
            }
        , changePasswordModal
        , Element.el [ Element.centerX ]
            (Ui.dangerButton
                { onPress = changePasswordConfirm
                , label =
                    case model.status of
                        Status.Sent ->
                            Ui.spinner

                        _ ->
                            Element.text (Lang.deleteAccount global.lang)
                }
            )
        ]
