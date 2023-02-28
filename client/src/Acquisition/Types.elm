port module Acquisition.Types exposing
    ( Model, State(..), Record, recordDuration, encodeRecord, decodeRecord, init, Msg(..), pointerCanvasId, PointerStyle, encodePointerStyle
    , setPointerStyle
    )

{-| This module contains the types for the acqusition page, where a user can record themself.

@docs Model, State, Record, recordDuration, encodeRecord, decodeRecord, init, Msg, pointerCanvasId, PointerStyle, encodePointerStyle

-}

import Data.Capsule as Data exposing (Capsule)
import Device
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Time
import Utils


{-| The different state of loading in which the acquisition page can be.
-}
type State
    = DetectingDevices
    | BindingWebcam
    | Ready


{-| The type for the model of the acquisition page.
-}
type alias Model =
    { capsule : Capsule
    , gos : Data.Gos
    , gosId : Int
    , state : State
    , deviceLevel : Maybe Float
    , showSettings : Bool
    , recording : Maybe Time.Posix
    , currentSlide : Int
    , currentSentence : Int
    , records : List Record
    , recordPlaying : Maybe Record
    , savedRecord : Maybe Data.Record
    , deleteRecord : Bool
    , pointerStyle : PointerStyle
    }


{-| A record stored in the memory of the client.
-}
type alias Record =
    { events : List Data.Event
    , deviceBlob : Encode.Value
    , pointerBlob : Maybe Encode.Value
    , old : Bool
    }


{-| Gets the duration of a record.
-}
recordDuration : Record -> Int
recordDuration record =
    record.events
        |> List.reverse
        |> List.head
        |> Maybe.map .time
        |> Maybe.withDefault 0


{-| Decodes a record received from JavaScript.
-}
decodeRecord : Decoder Record
decodeRecord =
    Decode.map4 Record
        (Decode.field "events" (Decode.list Data.decodeEvent))
        (Decode.field "webcam_blob" Decode.value)
        (Decode.field "pointer_blob" (Decode.nullable Decode.value))
        (Decode.succeed False)


{-| Encodes a record so it can be sent to JavaScript.
-}
encodeRecord : Record -> Encode.Value
encodeRecord record =
    Encode.object
        [ ( "events", Encode.list Data.encodeEvent record.events )
        , ( "webcam_blob", record.deviceBlob )
        , ( "pointer_blob", record.pointerBlob |> Maybe.withDefault Encode.null )
        ]


{-| The style of the pointer.
-}
type alias PointerStyle =
    { mode : PointerMode
    , color : String
    , size : Int
    }


{-| The mode of the pointer: pointer or brush.
-}
type PointerMode
    = Pointer
    | Brush


{-| Encodes a pointer mode in json.
-}
encodePointerMode : PointerMode -> Encode.Value
encodePointerMode mode =
    Encode.string <|
        case mode of
            Pointer ->
                "Pointer"

            Brush ->
                "Brush"


{-| Encodes a pointer style in json.
-}
encodePointerStyle : PointerStyle -> Encode.Value
encodePointerStyle style =
    Encode.object
        [ ( "mode", encodePointerMode style.mode )
        , ( "color", Encode.string style.color )
        , ( "size", Encode.int style.size )
        ]


{-| The default pointer style value.
-}
defaultPointerStyle : PointerStyle
defaultPointerStyle =
    { mode = Pointer
    , size = 10
    , color = "rgb(255, 0, 0)"
    }


{-| Initializes a model from the capsule and the grain we want to record.

It returns Nothing if the grain is not in the capsule.

-}
init : Int -> Capsule -> Maybe ( Model, Cmd Msg )
init gos capsule =
    case List.drop gos capsule.structure of
        h :: _ ->
            Just <|
                ( { capsule = capsule
                  , gos = h
                  , gosId = gos
                  , state = DetectingDevices
                  , deviceLevel = Nothing
                  , showSettings = False
                  , recording = Nothing
                  , currentSlide = 0
                  , currentSentence = 0
                  , records =
                        case Data.recordPath capsule h of
                            Just recordPath ->
                                [ { events = h.events
                                  , deviceBlob = Encode.string recordPath
                                  , pointerBlob = Data.pointerPath capsule h |> Maybe.map Encode.string
                                  , old = True
                                  }
                                ]

                            _ ->
                                []
                  , recordPlaying = Nothing
                  , savedRecord = h.record
                  , deleteRecord = False
                  , pointerStyle = defaultPointerStyle
                  }
                , Cmd.batch [ Device.detectDevices Nothing, setupCanvas, setPointerStyle defaultPointerStyle ]
                )

        _ ->
            Nothing


{-| The message type of the module.
-}
type Msg
    = DeviceChanged
    | CurrentSentenceChanged String
    | DetectDevicesFinished
    | DeviceBound
    | DeviceLevel Float
    | ToggleSettings
    | StartRecording
    | StopRecording
    | NextSentence Bool
    | RecordArrived Record
    | PlayRecordFinished
    | PlayRecord Record
    | StopRecord
    | RequestCameraPermission String
    | UploadRecord Record
    | DeleteRecord Utils.Confirmation
    | EscapePressed
    | SetPointerMode PointerMode
    | SetPointerColor String
    | SetPointerSize Int


{-| Alias for the setup canvas port.
-}
setupCanvas : Cmd msg
setupCanvas =
    setupCanvasPort pointerCanvasId


{-| Port for initializing the canvas on which the user can draw or point.
-}
port setupCanvasPort : String -> Cmd msg


{-| Id of the canvas on which the pointer will be drawn.
-}
pointerCanvasId : String
pointerCanvasId =
    "pointer-canvas"


{-| Helper to change the pointer style.
-}
setPointerStyle : PointerStyle -> Cmd msg
setPointerStyle style =
    setPointerStylePort <| encodePointerStyle style


{-| Port to change the pointer style.
-}
port setPointerStylePort : Encode.Value -> Cmd msg
