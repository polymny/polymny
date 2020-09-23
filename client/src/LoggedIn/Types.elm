module LoggedIn.Types exposing
    ( Model
    , Msg(..)
    , Rename(..)
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
import Dropdown
import Edition.Types as Edition
import File exposing (File)
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
    , projectName : String
    , capsuleName : String
    , capsule : Maybe Api.CapsuleDetails
    , slides : Maybe (List ( Int, Api.Slide ))
    , numberOfSlidesPerRow : Int
    , dropdown : Dropdown.State Api.Project
    , projectSelected : Maybe Api.Project
    , rename : Maybe Rename
    }


type Rename
    = RenameProject ( Int, String )
    | RenameCapsule ( Int, Int, String )


type Tab
    = Home UploadForm
    | Preparation Preparation.Model
    | Acquisition Acquisition.Model
    | Edition Edition.Model
    | Settings Settings.Model


type Msg
    = PreparationMsg Preparation.Msg
    | AcquisitionMsg Acquisition.Msg
    | EditionMsg Edition.Msg
    | PublicationMsg
    | Record Api.CapsuleDetails Int
    | UploadSlideShowMsg UploadSlideShowMsg
    | CapsulesReceived Api.Project (List Api.Capsule)
    | CapsuleClicked Api.Capsule
    | CapsuleReceived Api.CapsuleDetails
    | PreparationClicked Api.CapsuleDetails
    | AcquisitionClicked Api.CapsuleDetails
    | EditionClicked Api.CapsuleDetails Bool
    | SettingsClicked
    | SettingsMsg Settings.Msg
    | ToggleFoldedProject Int
    | DropdownMsg (Dropdown.Msg Api.Project)
    | OptionPicked (Maybe Api.Project)
    | GosClicked Int
    | CancelRename
    | RenameMsg Rename
    | ValidateRenameProject


type UploadSlideShowMsg
    = UploadSlideShowSelectFileRequested
    | UploadSlideShowFileReady File
    | UploadSlideShowFormSubmitted
    | UploadSlideShowSuccess Int Api.CapsuleDetails
    | UploadSlideShowError
    | UploadSlideShowChangeProjectName String
    | UploadSlideShowChangeCapsuleName String
    | UploadSlideShowGoToAcquisition
    | UploadSlideShowGoToPreparation
    | UploadSlideShowCancel
    | UploadSlideShowSlideClicked Int


initUploadForm : UploadForm
initUploadForm =
    UploadForm Status.NotSent Nothing "" "" Nothing Nothing 5 (Dropdown.init "") Nothing Nothing


init : Tab
init =
    Home initUploadForm


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
