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
import File exposing (File)
import Preparation.Types as Preparation
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
    | Edition
    | Publication


type Msg
    = PreparationMsg Preparation.Msg
    | AcquisitionMsg Acquisition.Msg
    | EditionMsg
    | PublicationMsg
    | Record Api.CapsuleDetails Int
    | UploadSlideShowMsg UploadSlideShowMsg
    | ShowMenuToggleMsg


type UploadSlideShowMsg
    = UploadSlideShowSelectFileRequested
    | UploadSlideShowFileReady File
    | UploadSlideShowFormSubmitted
    | UploadSlideShowSuccess Api.CapsuleDetails


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
