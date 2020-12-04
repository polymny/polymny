module Acquisition.Types exposing
    ( AudioDevice
    , Mode(..)
    , Model
    , Msg(..)
    , Record
    , Resolution
    , VideoDevice
    , audio
    , decodeDevices
    , init
    , initAtFirstNonRecorded
    , newRecord
    , replaceAudio
    , replaceResolution
    , replaceVideo
    , resolution
    , video
    )

import Acquisition.Ports as Ports
import Api
import Dropdown
import Json.Decode as Decode exposing (Decoder)
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


type alias Resolution =
    { width : Int, height : Int }


type alias VideoDevice =
    { deviceId : String, groupId : String, label : String, resolutions : List Resolution }


type alias AudioDevice =
    { deviceId : String, groupId : String, label : String }


decodeResolution : Decoder Resolution
decodeResolution =
    Decode.map2 Resolution
        (Decode.field "width" Decode.int)
        (Decode.field "height" Decode.int)


decodeVideoDevice : Decoder VideoDevice
decodeVideoDevice =
    Decode.map4 VideoDevice
        (Decode.field "deviceId" Decode.string)
        (Decode.field "groupId" Decode.string)
        (Decode.field "label" Decode.string)
        (Decode.field "resolutions" (Decode.list decodeResolution))


decodeAudioDevice : Decoder AudioDevice
decodeAudioDevice =
    Decode.map3 AudioDevice
        (Decode.field "deviceId" Decode.string)
        (Decode.field "groupId" Decode.string)
        (Decode.field "label" Decode.string)


type alias Devices =
    { video : List VideoDevice
    , audio : List AudioDevice
    }


initDevices : Devices
initDevices =
    Devices [] []


decodeDevices : Decoder Devices
decodeDevices =
    Decode.map2 Devices
        (Decode.field "video" (Decode.list decodeVideoDevice))
        (Decode.field "audio" (Decode.list decodeAudioDevice))


type alias Model =
    { records : List Record
    , recording : Bool
    , currentVideo : Maybe Int
    , slides : Maybe (List Api.Slide)
    , details : Api.CapsuleDetails
    , gos : Int
    , currentSlide : Int
    , currentLine : Int
    , mode : Mode
    , cameraReady : Bool
    , status : Status () ()
    , secondsRemaining : Maybe Int
    , background : Maybe String
    , watchingWebcam : Bool
    , devices : Devices
    , showSettings : Maybe ( Dropdown.State VideoDevice, Dropdown.State Resolution, Dropdown.State AudioDevice )
    , device : ( Maybe VideoDevice, Maybe Resolution, Maybe AudioDevice )
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
      , currentLine = 0
      , mode = mode
      , cameraReady = False
      , status = Status.NotSent
      , secondsRemaining = Nothing
      , background = background
      , watchingWebcam = True
      , devices = initDevices
      , showSettings = Nothing
      , device = ( Nothing, Nothing, Nothing )
      }
    , Ports.init ( "video", Maybe.map Tuple.first record, background )
    )


video : Model -> Maybe VideoDevice
video model =
    let
        ( x, _, _ ) =
            model.device
    in
    x


resolution : Model -> Maybe Resolution
resolution model =
    let
        ( _, x, _ ) =
            model.device
    in
    x


audio : Model -> Maybe AudioDevice
audio model =
    let
        ( _, _, x ) =
            model.device
    in
    x


replaceVideo : Maybe VideoDevice -> ( Maybe VideoDevice, Maybe Resolution, Maybe AudioDevice ) -> ( Maybe VideoDevice, Maybe Resolution, Maybe AudioDevice )
replaceVideo toReplace ( _, y, z ) =
    ( toReplace, Maybe.andThen (List.head << .resolutions) toReplace, z )


replaceResolution : Maybe Resolution -> ( Maybe VideoDevice, Maybe Resolution, Maybe AudioDevice ) -> ( Maybe VideoDevice, Maybe Resolution, Maybe AudioDevice )
replaceResolution toReplace ( x, _, z ) =
    ( x, toReplace, z )


replaceAudio : Maybe AudioDevice -> ( Maybe VideoDevice, Maybe Resolution, Maybe AudioDevice ) -> ( Maybe VideoDevice, Maybe Resolution, Maybe AudioDevice )
replaceAudio toReplace ( x, y, _ ) =
    ( x, y, toReplace )


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
    | CameraReady Json.Encode.Value
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
    | NextSentence
    | ToggleSettings
    | VideoDropdownMsg (Dropdown.Msg VideoDevice)
    | AudioDropdownMsg (Dropdown.Msg AudioDevice)
    | ResolutionDropdownMsg (Dropdown.Msg Resolution)
    | VideoOptionPicked (Maybe VideoDevice)
    | AudioOptionPicked (Maybe AudioDevice)
    | ResolutionOptionPicked (Maybe Resolution)
