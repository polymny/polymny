port module Acquisition.Updates exposing
    ( update
    , subs
    )

{-| This module contains the update function for the preparation page.

@docs update

-}

import Acquisition.Types as Acquisition
import App.Types as App
import Config
import Data.Capsule as Data exposing (Capsule)
import Device
import Json.Decode as Decode
import Json.Encode as Encode
import Keyboard
import Route


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

                Acquisition.NextSentence ->
                    let
                        slides : List Data.Slide
                        slides =
                            List.drop m.gos m.capsule.structure
                                |> List.head
                                |> Maybe.map .slides
                                |> Maybe.withDefault []

                        currentSlide : Maybe Data.Slide
                        currentSlide =
                            List.head (List.drop m.currentSlide slides)

                        nextSlide : Maybe Data.Slide
                        nextSlide =
                            List.head (List.drop (m.currentSlide + 1) slides)

                        lineNumber : Int
                        lineNumber =
                            currentSlide
                                |> Maybe.map .prompt
                                |> Maybe.map (String.split "\n")
                                |> Maybe.map List.length
                                |> Maybe.withDefault 0
                    in
                    case ( ( m.currentSentence + 1 < lineNumber, nextSlide ), ( m.recording, m.state ) ) of
                        ( ( _, _ ), ( Nothing, Acquisition.Ready ) ) ->
                            -- If not recording, start recording (useful for remotes)
                            ( { model | page = App.Acquisition { m | recording = Just clientState.time, currentSlide = 0, currentSentence = 0 } }
                            , startRecording
                            )

                        ( ( _, _ ), ( Nothing, _ ) ) ->
                            -- If not recording but device is not ready, do nothing
                            ( model, Cmd.none )

                        ( ( True, _ ), ( Just _, _ ) ) ->
                            -- If there is another line, go to the next line
                            ( { model | page = App.Acquisition { m | currentSentence = m.currentSentence + 1 } }
                            , registerEvent Data.NextSentence
                            )

                        ( ( _, Just _ ), ( Just _, _ ) ) ->
                            -- If there is no other line but a next slide, go to the next slide
                            ( { model | page = App.Acquisition { m | currentSlide = m.currentSlide + 1, currentSentence = 0 } }
                            , registerEvent Data.NextSlide
                            )

                        ( ( _, _ ), ( Just _, _ ) ) ->
                            -- If recording and end reach, stop recording
                            ( { model | page = App.Acquisition { m | currentSlide = 0, currentSentence = 0, recording = Nothing } }
                            , stopRecording
                            )

                Acquisition.RecordArrived record ->
                    ( { model | page = App.Acquisition { m | records = record :: m.records } }, Cmd.none )

                Acquisition.UploadRecord record ->
                    let
                        task =
                            { task = Config.UploadRecord m.capsule.id m.gos (Acquisition.encodeRecord record)
                            , progress = Just 0.0
                            }

                        nextRoute =
                            if m.gos + 1 < List.length m.capsule.structure then
                                Route.Acquisition m.capsule.id (m.gos + 1)

                            else
                                Route.Home
                    in
                    ( { model | config = Config.addTask task model.config }
                    , Cmd.batch
                        [ uploadRecord m.capsule m.gos record
                        , Route.push model.config.clientState.key nextRoute
                        ]
                    )

        _ ->
            ( model, Cmd.none )


{-| Keyboard shortcuts of the acquisition page.
-}
shortcuts : Keyboard.RawKey -> App.Msg
shortcuts msg =
    case Keyboard.rawValue msg of
        "ArrowRight" ->
            App.AcquisitionMsg Acquisition.NextSentence

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


{-| Asks to play a specific record.
-}
playRecord : Acquisition.Record -> Cmd msg
playRecord record =
    playRecordPort (Acquisition.encodeRecord record)


{-| Port that starts the playing of a record.
-}
port playRecordPort : Encode.Value -> Cmd msg


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
