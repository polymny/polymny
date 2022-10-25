module Acquisition.Types exposing (..)

import Acquisition.Ports as Ports
import Capsule exposing (Capsule)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import List.Extra
import Status exposing (Status)


type State
    = DetectingDevices
    | BindingWebcam
    | ErrorDetectingDevices
    | ErrorBindingWebcam


isError : State -> Bool
isError state =
    case state of
        ErrorDetectingDevices ->
            True

        ErrorBindingWebcam ->
            True

        _ ->
            False


type alias Model =
    { capsule : Capsule
    , gos : Int
    , currentSlide : Int
    , currentLine : Int
    , recording : Bool
    , webcamBound : Bool
    , records : List Record
    , showSettings : Bool
    , chosenDevice : Device
    , uploading : Maybe Float
    , state : State
    , status : Status
    , recordPlaying : Maybe Record
    }


type alias Record =
    { events : List Capsule.Event
    , webcamBlob : Encode.Value
    , pointerBlob : Maybe Encode.Value
    , old : Bool
    }


decodeRecord : Decoder Record
decodeRecord =
    Decode.map4 Record
        (Decode.field "events" (Decode.list Capsule.decodeEvent))
        (Decode.field "webcam_blob" Decode.value)
        (Decode.field "pointer_blob" (Decode.nullable Decode.value))
        (Decode.succeed False)


encodeRecord : Record -> Encode.Value
encodeRecord record =
    Encode.object
        [ ( "events", Encode.list Capsule.encodeEvent record.events )
        , ( "webcam_blob", record.webcamBlob )
        , ( "pointer_blob", record.pointerBlob |> Maybe.withDefault Encode.null )
        ]


type alias Submodel =
    { capsule : Capsule
    , gos : Int
    , devices : Devices
    , chosenDevice : Device
    , currentSlide : Int
    , currentLine : Int
    , recording : Bool
    , webcamBound : Bool
    , records : List Record
    , showSettings : Bool
    , uploading : Maybe Float
    , status : Status
    , recordPlaying : Maybe Record
    }


toSubmodel : Devices -> Model -> Submodel
toSubmodel devices model =
    { capsule = model.capsule
    , gos = model.gos
    , devices = devices
    , chosenDevice = model.chosenDevice
    , currentSlide = model.currentSlide
    , currentLine = model.currentLine
    , recording = model.recording
    , webcamBound = model.webcamBound
    , records = model.records
    , showSettings = model.showSettings
    , uploading = model.uploading
    , status = model.status
    , recordPlaying = model.recordPlaying
    }


init : Maybe Devices -> { a | videoDeviceId : Maybe String, resolution : Maybe String, audioDeviceId : Maybe String } -> Capsule -> Int -> ( Model, Cmd Msg )
init devices chosenDeviceIds capsule id =
    let
        model =
            { capsule = capsule
            , gos = id
            , currentLine = 0
            , currentSlide = 0
            , recording = False
            , webcamBound = False
            , records =
                let
                    gos =
                        List.head (List.drop id capsule.structure)
                in
                case ( Maybe.map .record gos, gos ) of
                    ( Just (Just r), Just g ) ->
                        [ { webcamBlob = Encode.string (Capsule.assetPath capsule (r.uuid ++ ".webm"))
                          , pointerBlob =
                                r.pointerUuid
                                    |> Maybe.map (\x -> x ++ ".webm")
                                    |> Maybe.map (Capsule.assetPath capsule)
                                    |> Maybe.map Encode.string
                          , events = g.events
                          , old = True
                          }
                        ]

                    _ ->
                        []
            , showSettings = False
            , chosenDevice =
                case devices of
                    Just d ->
                        deviceFromIds d chosenDeviceIds

                    _ ->
                        { video = Nothing, resolution = Nothing, audio = Nothing }
            , uploading = Nothing
            , state =
                case devices of
                    Just _ ->
                        BindingWebcam

                    _ ->
                        DetectingDevices
            , status = Status.NotSent
            , recordPlaying = Nothing
            }
    in
    ( model
    , case devices of
        Just d ->
            let
                sub =
                    toSubmodel d model
            in
            bindWebcam sub.chosenDevice

        Nothing ->
            Ports.findDevices False
    )


bindWebcam : Device -> Cmd msg
bindWebcam device =
    Ports.bindWebcam ( encodeDevice device, encodeRecordingOptions device )


type alias Resolution =
    { width : Int
    , height : Int
    }


type alias VideoDevice =
    { deviceId : String
    , groupId : String
    , label : String
    , resolutions : List Resolution
    }


type alias AudioDevice =
    { deviceId : String
    , groupId : String
    , label : String
    }


format : Resolution -> String
format r =
    String.fromInt r.width ++ "x" ++ String.fromInt r.height


type alias Devices =
    { video : List VideoDevice
    , audio : List AudioDevice
    }


type alias Device =
    { video : Maybe VideoDevice
    , resolution : Maybe Resolution
    , audio : Maybe AudioDevice
    }


type SetCanvas
    = ChangeStyle Style
    | ChangeColor String
    | ChangeSize Int
    | Erase


type Style
    = Pointer
    | Brush


encodeSetCanvas : SetCanvas -> Encode.Value
encodeSetCanvas setCanvas =
    case setCanvas of
        ChangeStyle Pointer ->
            Encode.object [ ( "ty", Encode.string "ChangeStyle" ), ( "style", Encode.string "Pointer" ) ]

        ChangeStyle Brush ->
            Encode.object [ ( "ty", Encode.string "ChangeStyle" ), ( "style", Encode.string "Brush" ) ]

        ChangeColor color ->
            Encode.object [ ( "ty", Encode.string "ChangeColor" ), ( "color", Encode.string color ) ]

        ChangeSize size ->
            Encode.object [ ( "ty", Encode.string "ChangeSize" ), ( "size", Encode.int size ) ]

        Erase ->
            Encode.object [ ( "ty", Encode.string "Erase" ) ]


type Msg
    = Noop
    | RefreshDevices
    | DevicesReceived Devices
    | WebcamBound
    | PointerBound
    | InvertAcquisition
    | StartRecording
    | StopRecording
    | RecordArrived Record
    | StartPointerRecording Record
    | PointerRecordArrived Record
    | ToggleSettings
    | VideoDeviceChanged (Maybe VideoDevice)
    | ResolutionChanged Resolution
    | AudioDeviceChanged AudioDevice
    | NextSentence
    | PlayRecord Record
    | StopPlayingRecord
    | NextSlideReceived
    | PlayRecordFinished
    | UploadRecord Record
    | CapsuleUpdated (Maybe Capsule)
    | ProgressReceived Float
    | DeviceDetectionFailed
    | WebcamBindingFailed
    | UploadRecordFailed
    | UploadRecordFailedAck
    | IncreasePromptSize
    | DecreasePromptSize
    | SetCanvas SetCanvas


defaultDevice : Devices -> Device
defaultDevice devices =
    { video = List.head devices.video
    , resolution = List.head devices.video |> Maybe.map (List.head << .resolutions) |> Maybe.withDefault Nothing
    , audio = List.head devices.audio
    }


videoDeviceFromId : List VideoDevice -> String -> Maybe (Maybe VideoDevice)
videoDeviceFromId devices id =
    case id of
        "disabled" ->
            Just Nothing

        _ ->
            List.Extra.find (\x -> x.deviceId == id) devices |> Maybe.map Just


resolutionFromString : List Resolution -> String -> Maybe Resolution
resolutionFromString devices id =
    List.Extra.find (\x -> format x == id) devices


audioDeviceFromId : List AudioDevice -> String -> Maybe AudioDevice
audioDeviceFromId devices id =
    List.Extra.find (\x -> x.deviceId == id) devices


deviceFromIds : Devices -> { a | videoDeviceId : Maybe String, resolution : Maybe String, audioDeviceId : Maybe String } -> Device
deviceFromIds devices { videoDeviceId, resolution, audioDeviceId } =
    let
        default =
            defaultDevice devices

        video =
            case videoDeviceId of
                Nothing ->
                    default.video

                Just "disabled" ->
                    Nothing

                Just x ->
                    case videoDeviceFromId devices.video x of
                        Nothing ->
                            default.video

                        Just Nothing ->
                            Nothing

                        Just y ->
                            y

        realResolution =
            case resolution of
                Nothing ->
                    Maybe.andThen (\x -> List.head x.resolutions) video

                Just x ->
                    Maybe.andThen
                        (\v ->
                            case resolutionFromString v.resolutions x of
                                Nothing ->
                                    List.head v.resolutions

                                Just r ->
                                    Just r
                        )
                        video

        audio =
            case audioDeviceId of
                Nothing ->
                    default.audio

                Just x ->
                    case audioDeviceFromId devices.audio x of
                        Nothing ->
                            default.audio

                        Just a ->
                            Just a
    in
    { video = video, resolution = realResolution, audio = audio }


encodeVideoDevice : VideoDevice -> Maybe Resolution -> Encode.Value
encodeVideoDevice video resolution =
    case resolution of
        Just r ->
            Encode.object
                [ ( "deviceId", Encode.object [ ( "exact", Encode.string video.deviceId ) ] )
                , ( "width", Encode.object [ ( "exact", Encode.int r.width ) ] )
                , ( "height", Encode.object [ ( "exact", Encode.int r.height ) ] )
                ]

        _ ->
            Encode.object
                [ ( "deviceId", Encode.object [ ( "exact", Encode.string video.deviceId ) ] ) ]


encodeMaybeVideoDevice : Maybe VideoDevice -> Maybe Resolution -> Encode.Value
encodeMaybeVideoDevice video resolution =
    case video of
        Just v ->
            encodeVideoDevice v resolution

        _ ->
            Encode.bool False


encodeAudioDevice : AudioDevice -> Encode.Value
encodeAudioDevice audio =
    Encode.object [ ( "deviceId", Encode.object [ ( "exact", Encode.string audio.deviceId ) ] ) ]


encodeMaybeAudioDevice : Maybe AudioDevice -> Encode.Value
encodeMaybeAudioDevice audio =
    Maybe.map encodeAudioDevice audio |> Maybe.withDefault (Encode.bool False)


encodeDevice : Device -> Encode.Value
encodeDevice device =
    Encode.object
        [ ( "video", encodeMaybeVideoDevice device.video device.resolution )
        , ( "audio", encodeMaybeAudioDevice device.audio )
        ]


encodeRecordingOptions : Device -> Encode.Value
encodeRecordingOptions device =
    case ( device.video, device.audio ) of
        ( Just _, Just _ ) ->
            Encode.object
                [ ( "videoBitsPerSecond", Encode.int 2500000 )
                , ( "audioBitsPerSecond", Encode.int 128000 )
                , ( "mimeType", Encode.string "video/webm;codecs=opus,vp8" )
                ]

        ( Nothing, Just _ ) ->
            Encode.object
                [ ( "audioBitsPerSecond", Encode.int 128000 )
                , ( "mimeType", Encode.string "video/webm;codecs=opus" )
                ]

        ( Just _, Nothing ) ->
            Encode.object
                [ ( "videoBitsPerSecond", Encode.int 2500000 )
                , ( "mimeType", Encode.string "video/webm;codecs=vp8" )
                ]

        _ ->
            Encode.object []


devicesReceived : Sub Msg
devicesReceived =
    Ports.devicesReceived
        (\x ->
            case Decode.decodeValue decodeDevices x of
                Ok o ->
                    DevicesReceived o

                _ ->
                    Noop
        )


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


decodeDevices : Decoder Devices
decodeDevices =
    Decode.map2 Devices
        (Decode.field "video" (Decode.list decodeVideoDevice))
        (Decode.field "audio" (Decode.list decodeAudioDevice))
