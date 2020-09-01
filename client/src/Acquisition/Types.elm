module Acquisition.Types exposing (Mode(..), Model, Msg(..), Record, init, initAtFirstNonRecorded, newRecord)

import Acquisition.Ports as Ports
import Api
import Json.Encode
import Status exposing (Status)


type Mode
    = Single
    | All


type alias Record =
    { id : Int
    , new : Bool
    , started : Int
    , nextSlides : List Int
    }


newRecord : Int -> Int -> Record
newRecord id started =
    { id = id, new = True, started = started, nextSlides = [] }


type alias Model =
    { records : List Record
    , recording : Bool
    , currentVideo : Maybe Int
    , slides : Maybe (List Api.Slide)
    , details : Api.CapsuleDetails
    , gos : Int
    , currentSlide : Int
    , mode : Mode
    , cameraReady : Bool
    , status : Status () ()
    , secondsRemaining : Maybe Int
    , background : Maybe String
    }


init : Bool -> Api.CapsuleDetails -> Mode -> Int -> ( Model, Cmd Msg )
init mattingEnabled details mode gos =
    let
        record =
            case List.head (List.drop gos details.structure) of
                Just g ->
                    case g.record of
                        Just s ->
                            Just ( s, Record 0 False 0 g.transitions )

                        _ ->
                            Nothing

                _ ->
                    Nothing

        records =
            case record of
                Just g ->
                    [ Tuple.second g ]

                Nothing ->
                    []

        -- Last background used
        background : Maybe String
        background =
            if mattingEnabled then
                List.head (List.filterMap (\x -> x) (List.reverse (List.map (\x -> x.background) details.structure)))

            else
                Nothing
    in
    ( { records = records
      , recording = False
      , currentVideo = Nothing
      , slides = List.head (List.drop gos (Api.detailsSortSlides details))
      , details = details
      , gos = gos
      , currentSlide = 0
      , mode = mode
      , cameraReady = False
      , status = Status.NotSent
      , secondsRemaining = Nothing
      , background = background
      }
    , Ports.init ( "video", Maybe.map Tuple.first record, background )
    )


filterNonRecorded : ( Int, Api.Gos ) -> Maybe Int
filterNonRecorded ( id, gos ) =
    case gos.record of
        Nothing ->
            Just id

        Just _ ->
            Nothing


initAtFirstNonRecorded : Bool -> Api.CapsuleDetails -> Mode -> ( Model, Cmd Msg )
initAtFirstNonRecorded mattingEnabled details mode =
    let
        gos : Int
        gos =
            List.indexedMap Tuple.pair details.structure
                |> List.filterMap filterNonRecorded
                |> List.head
                |> Maybe.withDefault 0
    in
    init mattingEnabled details mode gos


type Msg
    = StartRecording
    | StopRecording
    | CameraReady
    | GoToWebcam
    | GoToStream Int
    | NextSlide Bool
    | UploadStream String Int
    | StreamUploaded Json.Encode.Value
    | NextSlideReceived Int
    | NewRecord Int
    | CaptureBackground
    | SecondsRemaining Int
    | BackgroundCaptured String
