module CapsuleSettings.Updates exposing (..)

import Api
import CapsuleSettings.Types as CapsuleSettings
import Core.Types as Core
import Status exposing (Status)


update : CapsuleSettings.Msg -> Core.Model -> ( Core.Model, Cmd Core.Msg )
update msg model =
    case model.page of
        Core.CapsuleSettings m ->
            let
                ( newModel, cmd ) =
                    case msg of
                        CapsuleSettings.ChangeRole user role ->
                            ( m, Api.changeRole Core.Noop Core.Noop m.capsule user.username role )

                        CapsuleSettings.RemoveUser user ->
                            ( m, Api.deinvite Core.Noop Core.Noop m.capsule user.username )

                        CapsuleSettings.ShareUsernameChanged newUsername ->
                            ( { m | username = newUsername }, Cmd.none )

                        CapsuleSettings.ShareRoleChanged newRole ->
                            ( { m | role = newRole }, Cmd.none )

                        CapsuleSettings.ShareConfirm ->
                            let
                                ( success, error ) =
                                    ( Core.CapsuleSettingsMsg CapsuleSettings.ShareSuccess
                                    , Core.CapsuleSettingsMsg CapsuleSettings.ShareError
                                    )
                            in
                            ( m, Api.invite success error m.capsule m.username m.role )

                        CapsuleSettings.ShareSuccess ->
                            ( { m | status = Status.Success }, Cmd.none )

                        CapsuleSettings.ShareError ->
                            ( { m | status = Status.Error }, Cmd.none )
            in
            ( mkModel model newModel, cmd )

        _ ->
            ( model, Cmd.none )


mkModel : Core.Model -> CapsuleSettings.Model -> Core.Model
mkModel model settings =
    { model | page = Core.CapsuleSettings settings }
