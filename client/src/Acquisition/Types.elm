module Acquisition.Types exposing (Model, Msg(..), init, withSlides)

import Acquisition.Ports as Ports
import Api


type alias Model =
    { recordingsNumber : Int
    , recording : Bool
    , currentStream : Int
    , slides : Maybe (List Api.Slide)
    }


init : ( Model, Cmd Msg )
init =
    ( { recordingsNumber = 0
      , recording = False
      , currentStream = 0
      , slides = Nothing
      }
    , Ports.init "video"
    )


withSlides : List Api.Slide -> ( Model, Cmd Msg )
withSlides slides =
    ( { recordingsNumber = 0
      , recording = False
      , currentStream = 0
      , slides = Just slides
      }
    , Ports.init "video"
    )


type Msg
    = AcquisitionClicked
    | StartRecording
    | StopRecording
    | GoToStream Int
    | RecordingsNumber Int
