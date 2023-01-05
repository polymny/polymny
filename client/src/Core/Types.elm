module Core.Types exposing (..)

import Acquisition.Types as Acquisition
import Admin.Types as Admin
import Browser
import Browser.Navigation
import Capsule exposing (Capsule)
import CapsuleSettings.Types as CapsuleSettings
import FileValue exposing (File)
import Lang exposing (Lang)
import NewCapsule.Types as NewCapsule
import Popup exposing (Popup)
import Preparation.Types as Preparation
import Production.Types as Production
import Publication.Types as Publication
import RemoteData exposing (WebData)
import Route exposing (Route)
import Settings.Types as Settings
import Time
import Url
import User exposing (User)
import Utils exposing (tern)


type alias Flags =
    { root : String
    , socketRoot : String
    , videoRoot : String
    , version : String
    , commit : Maybe String
    , home : Maybe String
    , registrationDisabled : Bool
    , requestLang : Maybe (Maybe Lang)
    , storageLang : Maybe (Maybe Lang)
    , zoomLevel : Int
    , acquisitionInverted : Bool
    , videoDeviceId : Maybe String
    , resolution : Maybe String
    , audioDeviceId : Maybe String
    , sortBy : ( User.SortBy, Bool )
    , promptSize : Int
    }


type alias Global =
    { zone : Time.Zone
    , key : Browser.Navigation.Key
    , devices : Maybe Acquisition.Devices
    , notificationPanelVisible : Bool
    , root : String
    , socketRoot : String
    , videoRoot : String
    , version : String
    , commit : Maybe String
    , home : Maybe String
    , registrationDisabled : Bool
    , lang : Lang
    , zoomLevel : Int
    , acquisitionInverted : Bool
    , videoDeviceId : Maybe String
    , resolution : Maybe String
    , audioDeviceId : Maybe String
    , sortBy : ( User.SortBy, Bool )
    , promptSize : Int
    }


flagsToGlobal : Browser.Navigation.Key -> Flags -> Global
flagsToGlobal key flags =
    let
        lang =
            case ( flags.storageLang, flags.requestLang ) of
                ( Just (Just l), _ ) ->
                    l

                ( _, Just (Just l) ) ->
                    l

                _ ->
                    Lang.default
    in
    { zone = Time.utc
    , key = key
    , devices = Nothing
    , notificationPanelVisible = False
    , root = flags.root
    , socketRoot = flags.socketRoot
    , videoRoot = flags.videoRoot
    , version = flags.version
    , commit = flags.commit
    , home = flags.home
    , registrationDisabled = flags.registrationDisabled
    , lang = lang
    , zoomLevel = flags.zoomLevel
    , acquisitionInverted = flags.acquisitionInverted
    , videoDeviceId = flags.videoDeviceId
    , resolution = flags.resolution
    , audioDeviceId = flags.audioDeviceId
    , sortBy = flags.sortBy
    , promptSize = flags.promptSize
    }


updateDevice : Acquisition.Device -> Global -> Global
updateDevice device global =
    { global
        | videoDeviceId = Maybe.map .deviceId device.video |> Maybe.withDefault "disabled" |> Just
        , resolution = Maybe.map Acquisition.format device.resolution
        , audioDeviceId = Maybe.map .deviceId device.audio
    }


type Page
    = Home HomeModel
    | NewCapsule NewCapsule.Model
    | Preparation Preparation.Model
    | Acquisition Acquisition.Model
    | Production Production.Model
    | Publication Publication.Model
    | CapsuleSettings CapsuleSettings.Model
    | Settings Settings.Model
    | Admin Admin.Model
    | NotFound


type alias HomeModel =
    { renameCapsule : Maybe Capsule }


newHomeModel : HomeModel
newHomeModel =
    { renameCapsule = Nothing }


changeCapsule : Capsule -> Model -> Model
changeCapsule capsule model =
    changeCapsuleById (\_ -> capsule) capsule.id model


changeCapsuleById : (Capsule -> Capsule) -> String -> Model -> Model
changeCapsuleById updater id model =
    let
        newUser =
            User.changeCapsuleById updater id model.user

        newPage =
            case model.page of
                Preparation c ->
                    Preparation (tern (c.capsule.id == id) (Preparation.replaceCapsule c (updater c.capsule)) c)

                Acquisition c ->
                    Acquisition (tern (c.capsule.id == id) c { c | capsule = c.capsule })

                Production c ->
                    Production (tern (c.capsule.id == id) (Production.init (updater c.capsule) c.gos) c)

                Publication c ->
                    Publication (tern (c.capsule.id == id) { c | capsule = updater c.capsule } c)

                x ->
                    x
    in
    { model | user = newUser, page = newPage }


routeFromPage : Page -> Route
routeFromPage page =
    case page of
        Home _ ->
            Route.Home

        NewCapsule _ ->
            Route.Custom ""

        Preparation m ->
            Route.Preparation m.capsule.id Nothing

        Acquisition m ->
            Route.Acquisition m.capsule.id (m.gos + 1)

        Production m ->
            Route.Production m.capsule.id (m.gos + 1)

        Publication m ->
            Route.Publication m.capsule.id

        CapsuleSettings m ->
            Route.CapsuleSettings m.capsule.id

        Settings _ ->
            Route.Settings

        Admin admin ->
            case admin.page of
                Admin.Dashboard ->
                    Route.Admin Route.Dashboard

                Admin.UsersPage pagination ->
                    Route.Admin (Route.Users pagination)

                Admin.UserPage user ->
                    Route.Admin (Route.User user.id)

                Admin.CapsulesPage pagination ->
                    Route.Admin (Route.Capsules pagination)

        NotFound ->
            Route.NotFound


type alias Model =
    { user : User
    , global : Global
    , page : Page
    , popup : Maybe (Popup Msg)
    }


onUrlRequest : Browser.UrlRequest -> Msg
onUrlRequest url =
    case url of
        Browser.Internal u ->
            InternalUrl u

        Browser.External u ->
            ExternalUrl u


type Msg
    = Noop
    | LogoutClicked
    | ToggleFold String
    | RenameCapsule (Maybe Capsule)
    | ValidateRenameCapsule Capsule
    | SlideUploadRequested (Maybe String)
    | SlideUploaded (Maybe String) File
    | SlideUploadResponded (WebData Capsule)
    | NewCapsuleMsg NewCapsule.Msg
    | PreparationMsg Preparation.Msg
    | AcquisitionMsg Acquisition.Msg
    | ProductionMsg Production.Msg
    | PublicationMsg Publication.Msg
    | CapsuleSettingsMsg CapsuleSettings.Msg
    | SettingsMsg Settings.Msg
    | AdminMsg Admin.Msg
    | Popup (Popup Msg)
    | Cancel
    | RequestDeleteCapsule String
    | DeleteCapsule String
    | RequestDeleteProject String
    | DeleteProject String
    | TimeZoneChanged Time.Zone
    | OnUrlChange Url.Url
    | InternalUrl Url.Url
    | ExternalUrl String
    | LangChanged Lang
    | ZoomIn
    | ZoomOut
    | Copy String
    | ToggleNotificationPanel
    | MarkNotificationAsRead User.Notification
    | DeleteNotification User.Notification
    | NotificationReceived User.Notification
    | VideoUploadProgress String Float
    | VideoUploadFinished String
    | ProductionProgress String Float
    | ProductionFinished String
    | PublicationFinished String
    | ExportCapsule Capsule
    | CapsuleChanged Capsule
    | ExtraCapsuleReceived Route Capsule
    | AdminDashboard String
    | AdminUsers (List Admin.User) Int
    | AdminUser Admin.User
    | AdminCapsules (List Capsule) Int
    | Update Model (Cmd Msg)
