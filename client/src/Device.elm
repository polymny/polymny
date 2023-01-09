port module Device exposing (..)

{-| This module helps us deal with devices (webcams and microphones).
-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| A video device, e.g. a webcam.
-}
type alias Video =
    { deviceId : String
    , groupId : String
    , label : String
    , available : Bool
    , resolutions : List Resolution
    }


{-| Encodes a video device.
-}
encodeVideo : Video -> Encode.Value
encodeVideo video =
    Encode.object
        [ ( "deviceId", Encode.string video.deviceId )
        , ( "groupId", Encode.string video.groupId )
        , ( "label", Encode.string video.label )
        , ( "available", Encode.bool video.available )
        , ( "resolutions", Encode.list encodeResolution video.resolutions )
        ]


{-| Decodes a video device.
-}
decodeVideo : Decoder Video
decodeVideo =
    Decode.map5 Video
        (Decode.field "deviceId" Decode.string)
        (Decode.field "groupId" Decode.string)
        (Decode.field "label" Decode.string)
        (Decode.field "available" Decode.bool)
        (Decode.field "resolutions" (Decode.list decodeResolution))


{-| The resolution of a video device.
-}
type alias Resolution =
    { width : Int
    , height : Int
    }


{-| Encodes a resolution of a video device.
-}
encodeResolution : Resolution -> Encode.Value
encodeResolution resolution =
    Encode.object
        [ ( "width", Encode.int resolution.width )
        , ( "height", Encode.int resolution.height )
        ]


{-| Decodes a resolution of a video device.
-}
decodeResolution : Decoder Resolution
decodeResolution =
    Decode.map2 Resolution
        (Decode.field "width" Decode.int)
        (Decode.field "height" Decode.int)


{-| An audio device, e.g. a microphone.
-}
type alias Audio =
    { deviceId : String
    , groupId : String
    , label : String
    , available : Bool
    }


{-| Encodes an audio device.
-}
encodeAudio : Audio -> Encode.Value
encodeAudio audio =
    Encode.object
        [ ( "deviceId", Encode.string audio.deviceId )
        , ( "groupId", Encode.string audio.groupId )
        , ( "label", Encode.string audio.label )
        , ( "available", Encode.bool audio.available )
        ]


{-| Decodes an audio device.
-}
decodeAudio : Decoder Audio
decodeAudio =
    Decode.map4 Audio
        (Decode.field "deviceId" Decode.string)
        (Decode.field "groupId" Decode.string)
        (Decode.field "label" Decode.string)
        (Decode.field "available" Decode.bool)


{-| A complete recording device, with video and audio.
-}
type alias Device =
    { video : Maybe ( Video, Resolution )
    , audio : Maybe Audio
    }


{-| Every existing device on the client.
-}
type alias Devices =
    { video : List Video
    , audio : List Audio
    }


{-| Encodes many devices.
-}
encodeDevices : Devices -> Encode.Value
encodeDevices devices =
    Encode.object
        [ ( "video", Encode.list encodeVideo devices.video )
        , ( "audio", Encode.list encodeAudio devices.audio )
        ]


{-| Decodes many devices.
-}
decodeDevices : Decoder Devices
decodeDevices =
    Decode.map2 Devices
        (Decode.field "video" (Decode.list decodeVideo))
        (Decode.field "audio" (Decode.list decodeAudio))


{-| Merges two sets of devices.

The first set needs to be the set that has been detected previously, the second set is the set detected currently.

-}
mergeDevices : Devices -> Devices -> Devices
mergeDevices old new =
    let
        -- Updates the state of the video device (sets the available flag depending on if its has been currently
        -- detected).
        updateVideo : Video -> Video
        updateVideo video =
            case List.filter (\x -> x.deviceId == video.deviceId) new.video of
                [] ->
                    { video | available = False }

                _ ->
                    { video | available = True }

        -- Same thing with audio
        updateAudio : Audio -> Audio
        updateAudio audio =
            case List.filter (\x -> x.deviceId == audio.deviceId) new.audio of
                [] ->
                    { audio | available = False }

                _ ->
                    { audio | available = True }

        oldVideos =
            List.map updateVideo old.video

        oldAudios =
            List.map updateAudio old.audio

        -- Filters the new video devices that are already in the old video devices.
        filterNewVideo : Video -> Bool
        filterNewVideo video =
            List.all (\x -> x.deviceId /= video.deviceId) old.video

        -- Same for audio.
        filterNewAudio : Audio -> Bool
        filterNewAudio audio =
            List.all (\x -> x.deviceId /= audio.deviceId) old.audio

        newVideos =
            List.filter filterNewVideo new.video

        newAudios =
            List.filter filterNewAudio new.audio
    in
    { video = oldVideos ++ newVideos
    , audio = oldAudios ++ newAudios
    }


{-| Triggers a full detection of every device.
-}
port detectDevicesPort : () -> Cmd msg


detectDevices : Cmd msg
detectDevices =
    detectDevicesPort ()


{-| Port where the javascript send the detected devices after detectDevices.
-}
port detectDevicesResponse : (Encode.Value -> msg) -> Sub msg
