module Acquisition.Updates exposing (..)

import Acquisition.Ports as Ports
import Acquisition.Types as Acquisition
import Browser.Navigation as Nav
import Capsule
import Core.Ports as Ports
import Core.Types as Core
import Route
import Status
import User


update : Acquisition.Msg -> Core.Model -> ( Core.Model, Cmd Core.Msg )
update msg model =
    let
        { global } =
            model
    in
    case msg of
        Acquisition.Noop ->
            ( model, Cmd.none )

        Acquisition.DevicesReceived devices ->
            let
                newGlobal =
                    { global | devices = Just devices }

                ( page, cmd ) =
                    case model.page of
                        Core.Acquisition p ->
                            let
                                device =
                                    Acquisition.deviceFromIds devices global

                                newPage =
                                    { p | chosenDevice = device, state = Acquisition.BindingWebcam }

                                sub =
                                    Acquisition.toSubmodel devices newPage
                            in
                            ( Core.Acquisition newPage
                            , Acquisition.bindWebcam sub.chosenDevice
                            )

                        x ->
                            ( x, Cmd.none )
            in
            ( { model | global = newGlobal, page = page }, cmd )

        Acquisition.DeviceDetectionFailed ->
            case model.page of
                Core.Acquisition page ->
                    ( { model | page = Core.Acquisition { page | state = Acquisition.ErrorDetectingDevices } }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Acquisition.WebcamBindingFailed ->
            case model.page of
                Core.Acquisition page ->
                    ( { model | page = Core.Acquisition { page | state = Acquisition.ErrorBindingWebcam } }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Acquisition.WebcamBound ->
            case model.page of
                Core.Acquisition p ->
                    ( mkModel model (Core.Acquisition { p | webcamBound = True }), Ports.bindPointer () )

                _ ->
                    ( model, Cmd.none )

        Acquisition.PointerBound ->
            case model.page of
                Core.Acquisition p ->
                    ( mkModel model (Core.Acquisition { p | webcamBound = True }), Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Acquisition.InvertAcquisition ->
            let
                newGlobal =
                    { global | acquisitionInverted = not global.acquisitionInverted }
            in
            ( { model | global = newGlobal }, Ports.setAcquisitionInverted newGlobal.acquisitionInverted )

        Acquisition.StartRecording ->
            case model.page of
                Core.Acquisition p ->
                    ( mkModel model (Core.Acquisition { p | recording = True, currentSlide = 0, currentLine = 0 })
                    , Ports.startRecording ()
                    )

                _ ->
                    ( model, Cmd.none )

        Acquisition.StartPointerRecording record ->
            case model.page of
                Core.Acquisition p ->
                    ( mkModel model (Core.Acquisition { p | recording = True, currentSlide = 0, currentLine = 0 })
                    , Ports.startPointerRecording (Acquisition.encodeRecord record)
                    )

                _ ->
                    ( model, Cmd.none )

        Acquisition.StopRecording ->
            case model.page of
                Core.Acquisition p ->
                    ( mkModel model (Core.Acquisition { p | recording = False }), Ports.stopRecording () )

                _ ->
                    ( model, Cmd.none )

        Acquisition.RecordArrived record ->
            case model.page of
                Core.Acquisition p ->
                    ( mkModel model (Core.Acquisition { p | records = record :: p.records }), Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Acquisition.PointerRecordArrived record ->
            case model.page of
                Core.Acquisition p ->
                    let
                        updater : Acquisition.Record -> Acquisition.Record
                        updater old =
                            if old.webcamBlob == record.webcamBlob then
                                record

                            else
                                old

                        newRecords =
                            List.map updater p.records
                    in
                    ( mkModel model (Core.Acquisition { p | records = newRecords }), Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Acquisition.ToggleSettings ->
            case model.page of
                Core.Acquisition p ->
                    ( mkModel model (Core.Acquisition { p | showSettings = not p.showSettings }), Ports.playWebcam () )

                _ ->
                    ( model, Cmd.none )

        Acquisition.VideoDeviceChanged v ->
            case model.page of
                Core.Acquisition p ->
                    let
                        chosenDevice =
                            p.chosenDevice

                        resolution =
                            Maybe.andThen (\x -> List.head x.resolutions) v

                        newChosenDevice =
                            { chosenDevice | video = v, resolution = resolution }
                    in
                    ( mkModel
                        { model | global = Core.updateDevice newChosenDevice model.global }
                        (Core.Acquisition { p | chosenDevice = newChosenDevice })
                    , Cmd.batch
                        [ Acquisition.bindWebcam newChosenDevice
                        , Ports.setVideoDeviceId (v |> Maybe.map .deviceId |> Maybe.withDefault "disabled")
                        ]
                    )

                _ ->
                    ( model, Cmd.none )

        Acquisition.ResolutionChanged v ->
            case model.page of
                Core.Acquisition p ->
                    let
                        chosenDevice =
                            p.chosenDevice

                        newChosenDevice =
                            { chosenDevice | resolution = Just v }
                    in
                    ( mkModel
                        { model | global = Core.updateDevice newChosenDevice model.global }
                        (Core.Acquisition { p | chosenDevice = newChosenDevice })
                    , Cmd.batch
                        [ Acquisition.bindWebcam newChosenDevice
                        , Ports.setResolution (Acquisition.format v)
                        ]
                    )

                _ ->
                    ( model, Cmd.none )

        Acquisition.AudioDeviceChanged v ->
            case model.page of
                Core.Acquisition p ->
                    let
                        chosenDevice =
                            p.chosenDevice

                        newChosenDevice =
                            { chosenDevice | audio = Just v }
                    in
                    ( mkModel
                        { model | global = Core.updateDevice newChosenDevice model.global }
                        (Core.Acquisition { p | chosenDevice = newChosenDevice })
                    , Cmd.batch
                        [ Acquisition.bindWebcam newChosenDevice
                        , Ports.setAudioDeviceId v.deviceId
                        ]
                    )

                _ ->
                    ( model, Cmd.none )

        Acquisition.NextSentence ->
            case model.page of
                Core.Acquisition p ->
                    let
                        slides : List Capsule.Slide
                        slides =
                            List.drop p.gos p.capsule.structure
                                |> List.head
                                |> Maybe.map .slides
                                |> Maybe.withDefault []

                        currentSlide : Maybe Capsule.Slide
                        currentSlide =
                            List.head (List.drop p.currentSlide slides)

                        nextSlide : Maybe Capsule.Slide
                        nextSlide =
                            List.head (List.drop (p.currentSlide + 1) slides)

                        lineNumber =
                            case currentSlide of
                                Just j ->
                                    List.length (String.split "\n" j.prompt)

                                _ ->
                                    0
                    in
                    case ( p.currentLine + 1 < lineNumber, nextSlide, p.recording ) of
                        ( _, _, False ) ->
                            -- If not recording, start recording (useful for remotes)
                            ( mkModel model (Core.Acquisition { p | recording = True, currentSlide = 0, currentLine = 0 })
                            , Ports.startRecording ()
                            )

                        ( True, _, True ) ->
                            -- If there is another line, go to the next line
                            ( mkModel model (Core.Acquisition { p | currentLine = p.currentLine + 1 })
                            , Ports.askNextSentence ()
                            )

                        ( _, Just _, True ) ->
                            -- If there is no other line but a next slide, go to the next slide
                            ( mkModel model (Core.Acquisition { p | currentSlide = p.currentSlide + 1, currentLine = 0 })
                            , Ports.askNextSlide ()
                            )

                        ( _, _, True ) ->
                            -- If recording and end reach, stop recording
                            ( mkModel model (Core.Acquisition { p | currentSlide = 0, currentLine = 0, recording = False })
                            , Ports.stopRecording ()
                            )

                _ ->
                    ( model, Cmd.none )

        Acquisition.PlayRecord record ->
            case model.page of
                Core.Acquisition p ->
                    ( mkModel model (Core.Acquisition { p | currentSlide = 0, recordPlaying = Just record })
                    , Ports.playRecord (Acquisition.encodeRecord record)
                    )

                _ ->
                    ( model, Cmd.none )

        Acquisition.StopPlayingRecord ->
            case model.page of
                Core.Acquisition p ->
                    ( mkModel model (Core.Acquisition { p | currentSlide = 0, recordPlaying = Nothing })
                    , Ports.stopPlayingRecord ()
                    )

                _ ->
                    ( model, Cmd.none )

        Acquisition.NextSlideReceived ->
            case model.page of
                Core.Acquisition p ->
                    let
                        slides : List Capsule.Slide
                        slides =
                            List.drop p.gos p.capsule.structure
                                |> List.head
                                |> Maybe.map .slides
                                |> Maybe.withDefault []

                        nextSlide =
                            if p.currentSlide == List.length slides - 1 then
                                0

                            else
                                p.currentSlide + 1
                    in
                    ( mkModel model (Core.Acquisition { p | currentSlide = nextSlide }), Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Acquisition.PlayRecordFinished ->
            case model.page of
                Core.Acquisition p ->
                    ( mkModel model (Core.Acquisition { p | currentSlide = 0, recording = False, recordPlaying = Nothing }), Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Acquisition.UploadRecord record ->
            case model.page of
                Core.Acquisition p ->
                    ( mkModel model (Core.Acquisition { p | uploading = Just 0.0, status = Status.Sent })
                    , Ports.uploadRecord ( p.capsule.id, p.gos, Acquisition.encodeRecord record )
                    )

                _ ->
                    ( model, Cmd.none )

        Acquisition.UploadRecordFailed ->
            case model.page of
                Core.Acquisition p ->
                    ( mkModel model (Core.Acquisition { p | status = Status.Error, uploading = Nothing }), Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Acquisition.UploadRecordFailedAck ->
            case model.page of
                Core.Acquisition p ->
                    ( mkModel model (Core.Acquisition { p | status = Status.NotSent, uploading = Nothing }), Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Acquisition.CapsuleUpdated c ->
            let
                newUser =
                    case c of
                        Just ca ->
                            User.changeCapsule ca model.user

                        _ ->
                            model.user
            in
            case model.page of
                Core.Acquisition p ->
                    let
                        _ =
                            case c of
                                Just ca ->
                                    { p | capsule = ca }

                                _ ->
                                    p
                    in
                    -- Go to the next record if any, production otherwise
                    if p.gos + 1 < List.length p.capsule.structure then
                        ( { model | user = newUser }
                        , Nav.pushUrl model.global.key (Route.toUrl (Route.Acquisition p.capsule.id (p.gos + 1)))
                        )

                    else
                        ( { model | user = newUser }
                        , Nav.pushUrl model.global.key (Route.toUrl (Route.Production p.capsule.id 0))
                        )

                _ ->
                    ( { model | user = newUser }, Cmd.none )

        Acquisition.ProgressReceived progress ->
            case model.page of
                Core.Acquisition p ->
                    ( mkModel model (Core.Acquisition { p | uploading = Just progress })
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        Acquisition.RefreshDevices ->
            ( { model | global = { global | devices = Nothing } }, Ports.findDevices True )

        Acquisition.IncreasePromptSize ->
            let
                newSize =
                    global.promptSize + 5
            in
            ( { model | global = { global | promptSize = newSize } }, Ports.setPromptSize newSize )

        Acquisition.DecreasePromptSize ->
            let
                newSize =
                    global.promptSize - 5 |> max 10
            in
            ( { model | global = { global | promptSize = newSize } }, Ports.setPromptSize newSize )

        Acquisition.SetCanvas s ->
            ( model, Ports.setCanvas (Acquisition.encodeSetCanvas s) )


mkModel : Core.Model -> Core.Page -> Core.Model
mkModel input newPage =
    { input | page = newPage }
