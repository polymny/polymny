module Acquisition.Types exposing (Mode(..), Model, Msg(..), Record, init, initAtFirstNonRecorded, newRecord)

import Acquisition.Ports as Ports
import Api
import Json.Encode


type Mode
    = Single
    | All


type alias Record =
    { started : Int
    , nextSlides : List Int
    }


newRecord : Int -> Record
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
    , mode : Mode
    , cameraReady : Bool
    }


init : Api.CapsuleDetails -> Mode -> Int -> ( Model, Cmd Msg )
init details mode gos =
    ( { records = []
      , recording = False
      , currentStream = 0
      , slides = List.head (List.drop gos (Api.detailsSortSlides details))
      , details = details
      , gos = gos
      , currentSlide = 0
      , mode = mode
      , cameraReady = False
      }
    , Ports.init "video"
    )


filterNonRecorded : ( Int, Api.Gos ) -> Maybe Int
filterNonRecorded ( id, gos ) =
    case gos.record of
        Nothing ->
            Just id

        Just _ ->
            Nothing


initAtFirstNonRecorded : Api.CapsuleDetails -> Mode -> ( Model, Cmd Msg )
initAtFirstNonRecorded details mode =
    let
        gos : Int
        gos =
            List.indexedMap Tuple.pair details.structure
                |> List.filterMap filterNonRecorded
                |> List.head
                |> Maybe.withDefault 0
    in
    ( { records = []
      , recording = False
      , currentStream = 0
      , slides = List.head (List.drop gos (Api.detailsSortSlides details))
      , details = details
      , gos = gos
      , currentSlide = 0
      , mode = mode
      , cameraReady = False
      }
    , Ports.init "video"
    )


type Msg
    = StartRecording
    | StopRecording
    | CameraReady
    | GoToStream Int
    | NextSlide Bool
    | UploadStream String Int
    | StreamUploaded Json.Encode.Value
    | NextSlideReceived Int
    | NewRecord Int
