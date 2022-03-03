module Data.Capsule exposing
    ( Capsule, assetPath
    , Gos, WebcamSettings, Fade, Anchor, Event, EventType(..)
    , Slide, slidePath, videoPath, gosVideoPath
    , Record
    , encodeCapsule, encodeGos, encodeWebcamSettings, encodeFade, encodeRecord, encodeEvent, encodeEventType, encodeAnchor
    , encodeSlide, encodePair
    , decodeCapsule, decodeGos, decodeWebcamSettings, decodePip, decodeFullscreen, decodeFade, decodeRecord, decodeEvent
    , decodeEventType, decodeAnchor, decodeSlide, decodePair
    )

{-| This module contains all the data related to capsules.


# The capsule type

@docs Capsule, assetPath


# The GoS (Group of Slides) type

@docs Gos, WebcamSettings, Fade, Anchor, Event, EventType


## Slides

@docs Slide, slidePath, videoPath, gosVideoPath


## Records

@docs Record


# Encoders and decoders


## Encoders

@docs encodeCapsule, encodeGos, encodeWebcamSettings, encodeFade, encodeRecord, encodeEvent, encodeEventType, encodeAnchor
@docs encodeSlide, encodePair


## Decoders

@docs decodeCapsule, decodeGos, decodeWebcamSettings, decodePip, decodeFullscreen, decodeFade, decodeRecord, decodeEvent
@docs decodeEventType, decodeAnchor, decodeSlide, decodePair

-}

import Data.Types as Data
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Utils exposing (andMap)


{-| This type represents a capsule.
-}
type alias Capsule =
    { id : String
    , name : String
    , project : String
    , role : Data.Role
    , videoUploaded : Data.TaskStatus
    , produced : Data.TaskStatus
    , published : Data.TaskStatus
    , privacy : Data.Privacy
    , structure : List Gos
    , lastModified : Int
    , promptSubtitles : Bool
    , diskUsage : Int
    , duration : Int
    }


{-| JSON encoder for capsule.
-}
encodeCapsule : Capsule -> Encode.Value
encodeCapsule capsule =
    Encode.object
        [ ( "id", Encode.string capsule.id )
        , ( "project", Encode.string capsule.project )
        , ( "name", Encode.string capsule.name )
        , ( "privacy", Data.encodePrivacy capsule.privacy )
        , ( "prompt_subtitles", Encode.bool capsule.promptSubtitles )
        , ( "structure", Encode.list encodeGos capsule.structure )
        ]


{-| JSON decoder for caspule.
-}
decodeCapsule : Decoder Capsule
decodeCapsule =
    Decode.succeed Capsule
        |> andMap (Decode.field "id" Decode.string)
        |> andMap (Decode.field "name" Decode.string)
        |> andMap (Decode.field "project" Decode.string)
        |> andMap (Decode.field "role" Data.decodeRole)
        |> andMap (Decode.field "video_uploaded" Data.decodeTaskStatus)
        |> andMap (Decode.field "produced" Data.decodeTaskStatus)
        |> andMap (Decode.field "published" Data.decodeTaskStatus)
        |> andMap (Decode.field "privacy" Data.decodePrivacy)
        |> andMap (Decode.field "structure" (Decode.list decodeGos))
        |> andMap (Decode.field "last_modified" Decode.int)
        -- |> andMap (Decode.field "users" (Decode.list decodeUser))
        |> andMap (Decode.field "prompt_subtitles" Decode.bool)
        |> andMap (Decode.field "disk_usage" Decode.int)
        |> andMap (Decode.field "duration_ms" Decode.int)


{-| Returns an asset path from its capsule and basename.
-}
assetPath : Capsule -> String -> String
assetPath capsule path =
    "/data/" ++ capsule.id ++ "/assets/" ++ path


{-| This type represents a slide of a presentation.
-}
type alias Slide =
    { uuid : String
    , extra : Maybe String
    , prompt : String
    }


{-| JSON encoder for a slide.
-}
encodeSlide : Slide -> Encode.Value
encodeSlide slide =
    Encode.object
        [ ( "uuid", Encode.string slide.uuid )
        , ( "extra", Maybe.map Encode.string slide.extra |> Maybe.withDefault Encode.null )
        , ( "prompt", Encode.string slide.prompt )
        ]


{-| JSON decoder for a slide.
-}
decodeSlide : Decoder Slide
decodeSlide =
    Decode.map3 Slide
        (Decode.field "uuid" Decode.string)
        (Decode.maybe (Decode.field "extra" Decode.string))
        (Decode.field "prompt" Decode.string)


{-| Returns the path to the image of the slide.
-}
slidePath : Capsule -> Slide -> String
slidePath capsule slide =
    assetPath capsule (slide.uuid ++ ".png")


{-| Returns the path to the video file of a produced capsule.

Returns Nothing if the capsule hasn't been produced yet.

-}
videoPath : Capsule -> Maybe String
videoPath capsule =
    if capsule.produced == Data.Done then
        Just ("/data/" ++ capsule.id ++ "/output.mp4")

    else
        Nothing


{-| Returns the path to a specific gos that has been produced independantly from the video.
-}
gosVideoPath : Capsule -> Int -> String
gosVideoPath capsule gos =
    assetPath capsule "tmp/gos_" ++ String.fromInt gos ++ ".mp4"


{-| This type represents a record done by a webcam.
-}
type alias Record =
    { uuid : String
    , pointerUuid : Maybe String
    , size : Maybe ( Int, Int )
    }


{-| JSON encoder for record.
-}
encodeRecord : Maybe Record -> Encode.Value
encodeRecord record =
    case record of
        Just r ->
            Encode.object
                [ ( "uuid", Encode.string r.uuid )
                , ( "pointer_uuid", r.pointerUuid |> Maybe.map Encode.string |> Maybe.withDefault Encode.null )
                , ( "size", r.size |> Maybe.map (encodePair Encode.int) |> Maybe.withDefault Encode.null )
                ]

        Nothing ->
            Encode.null


{-| JSON decoder for record.
-}
decodeRecord : Decoder Record
decodeRecord =
    Decode.map3 Record
        (Decode.field "uuid" Decode.string)
        (Decode.maybe (Decode.field "pointer_uuid" Decode.string))
        (Decode.maybe (Decode.field "size" (decodePair Decode.int)))


{-| JSON encoder for any pair.
-}
encodePair : (a -> Encode.Value) -> ( a, a ) -> Encode.Value
encodePair encoder ( x, y ) =
    Encode.list encoder [ x, y ]


{-| JSON decoder for a pair of int.
-}
decodePair : Decoder a -> Decoder ( a, a )
decodePair decoder =
    Decode.map2 Tuple.pair
        (Decode.index 0 decoder)
        (Decode.index 1 decoder)


{-| This type represents the different events that can occur during a record session.
-}
type EventType
    = Start
    | NextSlide
    | PreviousSlide
    | NextSentence
    | Play
    | Stop
    | End


{-| JSON encoder for event types.
-}
encodeEventType : EventType -> Encode.Value
encodeEventType e =
    let
        s =
            case e of
                Start ->
                    "start"

                NextSlide ->
                    "next_slide"

                PreviousSlide ->
                    "previous_slide"

                NextSentence ->
                    "next_sentence"

                Play ->
                    "play"

                Stop ->
                    "stop"

                End ->
                    "end"
    in
    Encode.string s


{-| JSON decoder for event types.
-}
decodeEventType : Decoder EventType
decodeEventType =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "start" ->
                        Decode.succeed Start

                    "next_slide" ->
                        Decode.succeed NextSlide

                    "previous_slide" ->
                        Decode.succeed PreviousSlide

                    "next_sentence" ->
                        Decode.succeed NextSentence

                    "play" ->
                        Decode.succeed Play

                    "stop" ->
                        Decode.succeed Stop

                    "end" ->
                        Decode.succeed End

                    x ->
                        Decode.fail <| "Unknown event type: " ++ x
            )


{-| This type represents what events occured and when.
-}
type alias Event =
    { ty : EventType
    , time : Int
    }


{-| JSON encoder for events.
-}
encodeEvent : Event -> Encode.Value
encodeEvent e =
    Encode.object
        [ ( "ty", encodeEventType e.ty )
        , ( "time", Encode.int e.time )
        ]


{-| JSON decoder for events.
-}
decodeEvent : Decoder Event
decodeEvent =
    Decode.map2 Event
        (Decode.field "ty" decodeEventType)
        (Decode.field "time" Decode.int)


{-| Anchor to which a record is attached in production.
-}
type Anchor
    = BottomLeft
    | BottomRight
    | TopLeft
    | TopRight


{-| JSON encoder for anchors.
-}
encodeAnchor : Anchor -> Encode.Value
encodeAnchor anchor =
    Encode.string
        (case anchor of
            BottomLeft ->
                "bottom_left"

            BottomRight ->
                "bottom_right"

            TopLeft ->
                "top_left"

            TopRight ->
                "top_right"
        )


{-| JSON decoder for anchors.
-}
decodeAnchor : Decoder Anchor
decodeAnchor =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "bottom_left" ->
                        Decode.succeed BottomLeft

                    "bottom_right" ->
                        Decode.succeed BottomRight

                    "top_left" ->
                        Decode.succeed TopLeft

                    "top_right" ->
                        Decode.succeed TopRight

                    x ->
                        Decode.fail <| "Unknown anchor: " ++ x
            )


{-| The settings of the placement of a webcam in production.
-}
type WebcamSettings
    = Disabled
    | Fullscreen { opacity : Float, keycolor : Maybe String }
    | Pip { anchor : Anchor, opacity : Float, position : ( Int, Int ), size : ( Int, Int ), keycolor : Maybe String }


{-| JSON encoder for webcam settings.
-}
encodeWebcamSettings : WebcamSettings -> Encode.Value
encodeWebcamSettings settings =
    case settings of
        Disabled ->
            Encode.object [ ( "type", Encode.string "disabled" ) ]

        Fullscreen { opacity, keycolor } ->
            Encode.object
                [ ( "type", Encode.string "fullscreen" )
                , ( "opacity", Encode.float opacity )
                , ( "keycolor", Maybe.withDefault Encode.null (Maybe.map Encode.string keycolor) )
                ]

        Pip { anchor, position, size, opacity, keycolor } ->
            Encode.object
                [ ( "type", Encode.string "pip" )
                , ( "anchor", encodeAnchor anchor )
                , ( "position", encodePair Encode.int position )
                , ( "size", encodePair Encode.int size )
                , ( "opacity", Encode.float opacity )
                , ( "keycolor", Maybe.withDefault Encode.null (Maybe.map Encode.string keycolor) )
                ]


{-| JSON decoder for the Pip attributes of webcam settings.
-}
decodePip : Decoder { anchor : Anchor, opacity : Float, position : ( Int, Int ), size : ( Int, Int ), keycolor : Maybe String }
decodePip =
    Decode.map5 (\a o p s k -> { anchor = a, opacity = o, position = p, size = s, keycolor = k })
        (Decode.field "anchor" decodeAnchor)
        (Decode.field "opacity" Decode.float)
        (Decode.field "position" (decodePair Decode.int))
        (Decode.field "size" (decodePair Decode.int))
        (Decode.maybe (Decode.field "keycolor" Decode.string))


{-| JSON decoder for the fullscreen attributs of webcam settings.
-}
decodeFullscreen : Decoder { opacity : Float, keycolor : Maybe String }
decodeFullscreen =
    Decode.map2 (\o k -> { opacity = o, keycolor = k })
        (Decode.field "opacity" Decode.float)
        (Decode.maybe (Decode.field "keycolor" Decode.string))


{-| JSON decoder for webcam settings.
-}
decodeWebcamSettings : Decoder WebcamSettings
decodeWebcamSettings =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\x ->
                case x of
                    "disabled" ->
                        Decode.succeed Disabled

                    "fullscreen" ->
                        Decode.map Fullscreen decodeFullscreen

                    "pip" ->
                        Decode.map Pip decodePip

                    _ ->
                        Decode.fail ("Unknown webcam settings type " ++ x)
            )


{-| This type represents the different types of fading that have been activated on video record.
-}
type alias Fade =
    { vfadein : Maybe Int
    , vfadeout : Maybe Int
    , afadein : Maybe Int
    , afadeout : Maybe Int
    }


{-| JSON encoder for fade attributes.
-}
encodeFade : Fade -> Encode.Value
encodeFade f =
    Encode.object
        [ ( "vfadein", Maybe.withDefault Encode.null (Maybe.map Encode.int f.vfadein) )
        , ( "vfadeout", Maybe.withDefault Encode.null (Maybe.map Encode.int f.vfadeout) )
        , ( "afadein", Maybe.withDefault Encode.null (Maybe.map Encode.int f.afadein) )
        , ( "afadeout", Maybe.withDefault Encode.null (Maybe.map Encode.int f.afadeout) )
        ]


{-| JSON decoder for fade attributes.
-}
decodeFade : Decoder Fade
decodeFade =
    Decode.map4 Fade
        (Decode.maybe (Decode.field "vfadein" Decode.int))
        (Decode.maybe (Decode.field "vfadeout" Decode.int))
        (Decode.maybe (Decode.field "afadein" Decode.int))
        (Decode.maybe (Decode.field "afadeout" Decode.int))


{-| This type represents a group of slides (GoS).
-}
type alias Gos =
    { record : Maybe Record
    , slides : List Slide
    , events : List Event
    , webcamSettings : WebcamSettings
    , fade : Fade
    }


{-| JSON encoder for gos.
-}
encodeGos : Gos -> Encode.Value
encodeGos gos =
    Encode.object
        [ ( "record", encodeRecord gos.record )
        , ( "slides", Encode.list encodeSlide gos.slides )
        , ( "events", Encode.list encodeEvent gos.events )
        , ( "webcam_settings", encodeWebcamSettings gos.webcamSettings )
        , ( "fade", encodeFade gos.fade )
        ]


{-| JSON decoder for gos.
-}
decodeGos : Decoder Gos
decodeGos =
    Decode.map5 Gos
        (Decode.maybe (Decode.field "record" decodeRecord))
        (Decode.field "slides" (Decode.list decodeSlide))
        (Decode.field "events" (Decode.list decodeEvent))
        (Decode.field "webcam_settings" decodeWebcamSettings)
        (Decode.field "fade" decodeFade)