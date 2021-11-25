module Admin.Updates exposing (..)

import Admin.Types as Admin
import Api
import Capsule exposing (Capsule)
import Core.Types as Core
import Http
import Lang
import Popup
import Status
import User


update : Admin.Msg -> Core.Model -> ( Core.Model, Cmd Core.Msg )
update msg model =
    case model.page of
        Core.Admin m ->
            case msg of
                Admin.ToggleFold project ->
                    case m.page of
                        Admin.UserPage u ->
                            let
                                replaceProject : User.Project -> User.Project
                                replaceProject p =
                                    if p.name == project then
                                        { p | folded = not p.folded }

                                    else
                                        p

                                innerU =
                                    u.inner

                                newInnerUser =
                                    { innerU | projects = List.map replaceProject innerU.projects }

                                newPage =
                                    Core.Admin { m | page = Admin.UserPage { u | inner = newInnerUser } }
                            in
                            ( { model | page = newPage }, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Admin.UsernameSearchChanged s ->
                    let
                        newValue =
                            if s == "" then
                                Nothing

                            else
                                Just s
                    in
                    ( mkModel model (Core.Admin { m | usernameSearch = newValue })
                    , Cmd.none
                    )

                Admin.EmailSearchChanged s ->
                    let
                        newValue =
                            if s == "" then
                                Nothing

                            else
                                Just s
                    in
                    ( mkModel model (Core.Admin { m | emailSearch = newValue })
                    , Cmd.none
                    )

                Admin.UserSearchSubmitted ->
                    let
                        resultToMsg : Result Http.Error (List Admin.User) -> Core.Msg
                        resultToMsg result =
                            (case result of
                                Ok users ->
                                    Admin.UserSearchSuccess users

                                Err _ ->
                                    Admin.UserSearchFailed
                            )
                                |> Core.AdminMsg
                    in
                    ( mkModel model (Core.Admin { m | usernameSearchStatus = Status.Sent })
                    , Api.adminSearchUsers resultToMsg m
                    )

                Admin.UserSearchSuccess users ->
                    ( mkModel model (Core.Admin { m | usernameSearchStatus = Status.Success, users = users }), Cmd.none )

                Admin.UserSearchFailed ->
                    ( mkModel model (Core.Admin { m | usernameSearchStatus = Status.Error }), Cmd.none )

                Admin.CapsuleSearchChanged s ->
                    ( mkModel model (Core.Admin { m | capsuleSearch = Just s })
                    , Cmd.none
                    )

                Admin.ProjectSearchChanged s ->
                    ( mkModel model (Core.Admin { m | projectSearch = Just s })
                    , Cmd.none
                    )

                Admin.CapsuleSearchSubmitted ->
                    let
                        resultToMsg : Result Http.Error (List Capsule) -> Core.Msg
                        resultToMsg result =
                            (case result of
                                Ok capsules ->
                                    Admin.CapsuleSearchSuccess capsules

                                Err _ ->
                                    Admin.CapsuleSearchFailed
                            )
                                |> Core.AdminMsg
                    in
                    ( mkModel model (Core.Admin { m | capsuleSearchStatus = Status.Sent })
                    , Api.adminSearchCapsules resultToMsg m
                    )

                Admin.CapsuleSearchSuccess capsules ->
                    ( mkModel model (Core.Admin { m | capsuleSearchStatus = Status.Success, capsules = capsules }), Cmd.none )

                Admin.CapsuleSearchFailed ->
                    ( mkModel model (Core.Admin { m | capsuleSearchStatus = Status.Error }), Cmd.none )

                Admin.InviteUsernameChanged s ->
                    ( mkModel model (Core.Admin { m | inviteUsername = s })
                    , Cmd.none
                    )

                Admin.InviteEmailChanged s ->
                    ( mkModel model (Core.Admin { m | inviteEmail = s })
                    , Cmd.none
                    )

                Admin.InviteUserConfirm ->
                    let
                        resultToMsg : Result Http.Error () -> Core.Msg
                        resultToMsg result =
                            (case result of
                                Ok _ ->
                                    Admin.InviteUserSuccess

                                Err _ ->
                                    Admin.InviteUserFailed
                            )
                                |> Core.AdminMsg
                    in
                    ( mkModel model (Core.Admin { m | inviteUserStatus = Status.Sent })
                    , Api.adminInvite resultToMsg m
                    )

                Admin.InviteUserSuccess ->
                    ( mkModel model (Core.Admin { m | inviteUserStatus = Status.Success }), Cmd.none )

                Admin.InviteUserFailed ->
                    ( mkModel model (Core.Admin { m | inviteUserStatus = Status.Error }), Cmd.none )

                Admin.RequestDeleteUser u ->
                    let
                        popup =
                            Popup.popup
                                (Lang.warning model.global.lang)
                                (Lang.deleteUserConfirm model.global.lang u.inner.username u.inner.email)
                                Core.Cancel
                                (Core.AdminMsg (Admin.DeleteUser u))
                    in
                    ( { model | popup = Just popup }, Cmd.none )

                Admin.DeleteUser u ->
                    ( mkModel { model | popup = Nothing } (Core.Admin m), Api.adminDeleteUser (\_ -> Core.Noop) u.id )

                Admin.ClearWebockets ->
                    ( model, Api.adminClearWebsockets )

        _ ->
            ( model, Cmd.none )


mkModel : Core.Model -> Core.Page -> Core.Model
mkModel input newPage =
    { input | page = newPage }
