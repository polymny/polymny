module Options.Types exposing (..)

{-| This module contains the types used in the Option module.
|
-}

import Data.Capsule as Data exposing (Capsule, SoundTrack)
import File exposing (File)
import FileValue exposing (File)
import RemoteData exposing (WebData)
import Utils
import Html exposing (track)


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


{-| The model for the Option module.
-}
type alias Model =
    { capsule : Capsule
    , webcamPosition : ( Float, Float )
    , deleteTrack : Maybe Data.SoundTrack
    , capsuleUpdate : RemoteData.WebData Capsule
    }


init : Capsule -> Model
init capsule =
    { capsule = capsule
    , webcamPosition = ( 0, 0 )
    , deleteTrack = Nothing
    , capsuleUpdate = RemoteData.NotAsked
    }
