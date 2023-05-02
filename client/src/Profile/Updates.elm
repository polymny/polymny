module Profile.Updates exposing (..)

{-| This module contains the updates of the profile page.
-}

import Api.User as Api
import App.Types as App
import Keyboard
import Profile.Types as Profile
import RemoteData


{-| Update function for the profile page.
-}
update : Profile.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case ( msg, model.page ) of
        ( Profile.TabChanged m, _ ) ->
            ( { model | page = App.Profile m }, Cmd.none )

        ( Profile.ChangeEmailNewEmailChanged newEmail, App.Profile (Profile.ChangeEmail s) ) ->
            ( { model | page = App.Profile <| Profile.ChangeEmail { s | newEmail = newEmail } }
            , Cmd.none
            )

        ( Profile.ChangeEmailConfirm, App.Profile (Profile.ChangeEmail s) ) ->
            ( { model | page = App.Profile <| Profile.ChangeEmail <| { s | data = RemoteData.Loading Nothing } }
            , Api.changeEmail s.newEmail (\x -> App.ProfileMsg <| Profile.ChangeEmailDataChanged x)
            )

        ( Profile.ChangeEmailDataChanged d, App.Profile (Profile.ChangeEmail s) ) ->
            ( { model | page = App.Profile <| Profile.ChangeEmail { s | data = d } }
            , Cmd.none
            )

        ( Profile.ChangePasswordCurrentPasswordChanged p, App.Profile (Profile.ChangePassword s) ) ->
            ( { model | page = App.Profile <| Profile.ChangePassword { s | currentPassword = p } }
            , Cmd.none
            )

        ( Profile.ChangePasswordNewPasswordChanged p, App.Profile (Profile.ChangePassword s) ) ->
            ( { model | page = App.Profile <| Profile.ChangePassword { s | newPassword = p } }
            , Cmd.none
            )

        ( Profile.ChangePasswordNewPasswordRepeatChanged p, App.Profile (Profile.ChangePassword s) ) ->
            ( { model | page = App.Profile <| Profile.ChangePassword { s | newPasswordRepeat = p } }
            , Cmd.none
            )

        ( Profile.ChangePasswordConfirm, App.Profile (Profile.ChangePassword s) ) ->
            ( { model | page = App.Profile <| Profile.ChangePassword <| { s | data = RemoteData.Loading Nothing } }
            , Api.changePassword model.user s.currentPassword s.newPassword (\x -> App.ProfileMsg <| Profile.ChangePasswordDataChanged x)
            )

        ( Profile.ChangePasswordDataChanged d, App.Profile (Profile.ChangePassword s) ) ->
            ( { model | page = App.Profile <| Profile.ChangePassword <| { s | data = d } }
            , Cmd.none
            )

        ( Profile.DeleteAccountPasswordChanged p, App.Profile (Profile.DeleteAccount s) ) ->
            ( { model | page = App.Profile <| Profile.DeleteAccount { s | password = p } }
            , Cmd.none
            )

        ( Profile.DeleteAccountConfirm, App.Profile (Profile.DeleteAccount s) ) ->
            ( { model | page = App.Profile <| Profile.DeleteAccount <| { s | showPopup = True } }
            , Cmd.none
            )

        ( Profile.DeleteAccountCancel, App.Profile (Profile.DeleteAccount s) ) ->
            ( { model | page = App.Profile <| Profile.DeleteAccount <| { s | showPopup = False } }
            , Cmd.none
            )

        ( Profile.DeleteAccountConfirmTwice, App.Profile (Profile.DeleteAccount s) ) ->
            ( { model | page = App.Profile <| Profile.DeleteAccount <| { s | data = RemoteData.Loading Nothing, showPopup = False } }
            , Api.deleteAccount s.password (\x -> App.ProfileMsg <| Profile.DeleteAccountDataChanged x)
            )

        ( Profile.DeleteAccountDataChanged d, App.Profile (Profile.DeleteAccount s) ) ->
            ( { model | page = App.Profile <| Profile.DeleteAccount <| { s | data = d } }
            , Cmd.none
            )

        ( Profile.EnterPressed, App.Profile (Profile.ChangeEmail _) ) ->
            update Profile.ChangeEmailConfirm model

        ( Profile.EnterPressed, App.Profile (Profile.ChangePassword _) ) ->
            update Profile.ChangePasswordConfirm model

        ( Profile.EnterPressed, App.Profile (Profile.DeleteAccount _) ) ->
            update Profile.DeleteAccountConfirm model

        _ ->
            ( model, Cmd.none )


{-| Keyboard shortcuts of the profile page.
-}
shortcuts : Keyboard.RawKey -> App.Msg
shortcuts msg =
    case Keyboard.rawValue msg of
        "Enter" ->
            App.ProfileMsg Profile.EnterPressed

        _ ->
            App.Noop


{-| Subscriptions of the page.
-}
subs : Sub App.Msg
subs =
    Keyboard.ups shortcuts
