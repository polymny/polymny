module LoggedIn.Updates exposing (update)

import Acquisition.Types as Acquisition
import Acquisition.Updates as Acquisition
import Api
import Core.Types as Core
import File.Select as Select
import LoggedIn.Types as LoggedIn
import Preparation.Types as Preparation
import Preparation.Updates as Preparation
import Utils


update : LoggedIn.Msg -> LoggedIn.Model -> ( LoggedIn.Model, Cmd Core.Msg )
update msg { session, tab } =
    case ( msg, tab ) of
        ( LoggedIn.PreparationMsg preparationMsg, LoggedIn.Preparation model ) ->
            let
                ( newSession, newModel, cmd ) =
                    Preparation.update session preparationMsg model
            in
            ( LoggedIn.Model newSession (LoggedIn.Preparation newModel), cmd )

        ( LoggedIn.PreparationMsg (Preparation.ProjectClicked project), _ ) ->
            ( { session = session, tab = LoggedIn.Preparation <| Preparation.Project project Nothing }
            , Api.capsulesFromProjectId (resultToMsg project) project.id
            )

        ( LoggedIn.Record capsule gos, _ ) ->
            let
                ( t, cmd ) =
                    Acquisition.init capsule Acquisition.Single gos
            in
            ( { session = session, tab = LoggedIn.Acquisition t }, Cmd.map (\x -> Core.LoggedInMsg (LoggedIn.AcquisitionMsg x)) cmd )

        ( LoggedIn.PreparationMsg Preparation.PreparationClicked, _ ) ->
            ( { session = session, tab = LoggedIn.Preparation Preparation.Home }
            , Cmd.none
            )

        ( LoggedIn.AcquisitionMsg acquisitionMsg, LoggedIn.Acquisition model ) ->
            Acquisition.update session acquisitionMsg model

        -- TODO Fix acquisition button
        -- ( LoggedIn.AcquisitionMsg Acquisition.AcquisitionClicked, _ ) ->
        --     let
        --         ( model, cmd ) =
        --             Acquisition.init
        --         coreCmd =
        --             Cmd.map (\x -> Core.LoggedInMsg (LoggedIn.AcquisitionMsg x)) cmd
        --     in
        --     ( { session = session, tab = LoggedIn.Acquisition model }
        --     , coreCmd
        --     )
        ( LoggedIn.AcquisitionMsg Acquisition.AcquisitionClicked, _ ) ->
            ( LoggedIn.Model session tab, Cmd.none )

        ( LoggedIn.UploadSlideShowMsg uploadSlideShowMsg, LoggedIn.Home model ) ->
            let
                ( newModel, cmd ) =
                    updateUploadSlideShow uploadSlideShowMsg model
            in
            ( LoggedIn.Model session (LoggedIn.Home newModel), cmd )

        _ ->
            ( LoggedIn.Model session tab, Cmd.none )


updateUploadSlideShow : LoggedIn.UploadSlideShowMsg -> LoggedIn.UploadForm -> ( LoggedIn.UploadForm, Cmd Core.Msg )
updateUploadSlideShow msg model =
    case ( msg, model ) of
        ( LoggedIn.UploadSlideShowSelectFileRequested, _ ) ->
            ( model
            , Select.file
                [ "application/pdf" ]
                (\x ->
                    Core.LoggedInMsg <|
                        LoggedIn.UploadSlideShowMsg <|
                            LoggedIn.UploadSlideShowFileReady x
                )
            )

        ( LoggedIn.UploadSlideShowFileReady file, form ) ->
            ( { form | file = Just file }
            , Cmd.none
            )

        ( LoggedIn.UploadSlideShowFormSubmitted, form ) ->
            case form.file of
                Nothing ->
                    ( form, Cmd.none )

                Just file ->
                    ( form, Api.capsuleUploadSlideShow resultToMsg1 0 file )


resultToMsg : Api.Project -> Result e (List Api.Capsule) -> Core.Msg
resultToMsg project result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <|
                LoggedIn.PreparationMsg <|
                    Preparation.CapsulesReceived project x
        )
        (\_ -> Core.Noop)
        result


resultToMsg1 : Result e Api.CapsuleDetails -> Core.Msg
resultToMsg1 result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <| LoggedIn.PreparationMsg <| Preparation.CapsuleReceived x
        )
        (\_ -> Core.Noop)
        result
