module Acquisition.Types exposing (Model, State(..), Record, recordDuration, encodeRecord, decodeRecord, init, Msg(..))

{-| This module contains the types for the acqusition page, where a user can record themself.

@docs Model, State, Record, recordDuration, encodeRecord, decodeRecord, init, Msg

-}

import Data.Capsule as Data exposing (Capsule)
import Device
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Time


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
    , gos : Int
    , state : State
    , deviceLevel : Maybe Float
    , showSettings : Bool
    , recording : Maybe Time.Posix
    , currentSlide : Int
    , currentSentence : Int
    , records : List Record
    , recordPlaying : Maybe Record
    }


{-| A record stored in the memory of the client.
-}
type alias Record =
    { events : List Data.Event
    , deviceBlob : Encode.Value
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
    Decode.map3 Record
        (Decode.field "events" (Decode.list Data.decodeEvent))
        (Decode.field "webcam_blob" Decode.value)
        -- (Decode.field "pointer_blob" (Decode.nullable Decode.value))
        (Decode.succeed False)


{-| Encodes a record so it can be sent to JavaScript.
-}
encodeRecord : Record -> Encode.Value
encodeRecord record =
    Encode.object
        [ ( "events", Encode.list Data.encodeEvent record.events )
        , ( "webcam_blob", record.deviceBlob )

        -- , ( "pointer_blob", record.pointerBlob |> Maybe.withDefault Encode.null )
        ]


{-| Initializes a model from the capsule and the grain we want to record.

It returns Nothing if the grain is not in the capsule.

-}
init : Int -> Capsule -> Maybe ( Model, Cmd Msg )
init gos capsule =
    if gos < List.length capsule.structure && gos >= 0 then
        Just <|
            ( { capsule = capsule
              , gos = gos
              , state = DetectingDevices
              , deviceLevel = Nothing
              , showSettings = False
              , recording = Nothing
              , currentSlide = 0
              , currentSentence = 0
              , records = []
              , recordPlaying = Nothing
              }
            , Device.detectDevices Nothing
            )

    else
        Nothing


{-| The message type of the module.
-}
type Msg
    = DeviceChanged
    | DetectDevicesFinished
    | DeviceBound
    | DeviceLevel Float
    | ToggleSettings
    | StartRecording
    | StopRecording
    | NextSentence
    | RecordArrived Record
    | PlayRecordFinished
    | PlayRecord Record
    | RequestCameraPermission String
    | UploadRecord Record
