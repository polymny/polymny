port module Acquisition.Updates exposing
    ( update
    , subs
    )

{-| This module contains the update function for the preparation page.

@docs update

-}

import Acquisition.Types as Acquisition
import Api.Capsule as Api
import App.Types as App
import App.Utils as App
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Config
import Data.Capsule as Data exposing (Capsule)
import Data.User as Data
import Device
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Keyboard
import Route
import Task
import Time
import Utils


{-| The update function of the preparation page.
-}
update : Acquisition.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    let
        clientConfig =
            model.config.clientConfig

        clientState =
            model.config.clientState

        ( maybeCapsule, maybeGos ) =
            App.capsuleAndGos model.user model.page
    in
    case ( model.page, maybeCapsule, maybeGos ) of
        ( App.Acquisition m, Just capsule, Just gos ) ->
            let
                { pointerStyle } =
                    m
            in
            case msg of
                Acquisition.RequestCameraPermission deviceId ->
                    ( { model | page = App.Acquisition { m | state = Acquisition.DetectingDevices } }, Device.detectDevices (Just deviceId) False )

                Acquisition.DeviceChanged ->
                    ( { model | page = App.Acquisition { m | state = Acquisition.BindingWebcam, deviceLevel = Nothing } }
                    , Device.bindDevice (Device.getDevice clientConfig.devices clientConfig.preferredDevice)
                    )

                Acquisition.DetectDevicesFinished ->
                    ( { model | page = App.Acquisition { m | state = Acquisition.BindingWebcam, deviceLevel = Nothing } }
                    , Device.bindDevice (Device.getDevice clientConfig.devices clientConfig.preferredDevice)
                    )

                Acquisition.DeviceBound ->
                    ( { model | page = App.Acquisition { m | state = Acquisition.Ready } }, Cmd.none )

                Acquisition.BindingDeviceFailed ->
                    ( { model | page = App.Acquisition { m | state = Acquisition.Error } }, Cmd.none )

                Acquisition.DeviceLevel x ->
                    ( { model | page = App.Acquisition { m | deviceLevel = Just x } }, Cmd.none )

                Acquisition.ToggleSettings ->
                    let
                        newState =
                            case m.state of
                                Acquisition.Error ->
                                    Acquisition.Error

                                _ ->
                                    m.state
                    in
                    ( { model | page = App.Acquisition { m | state = newState, showSettings = not m.showSettings } }
                    , Device.bindDevice (Device.getDevice clientConfig.devices clientConfig.preferredDevice)
                    )

                Acquisition.StartRecording ->
                    if m.state == Acquisition.Ready then
                        ( { model | page = App.Acquisition { m | recording = Just clientState.time, currentSlide = 0, currentSentence = 0 } }
                        , startRecording
                        )

                    else
                        ( model, Cmd.none )

                Acquisition.StartPointerRecording index record ->
                    if m.state == Acquisition.Ready then
                        ( { model | page = App.Acquisition { m | recording = Just clientState.time, currentSlide = 0, currentSentence = 0 } }
                        , startPointerRecording index record
                        )

                    else
                        ( model, Cmd.none )

                Acquisition.StopRecording ->
                    ( { model | page = App.Acquisition { m | recording = Nothing, currentSlide = 0, currentSentence = 0 } }
                    , stopRecording
                    )

                Acquisition.PointerRecordFinished ->
                    ( { model | page = App.Acquisition { m | recording = Nothing, currentSlide = 0, currentSentence = 0 } }
                    , Cmd.none
                    )

                Acquisition.PlayRecord ( index, record ) ->
                    ( { model | page = App.Acquisition { m | recordPlaying = Just ( index, record ), currentSlide = 0, currentSentence = 0 } }
                    , playRecord record
                    )

                Acquisition.StopRecord ->
                    ( { model | page = App.Acquisition { m | recordPlaying = Nothing } }
                    , stopRecord
                    )

                Acquisition.PlayRecordFinished ->
                    ( { model
                        | page =
                            App.Acquisition
                                { m
                                    | state = Acquisition.BindingWebcam
                                    , recordPlaying = Nothing
                                    , currentSlide = 0
                                    , currentSentence = 0
                                }
                      }
                    , Cmd.none
                    )

                Acquisition.CurrentSentenceChanged sentence ->
                    if String.contains "\n" sentence then
                        ( { model | page = App.Acquisition m }
                        , Task.attempt (\_ -> App.Noop) <| Dom.blur Acquisition.promptFirstSentenceId
                        )

                    else
                        ( { model | page = App.Acquisition { m | currentReplacementPrompt = Just sentence } }, Cmd.none )

                Acquisition.NextSentenceChanged sentence ->
                    if String.contains "\n" sentence then
                        ( { model | page = App.Acquisition m }
                        , Task.attempt (\_ -> App.Noop) <| Dom.blur Acquisition.promptSecondSentenceId
                        )

                    else
                        ( { model | page = App.Acquisition { m | nextReplacementPrompt = Just sentence } }, Cmd.none )

                Acquisition.PreviousSentence ->
                    ( { model | page = App.Acquisition { m | currentSentence = max (m.currentSentence - 1) 0 } }, Cmd.none )

                Acquisition.NextSentence shouldRecord ->
                    let
                        cancelCommand : Cmd msg -> Cmd msg
                        cancelCommand cmd =
                            if shouldRecord then
                                cmd

                            else
                                Cmd.none

                        cancelRecording : Maybe Time.Posix -> Maybe Time.Posix
                        cancelRecording input =
                            if shouldRecord then
                                input

                            else
                                m.recording

                        currentSlide : Maybe Data.Slide
                        currentSlide =
                            List.head (List.drop m.currentSlide gos.slides)

                        nextSlide : Maybe Data.Slide
                        nextSlide =
                            List.head (List.drop (m.currentSlide + 1) gos.slides)

                        lineNumber : Int
                        lineNumber =
                            currentSlide
                                |> Maybe.map .prompt
                                |> Maybe.map (String.split "\n")
                                |> Maybe.map List.length
                                |> Maybe.withDefault 0
                    in
                    case ( ( m.currentReplacementPrompt, m.nextReplacementPrompt ), ( m.currentSentence + 1 < lineNumber, nextSlide ), ( m.recording, m.state, shouldRecord ) ) of
                        ( ( Nothing, Nothing ), ( _, _ ), ( Nothing, Acquisition.Ready, True ) ) ->
                            -- If not recording, start recording (useful for remotes)
                            ( { model
                                | page =
                                    App.Acquisition
                                        { m
                                            | recording = Just clientState.time |> cancelRecording
                                            , currentSlide = 0
                                            , currentSentence = 0
                                        }
                              }
                            , startRecording |> cancelCommand
                            )

                        ( ( Nothing, Nothing ), ( _, _ ), ( Nothing, _, True ) ) ->
                            -- If not recording but device is not ready, do nothing
                            ( model, Cmd.none )

                        ( ( Nothing, Nothing ), ( True, _ ), ( _, _, _ ) ) ->
                            -- If there is another line, go to the next line
                            ( { model | page = App.Acquisition { m | currentSentence = m.currentSentence + 1 } }
                            , registerEvent Data.NextSentence |> cancelCommand
                            )

                        ( ( Nothing, Nothing ), ( _, Just _ ), ( _, _, _ ) ) ->
                            -- If there is no other line but a next slide, go to the next slide
                            ( { model | page = App.Acquisition { m | currentSlide = m.currentSlide + 1, currentSentence = 0 } }
                            , registerEvent Data.NextSlide |> cancelCommand
                            )

                        ( ( Nothing, Nothing ), ( _, _ ), ( _, _, _ ) ) ->
                            -- If recording and end reach, stop recording
                            ( { model
                                | page =
                                    App.Acquisition
                                        { m
                                            | currentSlide = 0
                                            , currentSentence = 0
                                            , recording = Nothing |> cancelRecording
                                        }
                              }
                            , stopRecording |> cancelCommand
                            )

                        ( ( Just _, _ ), _, _ ) ->
                            ( model, Cmd.none )

                        ( ( _, Just _ ), _, _ ) ->
                            ( model, Cmd.none )

                Acquisition.RecordArrived ( index, record ) ->
                    let
                        -- Updates a record if they share the same deviceBlob (pointerBlob has changed).
                        -- The bool indicates whether it changed or not
                        updater : ( Int, Acquisition.Record ) -> ( Acquisition.Record, Bool )
                        updater ( oldIndex, oldRecord ) =
                            if Just oldIndex == index then
                                ( record, True )

                            else
                                ( oldRecord, False )

                        updatedRecords =
                            List.map updater <| List.reverse <| List.indexedMap Tuple.pair <| List.reverse m.records

                        newRecords =
                            if List.any Tuple.second updatedRecords then
                                -- A record changed, so just return the updated value
                                updatedRecords |> List.map Tuple.first

                            else
                                -- No record changed, which means we received a new record, add it to the list
                                record :: m.records
                    in
                    ( { model | page = App.Acquisition { m | records = newRecords } }, Acquisition.clearPointer )

                Acquisition.UploadRecord record ->
                    let
                        task : Config.TaskStatus
                        task =
                            { task = Config.UploadRecord model.config.clientState.taskId m.capsule m.gos <| Acquisition.encodeRecord record
                            , progress = Just 0.0
                            , finished = False
                            , aborted = False
                            , global = True
                            }

                        nextRoute =
                            if m.gos + 1 < List.length capsule.structure then
                                Route.Acquisition m.capsule (m.gos + 1)

                            else
                                Route.Production m.capsule 0

                        ( newConfig, _ ) =
                            Config.update (Config.UpdateTaskStatus task) model.config
                    in
                    ( { model
                        | config = Config.incrementTaskId newConfig

                        -- Whoever is reading this code, I'm sorry
                        -- When we validate the last record of a capsule, we want to move to the production
                        -- page, but the App/Updates.elm will detect that we're trying to change page while we
                        -- still have non validated records, which would trigger the warn leaving popup.
                        -- We hard remove the records here to prevent that.
                        , page = App.Acquisition { m | records = [] }
                      }
                    , Cmd.batch
                        [ uploadRecord capsule m.gos record model.config.clientState.taskId
                        , Route.push model.config.clientState.key nextRoute
                        ]
                    )

                Acquisition.DeleteRecord Utils.Request ->
                    ( { model | page = App.Acquisition { m | deleteRecord = True } }, Cmd.none )

                Acquisition.DeleteRecord Utils.Cancel ->
                    ( { model | page = App.Acquisition { m | deleteRecord = False } }, Cmd.none )

                Acquisition.DeleteRecord Utils.Confirm ->
                    let
                        newGos =
                            { gos | events = [], record = Nothing }

                        newCapsule =
                            Data.updateGos m.gos newGos capsule
                    in
                    ( { model
                        | page =
                            App.Acquisition
                                { m
                                    | deleteRecord = False
                                    , savedRecord = Nothing
                                    , records = List.filter (\r -> not r.old) m.records
                                }
                        , user = Data.updateUser newCapsule model.user
                      }
                    , Api.deleteRecord capsule m.gos (\_ -> App.Noop)
                    )

                Acquisition.EscapePressed ->
                    ( { model | page = App.Acquisition { m | deleteRecord = False } }
                    , Cmd.none
                    )

                Acquisition.SetPointerMode newMode ->
                    let
                        newPointerStyle =
                            { pointerStyle | mode = newMode }
                    in
                    ( { model | page = App.Acquisition { m | pointerStyle = newPointerStyle } }
                    , Acquisition.setPointerStyle newPointerStyle
                    )

                Acquisition.SetPointerColor newColor ->
                    let
                        newPointerStyle =
                            { pointerStyle | color = newColor }
                    in
                    ( { model | page = App.Acquisition { m | pointerStyle = newPointerStyle } }
                    , Acquisition.setPointerStyle newPointerStyle
                    )

                Acquisition.SetPointerSize newSize ->
                    let
                        newPointerStyle =
                            { pointerStyle | size = newSize |> min 20 |> max 5 }
                    in
                    ( { model | page = App.Acquisition { m | pointerStyle = newPointerStyle } }
                    , Acquisition.setPointerStyle newPointerStyle
                    )

                Acquisition.ClearPointer ->
                    ( model, Acquisition.clearPointer )

                Acquisition.Leave Utils.Cancel ->
                    ( { model | page = App.Acquisition { m | warnLeaving = Nothing } }
                    , Maybe.map (\x -> Nav.back x 1) model.config.clientState.key |> Maybe.withDefault Cmd.none
                    )

                Acquisition.Leave Utils.Confirm ->
                    ( model
                    , m.warnLeaving |> Maybe.map (Route.push model.config.clientState.key) |> Maybe.withDefault Cmd.none
                    )

                Acquisition.Leave _ ->
                    ( model, Cmd.none )

                Acquisition.StartEditingPrompt ->
                    let
                        currentSlide : Maybe Data.Slide
                        currentSlide =
                            List.head (List.drop m.currentSlide gos.slides)

                        line =
                            currentSlide
                                |> Maybe.map .prompt
                                |> Maybe.withDefault ""
                                |> String.split "\n"
                                |> List.drop m.currentSentence
                                |> List.head
                    in
                    ( { model | page = App.Acquisition { m | currentReplacementPrompt = line } }, Cmd.none )

                Acquisition.StopEditingPrompt ->
                    let
                        realSentence =
                            m.currentReplacementPrompt |> Maybe.withDefault "" |> String.replace "\n" "" |> String.trim

                        currentSlide : Maybe Data.Slide
                        currentSlide =
                            List.head (List.drop m.currentSlide gos.slides)

                        newPrompt : Maybe String
                        newPrompt =
                            case currentSlide of
                                Just s ->
                                    let
                                        split =
                                            String.split "\n" s.prompt

                                        splitReplaced =
                                            List.take m.currentSentence split
                                                ++ (realSentence :: List.drop (m.currentSentence + 1) split)
                                    in
                                    Just <| String.join "\n" splitReplaced

                                _ ->
                                    Nothing

                        newCapsule =
                            case ( currentSlide, newPrompt ) of
                                ( Just s, Just p ) ->
                                    Data.updateSlide { s | prompt = p } capsule

                                _ ->
                                    capsule
                    in
                    ( { model
                        | user = Data.updateUser newCapsule model.user
                        , page = App.Acquisition { m | currentReplacementPrompt = Nothing }
                      }
                    , Api.updateCapsule newCapsule (\_ -> App.Noop)
                    )

                Acquisition.StartEditingSecondPrompt ->
                    let
                        currentSlide : Maybe Data.Slide
                        currentSlide =
                            List.head (List.drop m.currentSlide gos.slides)

                        ( sentenceToChange, slideToChange ) =
                            let
                                promptLength =
                                    Maybe.map .prompt currentSlide |> Maybe.withDefault "" |> String.split "\n" |> List.length
                            in
                            if m.currentSentence >= promptLength - 1 then
                                ( 0, List.head (List.drop (m.currentSlide + 1) gos.slides) )

                            else
                                ( m.currentSentence + 1, currentSlide )

                        line =
                            slideToChange
                                |> Maybe.map .prompt
                                |> Maybe.withDefault ""
                                |> String.split "\n"
                                |> List.drop sentenceToChange
                                |> List.head
                    in
                    ( { model | page = App.Acquisition { m | nextReplacementPrompt = line } }, Cmd.none )

                Acquisition.StopEditingSecondPrompt ->
                    let
                        realSentence =
                            m.nextReplacementPrompt
                                |> Maybe.withDefault ""
                                |> String.replace "\n" ""
                                |> String.trim

                        currentSlide : Maybe Data.Slide
                        currentSlide =
                            List.head (List.drop m.currentSlide gos.slides)

                        ( sentenceToChange, slideToChange ) =
                            let
                                promptLength =
                                    Maybe.map .prompt currentSlide |> Maybe.withDefault "" |> String.split "\n" |> List.length
                            in
                            if m.currentSentence >= promptLength - 1 then
                                ( 0, List.head (List.drop (m.currentSlide + 1) gos.slides) )

                            else
                                ( m.currentSentence + 1, currentSlide )

                        newPrompt : Maybe String
                        newPrompt =
                            case slideToChange of
                                Just s ->
                                    let
                                        split =
                                            String.split "\n" s.prompt

                                        splitReplaced =
                                            List.take sentenceToChange split
                                                ++ (realSentence :: List.drop (sentenceToChange + 1) split)
                                    in
                                    Just <| String.join "\n" splitReplaced

                                _ ->
                                    Nothing

                        newCapsule =
                            case ( slideToChange, newPrompt ) of
                                ( Just s, Just p ) ->
                                    Data.updateSlide { s | prompt = p } capsule

                                _ ->
                                    capsule
                    in
                    ( { model
                        | user = Data.updateUser newCapsule model.user
                        , page = App.Acquisition { m | nextReplacementPrompt = Nothing }
                      }
                    , Api.updateCapsule newCapsule (\_ -> App.Noop)
                    )

                Acquisition.ToggleHelp ->
                    ( { model | page = App.Acquisition { m | showHelp = not m.showHelp } }, Cmd.none )

                Acquisition.ReinitializeDevices ->
                    let
                        ( newConfig, cmd ) =
                            Config.update Config.ReinitializeDevices model.config
                    in
                    ( { model
                        | page = App.Acquisition { m | showSettings = False, state = Acquisition.DetectingDevices }
                        , config = newConfig
                      }
                    , Cmd.map App.ConfigMsg cmd
                    )

        _ ->
            ( model, Cmd.none )


{-| Keyboard shortcuts of the acquisition page.
-}
shortcuts : Keyboard.RawKey -> App.Msg
shortcuts msg =
    case Keyboard.rawValue msg of
        "ArrowRight" ->
            App.AcquisitionMsg <| Acquisition.NextSentence True

        "Escape" ->
            App.AcquisitionMsg <| Acquisition.EscapePressed

        _ ->
            App.Noop


{-| Helper to decode [Int, Record].
-}
decodeRecordWithIndex : Decoder ( Maybe Int, Acquisition.Record )
decodeRecordWithIndex =
    Decode.map2 Tuple.pair
        (Decode.index 0 <| Decode.nullable Decode.int)
        (Decode.index 1 <| Acquisition.decodeRecord)


{-| The subscriptions needed for the page to work.
-}
subs : Acquisition.Model String Int -> Sub App.Msg
subs _ =
    Sub.batch
        [ detectDevicesFinished (\_ -> App.AcquisitionMsg Acquisition.DetectDevicesFinished)
        , deviceBound (\_ -> App.AcquisitionMsg Acquisition.DeviceBound)
        , bindingDeviceFailed (\_ -> App.AcquisitionMsg Acquisition.BindingDeviceFailed)
        , deviceLevel (\x -> App.AcquisitionMsg (Acquisition.DeviceLevel x))
        , playRecordFinished (\_ -> App.AcquisitionMsg Acquisition.PlayRecordFinished)
        , recordPointerFinished (\_ -> App.AcquisitionMsg Acquisition.PointerRecordFinished)
        , nextSentenceReceived (\_ -> App.AcquisitionMsg <| Acquisition.NextSentence False)
        , recordArrived <|
            \x ->
                case Decode.decodeValue decodeRecordWithIndex x of
                    Ok ( index, record ) ->
                        App.AcquisitionMsg <| Acquisition.RecordArrived ( index, record )

                    _ ->
                        App.Noop
        , Keyboard.ups shortcuts
        ]


{-| The detection of devices asked by elm is finished.
-}
port detectDevicesFinished : (() -> msg) -> Sub msg


{-| The device binding is finished.
-}
port deviceBound : (() -> msg) -> Sub msg


{-| The device make a specific amount of sound.
-}
port deviceLevel : (Float -> msg) -> Sub msg


{-| Registers a specific event that occured during the record.

This should only be used for NextSlide and NextSentence because the other case are directly managed by javascript.

-}
registerEvent : Data.EventType -> Cmd msg
registerEvent event =
    registerEventPort (Data.eventTypeToString event)


{-| Port that registers a specific event that occured during the record.
-}
port registerEventPort : String -> Cmd msg


{-| Starts the recording.
-}
startRecording : Cmd msg
startRecording =
    startRecordingPort ()


{-| Port that starts the recording.
-}
port startRecordingPort : () -> Cmd msg


{-| Starts the recording of the pointer.
-}
startPointerRecording : Int -> Acquisition.Record -> Cmd msg
startPointerRecording index record =
    startPointerRecordingPort ( index, Acquisition.encodeRecord record )


{-| Port that starts the recording of the pointer.
-}
port startPointerRecordingPort : ( Int, Encode.Value ) -> Cmd msg


{-| Stops the recording.
-}
stopRecording : Cmd msg
stopRecording =
    stopRecordingPort ()


{-| Port that stops the recording.
-}
port stopRecordingPort : () -> Cmd msg


{-| Receives the record when they're finished.
-}
port recordArrived : (Decode.Value -> msg) -> Sub msg


{-| Asks to play a specific record.
-}
playRecord : Acquisition.Record -> Cmd msg
playRecord record =
    playRecordPort (Acquisition.encodeRecord record)


{-| Port that starts the playing of a record.
-}
port playRecordPort : Encode.Value -> Cmd msg


{-| Asks to stop playing record.
-}
stopRecord : Cmd msg
stopRecord =
    stopRecordPort ()


{-| Port that stops the playing of the record.
-}
port stopRecordPort : () -> Cmd msg


{-| Sub to know when the playing of a record is finished.
-}
port playRecordFinished : (() -> msg) -> Sub msg


{-| Sub to know when the recording of a pointer is finished.
-}
port recordPointerFinished : (() -> msg) -> Sub msg


{-| Uploadds a record to the server.
-}
uploadRecord : Capsule -> Int -> Acquisition.Record -> Config.TaskId -> Cmd msg
uploadRecord capsule gos record taskId =
    uploadRecordPort ( ( capsule.id, gos ), ( Acquisition.encodeRecord record, taskId ) )


{-| Port to upload a record.
-}
port uploadRecordPort : ( ( String, Int ), ( Encode.Value, Config.TaskId ) ) -> Cmd msg


{-| Sub for when the js asks to go to the next sentence.
-}
port nextSentenceReceived : (() -> msg) -> Sub msg


{-| Sub for when there is an error while binding the device.
-}
port bindingDeviceFailed : (() -> msg) -> Sub msg
