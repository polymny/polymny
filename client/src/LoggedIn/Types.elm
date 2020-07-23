module LoggedIn.Types exposing
    ( Model
    , Msg(..)
    , Tab(..)
    , UploadForm
    , UploadSlideShowMsg(..)
    , init
    , initUploadForm
    , isAcquisition
    , isPreparation
    )

import Acquisition.Types as Acquisition
import Api
import Edition.Types as Edition
import File exposing (File)
import NewCapsule.Types as NewCapsule
import NewProject.Types as NewProject
import Preparation.Types as Preparation
import Settings.Types as Settings
import Status exposing (Status)


type alias Model =
    { session : Api.Session
    , tab : Tab
    }


type alias UploadForm =
    { status : Status () ()
    , file : Maybe File
    }


type Tab
    = Home UploadForm Bool
    | Preparation Preparation.Model
    | Acquisition Acquisition.Model
    | Edition Edition.Model
    | NewProject NewProject.Model
    | Project Api.Project (Maybe NewCapsule.Model)
    | Settings Settings.Model


type Msg
    = PreparationMsg Preparation.Msg
    | AcquisitionMsg Acquisition.Msg
    | EditionMsg Edition.Msg
    | PublicationMsg
    | Record Api.CapsuleDetails Int
    | UploadSlideShowMsg UploadSlideShowMsg
    | ShowMenuToggleMsg
    | NewProjectMsg NewProject.Msg
    | NewCapsuleMsg NewCapsule.Msg
    | CapsulesReceived Api.Project (List Api.Capsule)
    | CapsuleClicked Api.Capsule
    | ProjectClicked Api.Project
    | NewCapsuleClicked Api.Project
    | CapsuleReceived Api.CapsuleDetails
    | PreparationClicked Api.CapsuleDetails
    | AcquisitionClicked Api.CapsuleDetails
    | EditionClicked Api.CapsuleDetails Bool
    | SettingsClicked
    | SettingsMsg Settings.Msg


type UploadSlideShowMsg
    = UploadSlideShowSelectFileRequested
    | UploadSlideShowFileReady File
    | UploadSlideShowFormSubmitted
    | UploadSlideShowSuccess Api.CapsuleDetails
    | UploadSlideShowError


initUploadForm : UploadForm
initUploadForm =
    UploadForm Status.NotSent Nothing


init : Tab
init =
    Home initUploadForm False


isPreparation : Tab -> Bool
isPreparation tab =
    case tab of
        Preparation _ ->
            True

        _ ->
            False


isAcquisition : Tab -> Bool
isAcquisition tab =
    case tab of
        Acquisition _ ->
            True

        _ ->
            False
