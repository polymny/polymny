module Options.Types exposing (..)

{-| This module contains the types used in the Option module.
|
-}

import Acquisition.Types exposing (Msg(..))
import Data.Capsule as Data exposing (Capsule)
import File
import FileValue
import RemoteData exposing (WebData)
import Utils


{-| The model for the Option module.
-}
type alias Model a =
    { capsule : a
    , webcamPosition : ( Float, Float )
    , deleteTrack : Maybe Data.SoundTrack
    , capsuleUpdate : RemoteData.WebData Capsule
    , playPreview : Bool
    }


{-| Transforms the capsule id into a real capsule.
-}
withCapsule : Capsule -> Model String -> Model Capsule
withCapsule capsule model =
    { capsule = capsule
    , webcamPosition = model.webcamPosition
    , deleteTrack = model.deleteTrack
    , capsuleUpdate = model.capsuleUpdate
    , playPreview = model.playPreview
    }


{-| Message type of the app.
-}
type Msg
    = SetOpacity Float
    | SetWidth (Maybe Int) -- Nothing means fullscreen
    | SetAnchor Data.Anchor
    | ToggleVideo
    | TrackUploadRequested
    | TrackUploadReceived FileValue.File File.File
    | TrackUploadResponded (WebData Capsule)
    | DeleteTrack Utils.Confirmation (Maybe Data.SoundTrack)
    | TrackUpload (WebData Data.Capsule)
    | CapsuleUpdate Int (RemoteData.WebData Capsule)
    | SetVolume Float
    | Play
    | Stop
    | EscapePressed
    | EnterPressed


init : Capsule -> Model String
init capsule =
    { capsule = capsule.id
    , webcamPosition = ( 0, 0 )
    , deleteTrack = Nothing
    , capsuleUpdate = RemoteData.NotAsked
    , playPreview = False
    }
