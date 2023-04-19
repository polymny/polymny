module Core.Updates exposing (..)

import Acquisition.Ports as Ports
import Acquisition.Updates as Acquisition
import Admin.Types as Admin
import Admin.Updates as Admin
import Api
import Browser.Navigation as Nav
import Capsule
import CapsuleSettings.Types as CapsuleSettings
import CapsuleSettings.Updates as CapsuleSettings
import Core.Ports as Ports
import Core.Types as Core
import Core.Utils as Core
import Lang
import NewCapsule.Types as NewCapsule
import NewCapsule.Updates as NewCapsule
import Popup
import Preparation.Types as Preparation
import Preparation.Updates as Preparation
import Production.Types as Production
import Production.Updates as Production
import Publication.Updates as Publication
import RemoteData
import Route
import Settings.Updates as Settings
import Url
import User


update : Core.Msg -> Maybe Core.Model -> ( Maybe Core.Model, Cmd Core.Msg )
update msg model =
    case model of
        Just m ->
            let
                ( newModel, newCommand ) =
                    updateModel msg m
            in
            ( Just newModel, newCommand )

        _ ->
            ( Nothing, Cmd.none )


updateModel : Core.Msg -> Core.Model -> ( Core.Model, Cmd Core.Msg )
updateModel msg model =
    let
        { user, global, page } =
            model

        unbindWebcam =
            case ( page, newModel.page ) of
                ( _, Core.Acquisition _ ) ->
                    Cmd.none

                ( Core.Acquisition _, _ ) ->
                    Ports.unbindWebcam ()

                _ ->
                    Cmd.none

        showWarning =
            case page of
                Core.Acquisition m ->
                    Core.routeFromPage page /= Core.routeFromPage newModel.page && not (List.filter (\x -> not x.old) m.records |> List.isEmpty) && m.uploading == Nothing

                _ ->
                    False

        showWarningCmd =
            case newModel.page of
                Core.Acquisition m ->
                    if not (List.filter (\x -> not x.old) m.records |> List.isEmpty) then
                        Ports.setOnBeforeUnloadValue True

                    else
                        Ports.setOnBeforeUnloadValue False

                _ ->
                    Ports.setOnBeforeUnloadValue False

        ( newModel, newCmd ) =
            case msg of
                Core.TimeZoneChanged newTimeZone ->
                    ( { model | global = { global | zone = newTimeZone } }, Cmd.none )

                Core.LogoutClicked ->
                    ( model, Api.logout (\_ -> Core.ExternalUrl (Maybe.withDefault "/" global.home)) )

                Core.ToggleFold project ->
                    let
                        replaceProject : User.Project -> User.Project
                        replaceProject p =
                            if p.name == project then
                                { p | folded = not p.folded }

                            else
                                p
                    in
                    ( { model | user = { user | projects = List.map replaceProject user.projects } }, Cmd.none )

                Core.RenameCapsule capsule ->
                    ( { model | page = Core.Home { renameCapsule = capsule } }, Cmd.none )

                Core.ValidateRenameCapsule capsule ->
                    let
                        changedModel =
                            Core.changeCapsule capsule model
                    in
                    ( { changedModel | page = Core.Home { renameCapsule = Nothing } }
                    , Api.updateCapsule Core.Noop capsule
                    )

                Core.SlideUploadRequested project ->
                    ( model
                    , Ports.select
                        ( project
                        , if User.isPremium user then
                            [ "application/pdf", "application/zip" ]

                          else
                            [ "application/pdf" ]
                        )
                    )

                -- Select.file [ "application/pdf", "application/zip" ] (Core.SlideUploaded project) )
                Core.SlideUploaded project file ->
                    case file.mime of
                        "application/pdf" ->
                            let
                                name =
                                    file.name
                                        |> String.split "."
                                        |> List.reverse
                                        |> List.drop 1
                                        |> List.reverse
                                        |> String.join "."

                                newCapsule =
                                    NewCapsule.init project name
                            in
                            ( { model | page = Core.NewCapsule newCapsule }
                            , Api.uploadSlideShow newCapsule.project file
                            )

                        "application/zip" ->
                            ( model
                            , if User.isPremium user then
                                Ports.importCapsule ( project, file.value )

                              else
                                Cmd.none
                            )

                        _ ->
                            ( model, Cmd.none )

                Core.SlideUploadResponded response ->
                    let
                        newPage =
                            case page of
                                Core.NewCapsule newCapsule ->
                                    Core.NewCapsule (NewCapsule.changeCapsule response newCapsule)

                                _ ->
                                    page

                        newUser =
                            case response of
                                RemoteData.Success c ->
                                    User.addCapsule c user

                                _ ->
                                    user
                    in
                    ( { model | user = newUser, page = newPage }
                    , Cmd.none
                    )

                Core.NewCapsuleMsg m ->
                    NewCapsule.update m model

                Core.PreparationMsg m ->
                    Preparation.update m model

                Core.AcquisitionMsg m ->
                    Acquisition.update m model

                Core.ProductionMsg m ->
                    Production.update m model

                Core.PublicationMsg m ->
                    Publication.update m model

                Core.CapsuleSettingsMsg m ->
                    CapsuleSettings.update m model

                Core.SettingsMsg m ->
                    Settings.update global m model

                Core.AdminMsg m ->
                    Admin.update m model

                Core.Popup newPopup ->
                    ( { model | popup = Just newPopup }, Cmd.none )

                Core.Cancel ->
                    ( { model | popup = Nothing }, Cmd.none )

                Core.RequestDeleteProject name ->
                    let
                        newPopup =
                            Popup.popup
                                (Lang.warning global.lang)
                                (Lang.deleteProjectConfirm global.lang)
                                Core.Cancel
                                (Core.DeleteProject name)
                    in
                    ( { model | popup = Just newPopup }, Cmd.none )

                Core.RequestDeleteCapsule id ->
                    let
                        newPopup =
                            Popup.popup
                                (Lang.warning global.lang)
                                (Lang.deleteCapsuleConfirm global.lang)
                                Core.Cancel
                                (Core.DeleteCapsule id)
                    in
                    ( { model | popup = Just newPopup }, Cmd.none )

                Core.DeleteCapsule id ->
                    ( { model | user = User.removeCapsule id user, popup = Nothing }
                    , Api.deleteCapsule (\_ -> Core.Noop) id
                    )

                Core.DeleteProject name ->
                    ( { model | user = User.removeProject name user, popup = Nothing }
                    , Api.deleteProject Core.Noop name
                    )

                Core.OnUrlChange url ->
                    let
                        ( p, cmd ) =
                            Core.pageFromRoute global user page (Route.fromUrl url) Nothing
                    in
                    if Core.routeFromPage model.page == Core.routeFromPage p then
                        ( { model | popup = Nothing }, cmd )

                    else
                        ( { model | page = p }, cmd )

                Core.InternalUrl url ->
                    if String.startsWith "/data/" url.path then
                        ( model, Nav.load (Url.toString url) )

                    else
                        let
                            ( path, otherCmd ) =
                                case url.fragment of
                                    Just fragment ->
                                        ( url.path ++ "#" ++ fragment, Ports.scrollIntoView fragment )

                                    _ ->
                                        ( url.path, Cmd.none )
                        in
                        ( model, Cmd.batch [ otherCmd, Nav.pushUrl global.key path ] )

                Core.ExternalUrl url ->
                    ( model, Nav.load url )

                Core.LangChanged newLang ->
                    ( { model | global = { global | lang = newLang } }
                    , Ports.setLanguage (Lang.toString newLang)
                    )

                Core.ZoomIn ->
                    let
                        newZoomLevel =
                            global.zoomLevel - 1 |> max 2
                    in
                    ( { model | global = { global | zoomLevel = newZoomLevel } }
                    , Ports.setZoomLevel newZoomLevel
                    )

                Core.ZoomOut ->
                    let
                        newZoomLevel =
                            global.zoomLevel + 1 |> min 5
                    in
                    ( { model | global = { global | zoomLevel = newZoomLevel } }
                    , Ports.setZoomLevel newZoomLevel
                    )

                Core.Copy s ->
                    ( model, Ports.copyString s )

                Core.ToggleNotificationPanel ->
                    ( { model | global = { global | notificationPanelVisible = not global.notificationPanelVisible } }
                    , Cmd.none
                    )

                Core.MarkNotificationAsRead notif ->
                    let
                        notifs =
                            user.notifications
                                |> List.map
                                    (\x ->
                                        if x.id == notif.id then
                                            { x | read = True }

                                        else
                                            x
                                    )
                    in
                    ( { model | user = { user | notifications = notifs } }
                    , Api.markNotificationAsRead Core.Noop notif
                    )

                Core.DeleteNotification notif ->
                    ( { model | user = { user | notifications = user.notifications |> List.filter (\x -> x.id /= notif.id) } }
                    , Api.deleteNotification Core.Noop notif
                    )

                Core.NotificationReceived notif ->
                    ( { model | user = { user | notifications = notif :: user.notifications } }
                    , Cmd.none
                    )

                Core.VideoUploadProgress id notif ->
                    let
                        newPage =
                            case model.page of
                                Core.Preparation p ->
                                    Core.Preparation { p | tracker = Just ( "", Preparation.Transcoding notif ) }

                                _ ->
                                    model.page

                        tmpModel =
                            Core.changeCapsuleById
                                (\x -> { x | videoUploaded = Capsule.Running (Just notif) })
                                id
                                model
                    in
                    ( { tmpModel | page = newPage }
                    , Cmd.none
                    )

                Core.VideoUploadFinished id ->
                    let
                        newPage =
                            case model.page of
                                Core.Preparation p ->
                                    Core.Preparation { p | tracker = Nothing }

                                _ ->
                                    model.page

                        tmpModel =
                            Core.changeCapsuleById
                                (\x -> { x | videoUploaded = Capsule.Done })
                                id
                                model
                    in
                    ( { tmpModel | page = newPage }
                    , Cmd.none
                    )

                Core.ProductionProgress id notif ->
                    ( Core.changeCapsuleById
                        (\x -> { x | produced = Capsule.Running (Just notif) })
                        id
                        model
                    , Cmd.none
                    )

                Core.ProductionFinished id ->
                    ( Core.changeCapsuleById (\x -> { x | produced = Capsule.Done }) id model, Cmd.none )

                Core.PublicationFinished id ->
                    ( Core.changeCapsuleById (\x -> { x | published = Capsule.Done }) id model, Cmd.none )

                Core.ExportCapsule capsule ->
                    ( model, Ports.exportCapsule (Capsule.encodeAll capsule) )

                Core.CapsuleChanged capsule ->
                    ( Core.changeCapsule capsule model, Cmd.none )

                Core.ExtraCapsuleReceived route capsule ->
                    ( { model | page = Tuple.first (Core.pageFromRoute global user page route (Just capsule)) }, Cmd.none )

                Core.AdminDashboard dashboard ->
                    let
                        adminModel =
                            Admin.initModel Admin.Dashboard
                    in
                    ( { model | page = Core.Admin { adminModel | stats = dashboard } }, Cmd.none )

                Core.AdminUsers users pagination ->
                    let
                        adminModel =
                            Admin.initModel <| Admin.UsersPage pagination
                    in
                    ( { model | page = Core.Admin { adminModel | users = users } }, Cmd.none )

                Core.AdminUser u ->
                    ( { model | page = Core.Admin <| Admin.initModel <| Admin.UserPage u }, Cmd.none )

                Core.AdminCapsules capsules pagination ->
                    let
                        adminModel =
                            Admin.initModel <| Admin.CapsulesPage pagination
                    in
                    ( { model | page = Core.Admin { adminModel | capsules = capsules } }, Cmd.none )

                Core.Noop ->
                    ( model, Cmd.none )

                Core.Update n c ->
                    ( n, c )
    in
    case ( showWarning, msg ) of
        ( _, Core.Update _ _ ) ->
            ( newModel, Cmd.batch [ newCmd, unbindWebcam, showWarningCmd ] )

        ( True, _ ) ->
            ( { model
                | popup =
                    Just
                        { title = Lang.warning global.lang
                        , message = Lang.recordsWillBeLost global.lang
                        , onCancel = Core.Update model (Cmd.batch [ Nav.back global.key 1, Ports.playWebcam () ])
                        , onConfirm = Core.Update newModel (Cmd.batch [ newCmd, unbindWebcam ])
                        }
              }
            , Cmd.none
            )

        _ ->
            ( newModel, Cmd.batch [ newCmd, unbindWebcam, showWarningCmd ] )
