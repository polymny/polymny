module Acquisition.Types exposing (Model, Msg(..), Record, init, newRecord)

import Acquisition.Ports as Ports
import Api
import Json.Encode


type alias Record =
    { started : Float
    , nextSlides : List Float
    }


newRecord : Float -> Record
newRecord started =
    { started = started, nextSlides = [] }


type alias Model =
    { records : List Record
    , recording : Bool
    , currentStream : Int
    , slides : Maybe (List Api.Slide)
    , details : Api.CapsuleDetails
    , gos : Int
    , currentSlide : Int
    }


init : Api.CapsuleDetails -> Int -> ( Model, Cmd Msg )
init details gos =
    ( { records = []
      , recording = False
      , currentStream = 0
      , slides = List.head (List.drop gos (Api.detailsSortSlides details))
      , details = details
      , gos = gos
      , currentSlide = 0
      }
    , Ports.init "video"
    )


type Msg
    = AcquisitionClicked
    | StartRecording
    | StopRecording
    | GoToStream Int
    | NextSlide Bool
    | UploadStream String Int
    | StreamUploaded Json.Encode.Value
    | NextSlideReceived Float
    | NewRecord Float
