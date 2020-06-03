module Preparation.Types exposing
    ( Model(..)
    , Msg(..)
    , UploadForm
    , UploadSlideShowMsg(..)
    , initUploadForm
    )

import Api
import Capsule.Types as Capsule
import File exposing (File)
import NewCapsule.Types as NewCapsule
import NewProject.Types as NewProject
import Status exposing (Status)


type Model
    = Home UploadForm
    | NewProject NewProject.Model
    | Project Api.Project (Maybe NewCapsule.Model)
    | Capsule Capsule.Model


type Msg
    = PreparationClicked
    | ProjectClicked Api.Project
    | NewProjectMsg NewProject.Msg
    | NewCapsuleMsg NewCapsule.Msg
    | CapsulesReceived Api.Project (List Api.Capsule)
    | NewCapsuleClicked Api.Project
    | CapsuleClicked Api.Capsule
    | CapsuleReceived Api.CapsuleDetails
    | CapsuleMsg Capsule.Msg
    | UploadSlideShowMsg UploadSlideShowMsg


type UploadSlideShowMsg
    = UploadSlideShowSelectFileRequested
    | UploadSlideShowFileReady File
    | UploadSlideShowFormSubmitted


type alias UploadForm =
    { status : Status () ()
    , file : Maybe File
    }


initUploadForm : UploadForm
initUploadForm =
    UploadForm Status.NotSent Nothing
