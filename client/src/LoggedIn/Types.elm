module LoggedIn.Types exposing
    ( Model
    , Msg(..)
    , Tab(..)
    , UploadForm
    , UploadSlideShowMsg(..)
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


type Tab
    = Home UploadForm
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


type UploadSlideShowMsg
    = UploadSlideShowSelectFileRequested
    | UploadSlideShowFileReady File
    | UploadSlideShowFormSubmitted
    | UploadSlideShowSuccess Api.CapsuleDetails


type alias UploadForm =
    { status : Status () ()
    , file : Maybe File
    }


initUploadForm : UploadForm
initUploadForm =
    UploadForm Status.NotSent Nothing


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
