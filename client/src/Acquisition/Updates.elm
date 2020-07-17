module Acquisition.Updates exposing (update)

import Acquisition.Ports as Ports
import Acquisition.Types as Acquisition
import Api
import Core.Types as Core
import Edition.Types as Edition
import Edition.Views as Edition
import Json.Decode
import Log
import LoggedIn.Types as LoggedIn
import Preparation.Types as Preparation
import Status
import Utils
import Webcam


update : Api.Session -> Acquisition.Msg -> Acquisition.Model -> ( LoggedIn.Model, Cmd Core.Msg )
update session msg model =
    let
        makeModel : Acquisition.Model -> LoggedIn.Model
        makeModel m =
            { session = session, tab = LoggedIn.Acquisition m }
    in
    case msg of
        -- INNER MESSAGES
        Acquisition.CameraReady ->
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
            ( makeModel { model | recording = True, currentVideo = Just (List.length model.records), currentSlide = 0 }, cmd )

        Acquisition.StopRecording ->
            ( makeModel { model | recording = False }, Ports.stopRecording () )

        Acquisition.NewRecord n ->
            ( makeModel { model | records = Acquisition.newRecord (List.length model.records) n :: model.records }, Cmd.none )

        Acquisition.GoToWebcam ->
            case model.currentVideo of
                Just _ ->
                    ( makeModel model, Ports.goToWebcam elementId )

                Nothing ->
                    ( makeModel model, Cmd.none )

        Acquisition.GoToStream n ->
            case List.head (List.drop n (List.reverse model.records)) of
                Just { started, nextSlides } ->
                    ( makeModel { model | currentVideo = Just n, currentSlide = 0 }
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
                                    Acquisition.init model.details model.mode (model.gos + 1)
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
                ( makeModel { model | details = newDetails }
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
                            let
                                editionModel =
                                    Edition.selectEditionOptions session v.capsule (Edition.init v)
                            in
                            ( { session = session
                              , tab = LoggedIn.Edition { editionModel | status = Status.Sent }
                              }
                            , Api.editionAuto resultToMsg
                                editionModel.details.capsule.id
                                { withVideo = editionModel.withVideo
                                , webcamSize = editionModel.webcamSize
                                , webcamPosition = editionModel.webcamPosition
                                }
                            )

                        ( Ok v, Acquisition.All, False ) ->
                            let
                                ( m, c ) =
                                    Acquisition.init v model.mode (model.gos + 1)
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


elementId : String
elementId =
    "video"


resultToMsg : Result e Api.CapsuleDetails -> Core.Msg
resultToMsg result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <| LoggedIn.EditionMsg <| Edition.AutoSuccess x
        )
        (\_ -> Core.Noop)
        result
