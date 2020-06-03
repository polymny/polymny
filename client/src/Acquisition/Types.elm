module Acquisition.Types exposing (Model, Msg(..), init, withSlides)

import Acquisition.Ports as Ports
import Api


type alias Model =
    { recordingsNumber : Int
    , recording : Bool
    , currentStream : Int
    , slides : Maybe (List Api.Slide)
    , details : Api.CapsuleDetails
    , gos : Int
    }


init : Api.CapsuleDetails -> Int -> ( Model, Cmd Msg )
init details gos =
    ( { recordingsNumber = 0
      , recording = False
      , currentStream = 0
      , slides = Nothing
      , details = details
      , gos = gos
      }
    , Ports.init "video"
    )


withSlides : Api.CapsuleDetails -> Int -> List Api.Slide -> ( Model, Cmd Msg )
withSlides details gos slides =
    ( { recordingsNumber = 0
      , recording = False
      , currentStream = 0
      , slides = Just slides
      , details = details
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
