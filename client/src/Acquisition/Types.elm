module Acquisition.Types exposing (Model, Msg(..), init)

import Acquisition.Ports as Ports


type alias Model =
    { recordingsNumber : Int
    , recording : Bool
    , currentStream : Int
    }


init : ( Model, Cmd Msg )
init =
    ( { recordingsNumber = 0
      , recording = False
      , currentStream = 0
      }
    , Ports.bindWebcam "video"
    )


type Msg
    = AcquisitionClicked
    | StartRecording
    | StopRecording
    | GoToStream Int
    | RecordingsNumber Int
