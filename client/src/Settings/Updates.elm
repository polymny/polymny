module Settings.Updates exposing (..)

{-| This module contains the updates of the settings page.
-}

import Api.User as Api
import App.Types as App
import RemoteData
import Settings.Types as Settings


{-| Update function for the settings page.
-}
update : Settings.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case ( msg, model.page ) of
        ( Settings.TabChanged m, _ ) ->
            ( { model | page = App.Settings m }, Cmd.none )

        ( Settings.ChangeEmailNewEmailChanged newEmail, App.Settings (Settings.ChangeEmail s) ) ->
            ( { model | page = App.Settings <| Settings.ChangeEmail { s | newEmail = newEmail } }
            , Cmd.none
            )

        ( Settings.ChangeEmailConfirm, App.Settings (Settings.ChangeEmail s) ) ->
            ( { model | page = App.Settings <| Settings.ChangeEmail <| { s | data = RemoteData.Loading Nothing } }
            , Api.changeEmail s.newEmail (\x -> App.SettingsMsg <| Settings.ChangeEmailDataChanged x)
            )

        ( Settings.ChangeEmailDataChanged d, App.Settings (Settings.ChangeEmail s) ) ->
            ( { model | page = App.Settings <| Settings.ChangeEmail { s | data = d } }
            , Cmd.none
            )

        ( Settings.ChangePasswordCurrentPasswordChanged p, App.Settings (Settings.ChangePassword s) ) ->
            ( { model | page = App.Settings <| Settings.ChangePassword { s | currentPassword = p } }
            , Cmd.none
            )

        ( Settings.ChangePasswordNewPasswordChanged p, App.Settings (Settings.ChangePassword s) ) ->
            ( { model | page = App.Settings <| Settings.ChangePassword { s | newPassword = p } }
            , Cmd.none
            )

        ( Settings.ChangePasswordNewPasswordRepeatChanged p, App.Settings (Settings.ChangePassword s) ) ->
            ( { model | page = App.Settings <| Settings.ChangePassword { s | newPasswordRepeat = p } }
            , Cmd.none
            )

        ( Settings.ChangePasswordConfirm, App.Settings (Settings.ChangePassword s) ) ->
            ( { model | page = App.Settings <| Settings.ChangePassword <| { s | data = RemoteData.Loading Nothing } }
            , Api.changePassword model.user s.currentPassword s.newPassword (\x -> App.SettingsMsg <| Settings.ChangePasswordDataChanged x)
            )

        ( Settings.ChangePasswordDataChanged d, App.Settings (Settings.ChangePassword s) ) ->
            ( { model | page = App.Settings <| Settings.ChangePassword <| { s | data = d } }
            , Cmd.none
            )

        ( Settings.DeleteAccountPasswordChanged p, App.Settings (Settings.DeleteAccount s) ) ->
            ( { model | page = App.Settings <| Settings.DeleteAccount { s | password = p } }
            , Cmd.none
            )

        ( Settings.DeleteAccountConfirm, App.Settings (Settings.DeleteAccount s) ) ->
            ( { model | page = App.Settings <| Settings.DeleteAccount <| { s | showPopup = True } }
            , Cmd.none
            )

        ( Settings.DeleteAccountCancel, App.Settings (Settings.DeleteAccount s) ) ->
            ( { model | page = App.Settings <| Settings.DeleteAccount <| { s | showPopup = False } }
            , Cmd.none
            )

        ( Settings.DeleteAccountConfirmTwice, App.Settings (Settings.DeleteAccount s) ) ->
            ( { model | page = App.Settings <| Settings.DeleteAccount <| { s | data = RemoteData.Loading Nothing, showPopup = False } }
            , Api.deleteAccount s.password (\x -> App.SettingsMsg <| Settings.DeleteAccountDataChanged x)
            )

        ( Settings.DeleteAccountDataChanged d, App.Settings (Settings.DeleteAccount s) ) ->
            ( { model | page = App.Settings <| Settings.DeleteAccount <| { s | data = d } }
            , Cmd.none
            )

        _ ->
            ( model, Cmd.none )
