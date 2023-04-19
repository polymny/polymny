module Settings.Updates exposing (..)

import Api
import Browser.Navigation as Nav
import Core.Types as Core
import Http
import Lang
import Popup
import Settings.Types as Settings
import Status


update : Core.Global -> Settings.Msg -> Core.Model -> ( Core.Model, Cmd Core.Msg )
update global msg model =
    case model.page of
        Core.Settings m ->
            let
                { newPassword, newEmail, delete } =
                    m

                ( newModel, cmd, popup ) =
                    case msg of
                        Settings.NewPasswordCurrentPasswordChanged s ->
                            ( { m | newPassword = { newPassword | currentPassword = s } }, Cmd.none, Nothing )

                        Settings.NewPasswordNewPasswordChanged s ->
                            ( { m | newPassword = { newPassword | newPassword = s } }, Cmd.none, Nothing )

                        Settings.NewPasswordNewPasswordConfirmChanged s ->
                            ( { m | newPassword = { newPassword | newPasswordConfirm = s } }, Cmd.none, Nothing )

                        Settings.NewPasswordConfirm ->
                            ( { m | newPassword = { newPassword | status = Status.Sent } }
                            , Api.changePassword resultToMsg m.newPassword
                            , Nothing
                            )

                        Settings.NewPasswordSuccess ->
                            ( { m | newPassword = { newPassword | status = Status.Success } }, Cmd.none, Nothing )

                        Settings.NewPasswordFailed ->
                            ( { m | newPassword = { newPassword | status = Status.Error } }, Cmd.none, Nothing )

                        Settings.NewEmailNewEmailChanged s ->
                            ( { m | newEmail = { newEmail | newEmail = s } }, Cmd.none, Nothing )

                        Settings.NewEmailConfirm ->
                            ( { m | newEmail = { newEmail | status = Status.Sent } }
                            , Api.changeEmail resultToMsg2 m.newEmail
                            , Nothing
                            )

                        Settings.NewEmailSuccess ->
                            ( { m | newEmail = { newEmail | status = Status.Success } }, Cmd.none, Nothing )

                        Settings.NewEmailFailed ->
                            ( { m | newEmail = { newEmail | status = Status.Error } }, Cmd.none, Nothing )

                        Settings.DeletePasswordChanged s ->
                            ( { m | delete = { delete | currentPassword = s } }, Cmd.none, Nothing )

                        Settings.DeleteRequested ->
                            ( m
                            , Cmd.none
                            , Just
                                (Popup.popup (Lang.warning global.lang)
                                    (Lang.deleteSelf global.lang)
                                    Core.Cancel
                                    (Core.SettingsMsg Settings.DeleteConfirm)
                                )
                            )

                        Settings.DeleteConfirm ->
                            ( { m | delete = { delete | status = Status.Sent } }
                            , Api.deleteUser resultToMsg3 m.delete.currentPassword
                            , Nothing
                            )

                        Settings.DeleteSuccess ->
                            ( m, Nav.load (Maybe.withDefault global.root global.home), Nothing )

                        Settings.DeleteFailed ->
                            ( { m | delete = { delete | status = Status.Error } }, Cmd.none, Nothing )
            in
            ( mkModel { model | popup = popup } (Core.Settings newModel), cmd )

        _ ->
            ( model, Cmd.none )


resultToMsg : Result Http.Error () -> Core.Msg
resultToMsg result =
    (case result of
        Ok _ ->
            Settings.NewPasswordSuccess

        Err _ ->
            Settings.NewPasswordFailed
    )
        |> Core.SettingsMsg


resultToMsg2 : Result Http.Error () -> Core.Msg
resultToMsg2 result =
    (case result of
        Ok _ ->
            Settings.NewEmailSuccess

        Err _ ->
            Settings.NewEmailFailed
    )
        |> Core.SettingsMsg


resultToMsg3 : Result Http.Error () -> Core.Msg
resultToMsg3 result =
    (case result of
        Ok _ ->
            Settings.DeleteSuccess

        _ ->
            Settings.DeleteFailed
    )
        |> Core.SettingsMsg


mkModel : Core.Model -> Core.Page -> Core.Model
mkModel input newPage =
    { input | page = newPage }
