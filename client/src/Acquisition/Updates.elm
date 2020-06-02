module Acquisition.Updates exposing (update)

import Acquisition.Ports as Ports
import Acquisition.Types as Acquisition
import Api
import Core.Types as Core
import LoggedIn.Types as LoggedIn


update : Api.Session -> Acquisition.Msg -> Acquisition.Model -> ( Api.Session, Acquisition.Model, Cmd Core.Msg )
update session msg model =
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
            ( session, model, Cmd.none )

        Acquisition.StartRecording ->
            let
                cmd =
                    if model.currentStream == 0 then
                        Ports.startRecording ()

                    else
                        Cmd.batch [ Ports.goToStream ( elementId, 0 ), Ports.startRecording () ]
            in
            ( session, { model | recording = True, currentStream = 0 }, cmd )

        Acquisition.StopRecording ->
            ( session, { model | recording = False }, Ports.stopRecording () )

        Acquisition.RecordingsNumber n ->
            ( session, { model | recordingsNumber = n }, Cmd.none )

        Acquisition.GoToStream n ->
            if model.currentStream == n then
                ( session, model, Cmd.none )

            else
                ( session, { model | currentStream = n }, Ports.goToStream ( elementId, n ) )

        Acquisition.UploadStream url stream ->
            ( session, model, Ports.uploadStream ( url, stream ) )


elementId : String
elementId =
    "video"
