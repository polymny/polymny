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


update : Api.Session -> Acquisition.Msg -> Acquisition.Model -> ( LoggedIn.Model, Cmd Core.Msg )
update session msg model =
    let
        makeModel : Acquisition.Model -> LoggedIn.Model
        makeModel m =
            { session = session, tab = LoggedIn.Acquisition m }
    in
    case msg of
        -- INNER MESSAGES
        Acquisition.StartRecording ->
            let
                cmd =
                    if model.currentStream == 0 then
                        Ports.startRecording ()

                    else
                        Cmd.batch [ Ports.goToStream ( elementId, 0, Nothing ), Ports.startRecording () ]
            in
            ( makeModel { model | recording = True, currentStream = 0, currentSlide = 0 }, cmd )

        Acquisition.StopRecording ->
            ( makeModel { model | recording = False }, Ports.stopRecording () )

        Acquisition.NewRecord n ->
            ( makeModel { model | records = Acquisition.newRecord n :: model.records }, Cmd.none )

        Acquisition.GoToStream n ->
            if model.currentStream == n && n == 0 then
                ( makeModel model, Cmd.none )

            else
                case List.head (List.drop (n - 1) (List.reverse model.records)) of
                    Just { started, nextSlides } ->
                        ( makeModel { model | currentStream = n, currentSlide = 0 }
                        , Ports.goToStream ( elementId, n, Just (List.map (\x -> x - started) nextSlides) )
                        )

                    _ ->
                        ( makeModel model, Cmd.none )

        Acquisition.UploadStream url stream ->
            let
                structure =
                    List.head (List.drop model.gos model.details.structure)

                transitions =
                    List.head (List.drop (stream - 1) model.records)

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
            , Cmd.batch [ Api.updateSlideStructure (\_ -> Core.Noop) newDetails, Ports.uploadStream ( url, stream ) ]
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
                            ( { session = session, tab = LoggedIn.Edition { status = Status.Sent, details = v } }
                            , Api.editionAuto resultToMsg model.details.capsule.id
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
