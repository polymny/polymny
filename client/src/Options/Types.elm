module Options.Types exposing (..)

{-| This module contains the types used in the Option module.
|
-}

import Data.Capsule as Data exposing (Capsule)
import File exposing (File)
import FileValue exposing (File)
import RemoteData exposing (WebData)


{-| Message type of the app.
-}
type Msg
    = SetOpacity Float
    | SetWidth (Maybe Int) -- Nothing means fullscreen
    | SetAnchor Data.Anchor
    | ToggleVideo
    | TrackUploadRequested
    | TrackUploadReceived FileValue.File File.File
    | TrackUploaded File
    | TrackUploadResponded (WebData Capsule)
    | RequestDeleteTrack
    | DeleteTrackResponded (WebData Capsule)


{-| The model for the Option module.
|
-}
type alias Model =
    { capsule : Capsule
    , webcamPosition : ( Float, Float )
    , holdingImage : Maybe ( Int, Float, Float )
    }


init : Capsule -> Model
init capsule =
    { capsule = capsule
    , webcamPosition = ( 0, 0 )
    , holdingImage = Nothing
    }
