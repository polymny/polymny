module Acquisition.Updates exposing (update)

import Acquisition.Ports as Ports
import Acquisition.Types as Acquisition
import Acquisition.Views as Acquisition
import Api
import Core.Types as Core
import Dropdown
import Edition.Types as Edition
import Edition.Views as Edition
import Json.Decode
import Log
import LoggedIn.Types as LoggedIn
import Preparation.Types as Preparation
import Status


update : Core.Global -> Api.Session -> Acquisition.Msg -> Acquisition.Model -> ( LoggedIn.Model, Cmd Core.Msg )
update global session msg model =
    let
        makeModel : Acquisition.Model -> LoggedIn.Model
        makeModel m =
            { session = session, tab = LoggedIn.Acquisition m }
    in
    case msg of
        -- INNER MESSAGES
        Acquisition.CameraReady value ->
            case Json.Decode.decodeValue Acquisition.decodeDevices value of
                Ok v ->
                    ( makeModel { model | cameraReady = True, devices = v }, Cmd.none )

                Err _ ->
                    ( makeModel { model | cameraReady = True }, Cmd.none )

        Acquisition.StartRecording ->
            let
                cmd =
                    case model.currentVideo of
                        Just _ ->
                            Cmd.batch [ Ports.goToWebcam elementId, Ports.startRecording () ]

                        Nothing ->
                            Ports.startRecording ()
            in
            ( makeModel
                { model
                    | recording = True
                    , currentVideo = Just (List.length model.records)
                    , currentSlide = 0
                    , currentLine = 0
                }
            , cmd
            )

        Acquisition.ToggleSettings ->
            let
                newSettings =
                    case model.showSettings of
                        Just _ ->
                            Nothing

                        _ ->
                            Just ( Dropdown.init "", Dropdown.init "" )
            in
            ( makeModel { model | showSettings = newSettings }, Ports.goToWebcam elementId )

        Acquisition.VideoDropdownMsg vdMsg ->
            case model.showSettings of
                Just ( videoDropdown, audioDropdown ) ->
                    let
                        ( newModel, newCmd ) =
                            Dropdown.update Acquisition.videoDropdownConfig vdMsg videoDropdown model.devices.video
                    in
                    ( makeModel { model | showSettings = Just ( newModel, audioDropdown ) }, newCmd )

                _ ->
                    ( makeModel model, Cmd.none )

        Acquisition.VideoOptionPicked voMsg ->
            case voMsg of
                Just device ->
                    ( makeModel model, Ports.setVideoDevice ( device.deviceId, elementId ) )

                _ ->
                    ( makeModel model, Cmd.none )

        Acquisition.AudioDropdownMsg adMsg ->
            case model.showSettings of
                Just ( videoDropdown, audioDropdown ) ->
                    let
                        ( newModel, newCmd ) =
                            Dropdown.update Acquisition.audioDropdownConfig adMsg audioDropdown model.devices.audio
                    in
                    ( makeModel { model | showSettings = Just ( videoDropdown, newModel ) }, newCmd )

                _ ->
                    ( makeModel model, Cmd.none )

        Acquisition.AudioOptionPicked aoMsg ->
            case aoMsg of
                Just device ->
                    ( makeModel model, Ports.setAudioDevice ( device.deviceId, elementId ) )

                _ ->
                    ( makeModel model, Cmd.none )

        Acquisition.StopRecording ->
            ( makeModel { model | recording = False }, Ports.stopRecording () )

        Acquisition.NewRecord n ->
            ( makeModel { model | records = Acquisition.newRecord (List.length model.records) n :: model.records }, Cmd.none )

        Acquisition.GoToWebcam ->
            case model.currentVideo of
                Just _ ->
                    ( makeModel { model | watchingWebcam = True }, Ports.goToWebcam elementId )

                Nothing ->
                    ( makeModel model, Cmd.none )

        Acquisition.GoToStream n ->
            case List.head (List.drop n (List.reverse model.records)) of
                Just { started, nextSlides } ->
                    ( makeModel { model | currentVideo = Just n, currentSlide = 0, watchingWebcam = False }
                    , Ports.goToStream ( elementId, n, Just (List.map (\x -> x - started) nextSlides) )
                    )

                _ ->
                    ( makeModel model, Cmd.none )

        Acquisition.UploadStream url stream ->
            let
                transitions =
                    List.head (List.drop stream (List.reverse model.records))

                isNew =
                    case transitions of
                        Just { new } ->
                            new

                        _ ->
                            False
            in
            if not isNew then
                case model.mode of
                    Acquisition.Single ->
                        ( { session = session, tab = LoggedIn.Preparation (Preparation.init model.details) }, Cmd.none )

                    Acquisition.All ->
                        if model.gos + 1 == List.length model.details.structure then
                            ( { session = session, tab = LoggedIn.Preparation (Preparation.init model.details) }, Cmd.none )

                        else
                            let
                                ( m, cmd ) =
                                    Acquisition.init global.mattingEnabled model.details model.mode (model.gos + 1)
                            in
                            ( makeModel m, cmd |> Cmd.map LoggedIn.AcquisitionMsg |> Cmd.map Core.LoggedInMsg )

            else
                let
                    structure =
                        List.head (List.drop model.gos model.details.structure)

                    newTransitions =
                        case ( structure, transitions ) of
                            ( Just s, Just { started, nextSlides } ) ->
                                Just { s | transitions = List.reverse (List.map (\x -> x - started) nextSlides) }

                            _ ->
                                Nothing

                    newStructure =
                        case newTransitions of
                            Just y ->
                                List.take model.gos model.details.structure ++ (y :: List.drop (model.gos + 1) model.details.structure)

                            _ ->
                                model.details.structure

                    details =
                        model.details

                    newDetails =
                        { details | structure = newStructure }
                in
                ( makeModel { model | details = newDetails, status = Status.Sent }
                , Ports.uploadStream ( url, stream, Api.encodeSlideStructure newDetails )
                )

        Acquisition.StreamUploaded value ->
            let
                ( newModel, newCmd ) =
                    case
                        ( Json.Decode.decodeValue Api.decodeCapsuleDetails value
                        , model.mode
                        , model.gos + 1 == List.length model.details.structure
                        )
                    of
                        ( Ok v, Acquisition.Single, _ ) ->
                            ( { session = session, tab = LoggedIn.Preparation (Preparation.init v) }
                            , Cmd.none
                            )

                        ( Ok v, Acquisition.All, True ) ->
                            ( { session = session
                              , tab = LoggedIn.Edition (Edition.init v)
                              }
                            , Cmd.none
                            )

                        ( Ok v, Acquisition.All, False ) ->
                            let
                                ( m, c ) =
                                    Acquisition.init global.mattingEnabled v model.mode (model.gos + 1)
                            in
                            ( makeModel m, c |> Cmd.map LoggedIn.AcquisitionMsg |> Cmd.map Core.LoggedInMsg )

                        ( Err e, _, _ ) ->
                            let
                                _ =
                                    Log.debug "Error decoding capsule details" e
                            in
                            ( makeModel model, Cmd.none )
            in
            ( newModel, newCmd )

        Acquisition.NextSlide record ->
            if model.currentSlide + 1 >= List.length (Maybe.withDefault [] model.slides) then
                ( makeModel model, Cmd.none )

            else
                ( makeModel { model | currentSlide = model.currentSlide + 1 }
                , if record then
                    Ports.askNextSlide ()

                  else
                    Cmd.none
                )

        Acquisition.NextSlideReceived time ->
            let
                records =
                    case model.records of
                        h :: t ->
                            { h | nextSlides = time :: h.nextSlides } :: t

                        t ->
                            t
            in
            ( makeModel { model | records = records }, Cmd.none )

        Acquisition.CaptureBackground ->
            ( makeModel model, Ports.captureBackground elementId )

        Acquisition.SecondsRemaining n ->
            if n == 0 then
                ( makeModel { model | secondsRemaining = Nothing }, Cmd.none )

            else
                ( makeModel { model | secondsRemaining = Just n }, Cmd.none )

        Acquisition.BackgroundCaptured u ->
            ( makeModel { model | background = Just u }, Cmd.none )

        Acquisition.NextSentence ->
            let
                currentSlide : Maybe Api.Slide
                currentSlide =
                    List.head (List.drop model.currentSlide (Maybe.withDefault [] model.slides))

                nextSlide : Maybe Api.Slide
                nextSlide =
                    List.head (List.drop (model.currentSlide + 1) (Maybe.withDefault [] model.slides))

                lineNumber =
                    case currentSlide of
                        Just j ->
                            List.length (String.split "\n" j.prompt)

                        _ ->
                            0
            in
            case ( model.currentLine + 1 < lineNumber, nextSlide, model.recording ) of
                ( True, _, _ ) ->
                    -- If there is another line, go to the next line
                    ( makeModel { model | currentLine = model.currentLine + 1 }, Cmd.none )

                ( _, Just _, True ) ->
                    -- If there is no other line but a next slide, go to the next slide
                    ( makeModel { model | currentSlide = model.currentSlide + 1, currentLine = 0 }
                    , Ports.askNextSlide ()
                    )

                ( _, Just _, False ) ->
                    ( makeModel { model | currentSlide = model.currentSlide + 1, currentLine = 0 }
                    , Cmd.none
                    )

                ( _, _, True ) ->
                    -- If recording and end reach, stop recording
                    ( makeModel { model | currentSlide = 0, currentLine = 0, recording = False }, Ports.stopRecording () )

                ( _, _, _ ) ->
                    -- Otherwise, go back to begining
                    ( makeModel { model | currentSlide = 0, currentLine = 0 }, Cmd.none )


elementId : String
elementId =
    "video"
