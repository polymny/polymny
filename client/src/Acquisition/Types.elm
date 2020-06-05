module Acquisition.Types exposing (Model, Msg(..), init)

import Acquisition.Ports as Ports
import Api
import Json.Encode


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
      , slides = List.head (List.drop gos (Api.detailsSortSlides details))
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
    | StreamUploaded Json.Encode.Value
