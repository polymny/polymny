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
import Config
import Data.Capsule as Data exposing (Capsule)
import Data.User as Data
import Device
import Json.Decode as Decode
import Json.Encode as Encode
import Keyboard
import Route
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
    in
    case model.page of
        App.Acquisition m ->
            let
                { pointerStyle, gos } =
                    m
            in
            case msg of
                Acquisition.RequestCameraPermission deviceId ->
                    ( { model | page = App.Acquisition { m | state = Acquisition.DetectingDevices } }, Device.detectDevices (Just deviceId) )

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

                Acquisition.DeviceLevel x ->
                    ( { model | page = App.Acquisition { m | deviceLevel = Just x } }, Cmd.none )

                Acquisition.ToggleSettings ->
                    ( { model | page = App.Acquisition { m | state = Acquisition.BindingWebcam, showSettings = not m.showSettings } }
                    , Device.bindDevice (Device.getDevice clientConfig.devices clientConfig.preferredDevice)
                    )

                Acquisition.StartRecording ->
                    if m.state == Acquisition.Ready then
                        ( { model | page = App.Acquisition { m | recording = Just clientState.time, currentSlide = 0, currentSentence = 0 } }
                        , startRecording
                        )

                    else
                        ( model, Cmd.none )

                Acquisition.StopRecording ->
                    ( { model | page = App.Acquisition { m | recording = Nothing, currentSlide = 0, currentSentence = 0 } }
                    , stopRecording
                    )

                Acquisition.PlayRecord record ->
                    ( { model | page = App.Acquisition { m | recordPlaying = Just record, currentSlide = 0, currentSentence = 0 } }
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
                    let
                        currentSlide : Maybe Data.Slide
                        currentSlide =
                            List.head (List.drop m.currentSlide m.gos.slides)

                        newPrompt : Maybe String
                        newPrompt =
                            case currentSlide of
                                Just s ->
                                    let
                                        split =
                                            String.split "\n" s.prompt

                                        splitReplaced =
                                            List.take m.currentSentence split
                                                ++ (sentence :: List.drop (m.currentSentence + 1) split)
                                    in
                                    Just <| String.join "\n" splitReplaced

                                _ ->
                                    Nothing

                        ( newGos, newCapsule ) =
                            case ( currentSlide, newPrompt ) of
                                ( Just s, Just p ) ->
                                    ( Data.updateSlideInGos { s | prompt = p } m.gos
                                    , Data.updateSlide { s | prompt = p } m.capsule
                                    )

                                _ ->
                                    ( m.gos, m.capsule )
                    in
                    ( { model | page = App.Acquisition { m | gos = newGos, capsule = newCapsule } }
                    , Api.updateCapsule newCapsule (\_ -> App.Noop)
                    )

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
                            List.head (List.drop m.currentSlide m.gos.slides)

                        nextSlide : Maybe Data.Slide
                        nextSlide =
                            List.head (List.drop (m.currentSlide + 1) m.gos.slides)

                        lineNumber : Int
                        lineNumber =
                            currentSlide
                                |> Maybe.map .prompt
                                |> Maybe.map (String.split "\n")
                                |> Maybe.map List.length
                                |> Maybe.withDefault 0
                    in
                    case ( ( m.currentSentence + 1 < lineNumber, nextSlide ), ( m.recording, m.state, shouldRecord ) ) of
                        ( ( _, _ ), ( Nothing, Acquisition.Ready, True ) ) ->
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

                        ( ( _, _ ), ( Nothing, _, True ) ) ->
                            -- If not recording but device is not ready, do nothing
                            ( model, Cmd.none )

                        ( ( True, _ ), ( _, _, _ ) ) ->
                            -- If there is another line, go to the next line
                            ( { model | page = App.Acquisition { m | currentSentence = m.currentSentence + 1 } }
                            , registerEvent Data.NextSentence |> cancelCommand
                            )

                        ( ( _, Just _ ), ( _, _, _ ) ) ->
                            -- If there is no other line but a next slide, go to the next slide
                            ( { model | page = App.Acquisition { m | currentSlide = m.currentSlide + 1, currentSentence = 0 } }
                            , registerEvent Data.NextSlide |> cancelCommand
                            )

                        ( ( _, _ ), ( _, _, _ ) ) ->
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

                Acquisition.RecordArrived record ->
                    let
                        -- Updates a record if they share the same deviceBlob (pointerBlob has changed).
                        -- The bool indicates whether it changed or not
                        updater : Acquisition.Record -> ( Acquisition.Record, Bool )
                        updater old =
                            if old.deviceBlob == record.deviceBlob then
                                ( Debug.log "changed" record, True )

                            else
                                ( old, False )

                        updatedRecords =
                            List.map updater m.records

                        newRecords =
                            if List.any Tuple.second updatedRecords then
                                -- A record changed, so just return the updated value
                                updatedRecords |> List.map Tuple.first

                            else
                                -- No record changed, which means we received a new record, add it to the list
                                Debug.log "new" record :: m.records
                    in
                    ( { model | page = App.Acquisition { m | records = newRecords } }, Cmd.none )

                Acquisition.UploadRecord record ->
                    let
                        task : Config.TaskStatus
                        task =
                            { task = Config.ClientTask <| Config.UploadRecord m.capsule.id m.gosId <| Acquisition.encodeRecord record
                            , progress = Just 0.0
                            , finished = False
                            , aborted = False
                            }

                        nextRoute : Route.Route
                        nextRoute =
                            if m.gosId + 1 < List.length m.capsule.structure then
                                Route.Acquisition m.capsule.id (m.gosId + 1)

                            else
                                Route.Production m.capsule.id 0

                        ( newConfig, _ ) =
                            Config.update (Config.UpdateTaskStatus task) model.config
                    in
                    ( { model | config = newConfig }
                    , Cmd.batch
                        [ uploadRecord m.capsule m.gosId record
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
                            Data.updateGos m.gosId newGos m.capsule
                    in
                    ( { model
                        | page =
                            App.Acquisition
                                { m
                                    | deleteRecord = False
                                    , savedRecord = Nothing
                                    , gos = newGos
                                    , capsule = newCapsule
                                    , records = List.filter (\r -> not r.old) m.records
                                }
                        , user = Data.updateUser newCapsule model.user
                      }
                    , Api.deleteRecord m.capsule m.gosId (\_ -> App.Noop)
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


{-| The subscriptions needed for the page to work.
-}
subs : Acquisition.Model -> Sub App.Msg
subs model =
    Sub.batch
        [ detectDevicesFinished (\_ -> App.AcquisitionMsg Acquisition.DetectDevicesFinished)
        , deviceBound (\_ -> App.AcquisitionMsg Acquisition.DeviceBound)
        , deviceLevel (\x -> App.AcquisitionMsg (Acquisition.DeviceLevel x))
        , playRecordFinished (\_ -> App.AcquisitionMsg Acquisition.PlayRecordFinished)
        , recordArrived <|
            \x ->
                case Decode.decodeValue Acquisition.decodeRecord x of
                    Ok record ->
                        App.AcquisitionMsg <| Acquisition.RecordArrived record

                    _ ->
                        App.Noop
        , pointerRecordArrived <|
            \x ->
                case Decode.decodeValue Acquisition.decodeRecord x of
                    Ok record ->
                        App.AcquisitionMsg <| Acquisition.RecordArrived record

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


{-| Received a record as well as a pointer video.
-}
port pointerRecordArrived : (Decode.Value -> msg) -> Sub msg


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


{-| Uploadds a record to the server.
-}
uploadRecord : Capsule -> Int -> Acquisition.Record -> Cmd msg
uploadRecord capsule gos record =
    uploadRecordPort ( capsule.id, gos, Acquisition.encodeRecord record )


{-| Port to upload a record.
-}
port uploadRecordPort : ( String, Int, Encode.Value ) -> Cmd msg
