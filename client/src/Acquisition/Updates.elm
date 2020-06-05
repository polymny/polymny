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
                        Cmd.batch [ Ports.goToStream ( elementId, 0 ), Ports.startRecording () ]
            in
            ( makeModel { model | recording = True, currentStream = 0, currentSlide = 0 }, cmd )

        Acquisition.StopRecording ->
            ( makeModel { model | recording = False }, Ports.stopRecording () )

        Acquisition.RecordingsNumber n ->
            ( makeModel { model | recordingsNumber = n }, Cmd.none )

        Acquisition.GoToStream n ->
            if model.currentStream == n then
                ( makeModel model, Cmd.none )

            else
                ( makeModel { model | currentStream = n }, Ports.goToStream ( elementId, n ) )

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
            let
                newSlide =
                    min (model.currentSlide + 1) (List.length (Maybe.withDefault [] model.slides) - 1)
            in
            ( makeModel { model | currentSlide = newSlide }, Cmd.none )


elementId : String
elementId =
    "video"
