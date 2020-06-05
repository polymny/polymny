module Acquisition.Updates exposing (update)

import Acquisition.Ports as Ports
import Acquisition.Types as Acquisition
import Api
import Capsule.Types as Capsule
import Core.Types as Core
import Json.Decode
import Log
import LoggedIn.Types as LoggedIn
import Preparation.Types as Preparation


update : Api.Session -> Acquisition.Msg -> Acquisition.Model -> ( LoggedIn.Model, Cmd Core.Msg )
update session msg model =
    let
        makeModel : Acquisition.Model -> LoggedIn.Model
        makeModel m =
            { session = session, tab = LoggedIn.Acquisition m }
    in
    case msg of
        -- INNER MESSAGES
        -- TODO Fix acquisition button
        -- let
        --     ( newModel, cmd ) =
        --         Acquisition.init
        --     coreCmd =
        --         Cmd.map (\x -> Core.LoggedInMsg (LoggedIn.AcquisitionMsg x)) cmd
        -- in
        -- ( session, newModel, coreCmd )
        Acquisition.AcquisitionClicked ->
            ( makeModel model, Cmd.none )

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
            ( makeModel model, Ports.uploadStream ( url, stream ) )

        Acquisition.StreamUploaded value ->
            let
                newModel =
                    case Json.Decode.decodeValue Api.decodeCapsuleDetails value of
                        Ok v ->
                            { session = session, tab = LoggedIn.Preparation (Preparation.Capsule (Capsule.init v)) }

                        Err e ->
                            let
                                _ =
                                    Log.debug "Error decoding capsule details" e
                            in
                            makeModel model
            in
            ( newModel, Cmd.none )

        Acquisition.NextSlide ->
            if model.currentSlide + 1 >= List.length (Maybe.withDefault [] model.slides) then
                ( makeModel model, Cmd.none )

            else
                ( makeModel { model | currentSlide = model.currentSlide + 1 }, Ports.askNextSlide () )

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
