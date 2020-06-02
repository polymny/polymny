module Acquisition.Types exposing (Model, Msg(..), init, withSlides)

import Acquisition.Ports as Ports
import Api


type alias Model =
    { recordingsNumber : Int
    , recording : Bool
    , currentStream : Int
    , slides : Maybe (List Api.Slide)
    , capsule : Api.Capsule
    , gos : Int
    }


init : Api.Capsule -> Int -> ( Model, Cmd Msg )
init capsule gos =
    ( { recordingsNumber = 0
      , recording = False
      , currentStream = 0
      , slides = Nothing
      , capsule = capsule
      , gos = gos
      }
    , Ports.init "video"
    )


withSlides : Api.Capsule -> Int -> List Api.Slide -> ( Model, Cmd Msg )
withSlides capsule gos slides =
    ( { recordingsNumber = 0
      , recording = False
      , currentStream = 0
      , slides = Just slides
      , capsule = capsule
      , gos = gos
      }
    , Ports.init "video"
    )


type Msg
    = AcquisitionClicked
    | StartRecording
    | StopRecording
    | GoToStream Int
    | RecordingsNumber Int
    | UploadStream String Int
