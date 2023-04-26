module Capsule exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import List.Extra
import Utils exposing (andMap, tern)


type Role
    = Owner
    | Write
    | Read


encodeRole : Role -> String
encodeRole role =
    case role of
        Owner ->
            "owner"

        Write ->
            "write"

        Read ->
            "read"


decodeRoleString : String -> Maybe Role
decodeRoleString role =
    case role of
        "owner" ->
            Just Owner

        "write" ->
            Just Write

        "read" ->
            Just Read

        _ ->
            Nothing


decodeRole : Decoder Role
decodeRole =
    Decode.string
        |> Decode.andThen
            (\str ->
                case decodeRoleString str of
                    Just x ->
                        Decode.succeed x

                    _ ->
                        Decode.fail <| "Unknown role: " ++ str
            )


type TaskStatus
    = Idle
    | Running (Maybe Float)
    | Done


printTaskStatus : TaskStatus -> String
printTaskStatus ts =
    case ts of
        Idle ->
            "Idle"

        Running _ ->
            "Running"

        Done ->
            "Done"


decodeTaskStatus : Decoder TaskStatus
decodeTaskStatus =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "idle" ->
                        Decode.succeed Idle

                    "running" ->
                        Decode.succeed (Running Nothing)

                    "done" ->
                        Decode.succeed Done

                    x ->
                        Decode.fail <| "Unknown task status: " ++ x
            )


type Privacy
    = Public
    | Unlisted
    | Private


decodePrivacy : Decoder Privacy
decodePrivacy =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "private" ->
                        Decode.succeed Private

                    "unlisted" ->
                        Decode.succeed Unlisted

                    "public" ->
                        Decode.succeed Public

                    x ->
                        Decode.fail <| "Unknown task status: " ++ x
            )


encodePrivacy : Privacy -> Encode.Value
encodePrivacy privacy =
    Encode.string
        (case privacy of
            Private ->
                "private"

            Unlisted ->
                "unlisted"

            Public ->
                "public"
        )


privacyToString : Privacy -> String
privacyToString privacy =
    case privacy of
        Private ->
            "private"

        Unlisted ->
            "unlisted"

        Public ->
            "public"


stringToPrivacy : String -> Maybe Privacy
stringToPrivacy string =
    case string of
        "private" ->
            Just Private

        "unlisted" ->
            Just Unlisted

        "public" ->
            Just Public

        _ ->
            Nothing


type alias Slide =
    { uuid : String
    , extra : Maybe String
    , prompt : String
    }


decodeSlide : Decoder Slide
decodeSlide =
    Decode.map3 Slide
        (Decode.field "uuid" Decode.string)
        (Decode.maybe (Decode.field "extra" Decode.string))
        (Decode.field "prompt" Decode.string)


encodeSlide : Slide -> Encode.Value
encodeSlide slide =
    Encode.object
        [ ( "uuid", Encode.string slide.uuid )
        , ( "extra"
          , case slide.extra of
                Just s ->
                    Encode.string s

                _ ->
                    Encode.null
          )
        , ( "prompt", Encode.string slide.prompt )
        ]


slidePath : Capsule -> Slide -> String
slidePath capsule slide =
    assetPath capsule (slide.uuid ++ ".png")


assetPath : Capsule -> String -> String
assetPath capsule path =
    "/data/" ++ capsule.id ++ "/assets/" ++ path


videoPath : Capsule -> Maybe String
videoPath capsule =
    if capsule.produced == Done then
        Just ("/data/" ++ capsule.id ++ "/output.mp4")

    else
        Nothing


videoGosPath : Capsule -> Int -> Maybe String
videoGosPath capsule gosId =
    if capsule.produced == Done then
        Just ("/data/" ++ capsule.id ++ "/tmp/gos_" ++ String.fromInt gosId ++ ".mp4")

    else
        Nothing


type alias Record =
    { uuid : String
    , pointerUuid : Maybe String
    , size : Maybe ( Int, Int )
    }


decodeRecord : Decoder Record
decodeRecord =
    Decode.map3 Record
        (Decode.field "uuid" Decode.string)
        (Decode.maybe (Decode.field "pointer_uuid" Decode.string))
        (Decode.maybe (Decode.field "size" decodeIntPair))


encodeRecord : Maybe Record -> Encode.Value
encodeRecord record =
    case record of
        Just r ->
            Encode.object
                [ ( "uuid", Encode.string r.uuid )
                , ( "pointer_uuid", r.pointerUuid |> Maybe.map Encode.string |> Maybe.withDefault Encode.null )
                , case r.size of
                    Just ( w, h ) ->
                        ( "size", Encode.list Encode.int [ w, h ] )

                    _ ->
                        ( "size", Encode.null )
                ]

        Nothing ->
            Encode.null


type EventType
    = Start
    | NextSlide
    | PreviousSlide
    | NextSentence
    | Play
    | Stop
    | End


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


type alias Event =
    { ty : EventType
    , time : Int
    }


decodeEvent : Decoder Event
decodeEvent =
    Decode.map2 Event
        (Decode.field "ty" decodeEventType)
        (Decode.field "time" Decode.int)


encodeEvent : Event -> Encode.Value
encodeEvent e =
    Encode.object
        [ ( "ty", encodeEventType e.ty )
        , ( "time", Encode.int e.time )
        ]


type alias Gos =
    { record : Maybe Record
    , slides : List Slide
    , events : List Event
    , webcamSettings : WebcamSettings
    , fade : Fade
    }


type Anchor
    = BottomLeft
    | BottomRight
    | TopLeft
    | TopRight


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


type WebcamSettings
    = Disabled
    | Fullscreen { opacity : Float, keycolor : Maybe String }
    | Pip { anchor : Anchor, opacity : Float, position : ( Int, Int ), size : ( Int, Int ), keycolor : Maybe String }


defaultWebcamSettings : WebcamSettings
defaultWebcamSettings =
    Pip defaultPip


initPip : Anchor -> Float -> ( Int, Int ) -> ( Int, Int ) -> Maybe String -> { anchor : Anchor, opacity : Float, position : ( Int, Int ), size : ( Int, Int ), keycolor : Maybe String }
initPip anchor opacity position size keycolor =
    { anchor = anchor, opacity = opacity, position = position, size = size, keycolor = keycolor }


initFullscreen : Float -> Maybe String -> { opacity : Float, keycolor : Maybe String }
initFullscreen opacity keycolor =
    { opacity = opacity, keycolor = keycolor }


defaultPip : { anchor : Anchor, opacity : Float, position : ( Int, Int ), size : ( Int, Int ), keycolor : Maybe String }
defaultPip =
    { anchor = BottomLeft, position = ( 4, 4 ), size = ( 400, 300 ), opacity = 1.0, keycolor = Nothing }


defaultFullscreen : { opacity : Float, keycolor : Maybe String }
defaultFullscreen =
    { opacity = 1.0, keycolor = Nothing }


decodeIntPair : Decoder ( Int, Int )
decodeIntPair =
    Decode.map2 Tuple.pair
        (Decode.index 0 Decode.int)
        (Decode.index 1 Decode.int)


decodePip : Decoder { anchor : Anchor, opacity : Float, position : ( Int, Int ), size : ( Int, Int ), keycolor : Maybe String }
decodePip =
    Decode.map5 initPip
        (Decode.field "anchor" decodeAnchor)
        (Decode.field "opacity" Decode.float)
        (Decode.field "position" decodeIntPair)
        (Decode.field "size" decodeIntPair)
        (Decode.maybe (Decode.field "keycolor" Decode.string))


decodeFullscreen : Decoder { opacity : Float, keycolor : Maybe String }
decodeFullscreen =
    Decode.map2 initFullscreen
        (Decode.field "opacity" Decode.float)
        (Decode.maybe (Decode.field "keycolor" Decode.string))


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


encodePair : ( Int, Int ) -> Encode.Value
encodePair ( x, y ) =
    Encode.list Encode.int [ x, y ]


pairToList : ( a, a ) -> List a
pairToList ( x, y ) =
    [ x, y ]


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
                , ( "position", Encode.list Encode.int (pairToList position) )
                , ( "size", Encode.list Encode.int (pairToList size) )
                , ( "opacity", Encode.float opacity )
                , ( "keycolor", Maybe.withDefault Encode.null (Maybe.map Encode.string keycolor) )
                ]


type alias Fade =
    { vfadein : Maybe Int
    , vfadeout : Maybe Int
    , afadein : Maybe Int
    , afadeout : Maybe Int
    }


decodeFade : Decoder Fade
decodeFade =
    Decode.map4 Fade
        (Decode.maybe (Decode.field "vfadein" Decode.int))
        (Decode.maybe (Decode.field "vfadeout" Decode.int))
        (Decode.maybe (Decode.field "afadein" Decode.int))
        (Decode.maybe (Decode.field "afadeout" Decode.int))


encodeFade : Fade -> Encode.Value
encodeFade f =
    Encode.object
        [ ( "vfadein", Maybe.withDefault Encode.null (Maybe.map Encode.int f.vfadein) )
        , ( "vfadeout", Maybe.withDefault Encode.null (Maybe.map Encode.int f.vfadeout) )
        , ( "afadein", Maybe.withDefault Encode.null (Maybe.map Encode.int f.afadein) )
        , ( "afadeout", Maybe.withDefault Encode.null (Maybe.map Encode.int f.afadeout) )
        ]


decodeGos : WebcamSettings -> Decoder Gos
decodeGos settings =
    Decode.map5 Gos
        (Decode.maybe (Decode.field "record" decodeRecord))
        (Decode.field "slides" (Decode.list decodeSlide))
        (Decode.field "events" (Decode.list decodeEvent))
        (Decode.map (Maybe.withDefault settings) <| Decode.maybe <| Decode.field "webcam_settings" decodeWebcamSettings)
        (Decode.field "fade" decodeFade)


type alias User =
    { username : String, role : Role }


decodeUser : Decoder User
decodeUser =
    Decode.map2 User
        (Decode.field "username" Decode.string)
        (Decode.field "role" decodeRole)


type alias Capsule =
    { id : String
    , name : String
    , project : String
    , role : Role
    , videoUploaded : TaskStatus
    , produced : TaskStatus
    , published : TaskStatus
    , privacy : Privacy
    , structure : List Gos
    , lastModified : Int
    , users : List User
    , promptSubtitles : Bool
    , diskUsage : Int
    , durationMs : Int
    }


decode : Decoder Capsule
decode =
    Decode.field "webcam_settings" decodeWebcamSettings
        |> Decode.andThen
            (\x ->
                Decode.succeed Capsule
                    |> andMap (Decode.field "id" Decode.string)
                    |> andMap (Decode.field "name" Decode.string)
                    |> andMap (Decode.field "project" Decode.string)
                    |> andMap (Decode.field "role" decodeRole)
                    |> andMap (Decode.field "video_uploaded" decodeTaskStatus)
                    |> andMap (Decode.field "produced" decodeTaskStatus)
                    |> andMap (Decode.field "published" decodeTaskStatus)
                    |> andMap (Decode.field "privacy" decodePrivacy)
                    |> andMap (Decode.field "structure" (Decode.list (decodeGos x)))
                    |> andMap (Decode.field "last_modified" Decode.int)
                    |> andMap (Decode.field "users" (Decode.list decodeUser))
                    |> andMap (Decode.field "prompt_subtitles" Decode.bool)
                    |> andMap (Decode.field "disk_usage" Decode.int)
                    |> andMap (Decode.field "duration_ms" Decode.int)
            )


encodeGos : Gos -> Encode.Value
encodeGos gos =
    Encode.object
        [ ( "record", encodeRecord gos.record )
        , ( "slides", Encode.list encodeSlide gos.slides )
        , ( "events", Encode.list encodeEvent gos.events )
        , ( "webcam_settings", encodeWebcamSettings gos.webcamSettings )
        , ( "fade", encodeFade gos.fade )
        ]


encodeStructure : List Gos -> Encode.Value
encodeStructure =
    Encode.list encodeGos


encode : Capsule -> Encode.Value
encode capsule =
    Encode.object
        [ ( "id", Encode.string capsule.id )
        , ( "project", Encode.string capsule.project )
        , ( "name", Encode.string capsule.name )
        , ( "privacy", encodePrivacy capsule.privacy )
        , ( "prompt_subtitles", Encode.bool capsule.promptSubtitles )
        , ( "structure", encodeStructure capsule.structure )
        , ( "webcam_settings", encodeWebcamSettings defaultWebcamSettings )
        ]


encodeAll : Capsule -> Encode.Value
encodeAll capsule =
    Encode.object
        [ ( "id", Encode.string capsule.id )
        , ( "project", Encode.string capsule.project )
        , ( "name", Encode.string capsule.name )
        , ( "privacy", encodePrivacy capsule.privacy )
        , ( "prompt_subtitles", Encode.bool capsule.promptSubtitles )
        , ( "structure", encodeStructure capsule.structure )
        , ( "produced", Encode.bool (capsule.produced == Done) )
        ]


firstNonRecordedGos : Capsule -> Maybe Int
firstNonRecordedGos capsule =
    capsule.structure
        |> List.indexedMap (\i c -> ( i, c ))
        |> List.Extra.find (\( _, x ) -> x.record == Nothing)
        |> Maybe.map Tuple.first


findSlide : String -> Capsule -> Maybe Slide
findSlide uuid capsule =
    findSlideAux uuid capsule.structure


findSlideAux : String -> List Gos -> Maybe Slide
findSlideAux uuid gos =
    case gos of
        h :: t ->
            case findSlideInGos uuid h.slides of
                Just s ->
                    Just s

                _ ->
                    findSlideAux uuid t

        [] ->
            Nothing


findSlideInGos : String -> List Slide -> Maybe Slide
findSlideInGos uuid slides =
    case slides of
        h :: t ->
            if h.uuid == uuid then
                Just h

            else
                findSlideInGos uuid t

        [] ->
            Nothing


changeSlide : Slide -> Capsule -> Capsule
changeSlide slide capsule =
    { capsule | structure = changeSlideAux slide capsule.structure }


changeSlideAux : Slide -> List Gos -> List Gos
changeSlideAux slide gos =
    List.map (\x -> { x | slides = changeSlideInGos slide x.slides }) gos


changeSlideInGos : Slide -> List Slide -> List Slide
changeSlideInGos slide gos =
    List.map
        (\x ->
            if x.uuid == slide.uuid then
                slide

            else
                x
        )
        gos


nextSlide : Slide -> Capsule -> Maybe Slide
nextSlide slide capsule =
    nextSlideAux slide capsule.structure


nextSlideAux : Slide -> List Gos -> Maybe Slide
nextSlideAux slide gos =
    case gos of
        h1 :: t ->
            case nextSlideInGos slide h1.slides of
                ( Just s, _ ) ->
                    Just s

                ( _, True ) ->
                    case t of
                        h2 :: _ ->
                            List.head h2.slides

                        _ ->
                            Nothing

                _ ->
                    nextSlideAux slide t

        _ ->
            Nothing


nextSlideInGos : Slide -> List Slide -> ( Maybe Slide, Bool )
nextSlideInGos slide input =
    case input of
        h1 :: h2 :: t ->
            if h1.uuid == slide.uuid then
                ( Just h2, False )

            else
                nextSlideInGos slide (h2 :: t)

        h1 :: [] ->
            ( Nothing, h1.uuid == slide.uuid )

        [] ->
            ( Nothing, False )


previousSlide : Slide -> Capsule -> Maybe Slide
previousSlide slide capsule =
    previousSlideAux slide capsule.structure


previousSlideAux : Slide -> List Gos -> Maybe Slide
previousSlideAux slide gos =
    case gos of
        h1 :: t ->
            case previousSlideInGos slide h1.slides of
                ( Just s, _ ) ->
                    Just s

                ( _, True ) ->
                    Nothing

                _ ->
                    case t of
                        h2 :: _ ->
                            case previousSlideInGos slide h2.slides of
                                ( Just s, _ ) ->
                                    Just s

                                ( _, True ) ->
                                    List.head (List.reverse h1.slides)

                                _ ->
                                    previousSlideAux slide t

                        _ ->
                            Nothing

        [] ->
            Nothing


previousSlideInGos : Slide -> List Slide -> ( Maybe Slide, Bool )
previousSlideInGos slide input =
    case input of
        h1 :: h2 :: t ->
            if h1.uuid == slide.uuid then
                ( Nothing, True )

            else if h2.uuid == slide.uuid then
                ( Just h1, False )

            else
                previousSlideInGos slide (h2 :: t)

        h1 :: _ ->
            ( Nothing, h1.uuid == slide.uuid )

        _ ->
            ( Nothing, False )


deleteSlide : String -> Capsule -> Capsule
deleteSlide uuid capsule =
    { capsule | structure = deleteSlideAux uuid capsule.structure }


deleteSlideAux : String -> List Gos -> List Gos
deleteSlideAux uuid input =
    List.map (\x -> { x | slides = deleteSlideInGos uuid x.slides }) input
        |> List.filter (\x -> not (List.isEmpty x.slides))


deleteSlideInGos : String -> List Slide -> List Slide
deleteSlideInGos uuid input =
    List.filter (\x -> x.uuid /= uuid) input


updateSlide : Slide -> Capsule -> Capsule
updateSlide slide capsule =
    { capsule | structure = updateSlideAux slide capsule.structure }


updateSlideAux : Slide -> List Gos -> List Gos
updateSlideAux slide input =
    List.map (\x -> { x | slides = updateSlideInGos slide x.slides }) input
        |> List.filter (\x -> not (List.isEmpty x.slides))


updateSlideInGos : Slide -> List Slide -> List Slide
updateSlideInGos slide input =
    List.map (\x -> tern (x.uuid == slide.uuid) slide x) input
