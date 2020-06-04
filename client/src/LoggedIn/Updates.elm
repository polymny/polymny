module LoggedIn.Updates exposing (update)

import Acquisition.Types as Acquisition
import Acquisition.Updates as Acquisition
import Api
import Capsule.Types as Capsule
import Core.Types as Core
import File.Select as Select
import LoggedIn.Types as LoggedIn
import Preparation.Types as Preparation
import Preparation.Updates as Preparation
import Status
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

        ( LoggedIn.UploadSlideShowMsg uploadSlideShowMsg, LoggedIn.Home form ) ->
            let
                ( newModel, cmd ) =
                    updateUploadSlideShow uploadSlideShowMsg { session = session, tab = tab } form
            in
            ( newModel, cmd )

        _ ->
            ( LoggedIn.Model session tab, Cmd.none )


updateUploadSlideShow : LoggedIn.UploadSlideShowMsg -> LoggedIn.Model -> LoggedIn.UploadForm -> ( LoggedIn.Model, Cmd Core.Msg )
updateUploadSlideShow msg { session } form =
    case msg of
        LoggedIn.UploadSlideShowSelectFileRequested ->
            ( LoggedIn.Model session (LoggedIn.Home form)
            , Select.file
                [ "application/pdf" ]
                (\x ->
                    Core.LoggedInMsg <|
                        LoggedIn.UploadSlideShowMsg <|
                            LoggedIn.UploadSlideShowFileReady x
                )
            )

        LoggedIn.UploadSlideShowFileReady file ->
            ( LoggedIn.Model session
                (LoggedIn.Home { form | file = Just file })
            , Cmd.none
            )

        LoggedIn.UploadSlideShowFormSubmitted ->
            case form.file of
                Nothing ->
                    ( LoggedIn.Model session (LoggedIn.Home form), Cmd.none )

                Just file ->
                    ( LoggedIn.Model session (LoggedIn.Home { form | status = Status.Sent })
                    , Api.quickUploadSlideShow resultToMsg1 file
                    )

        LoggedIn.UploadSlideShowSuccess capsule ->
            ( LoggedIn.Model session (LoggedIn.Preparation <| Preparation.Capsule <| Capsule.init capsule)
            , Cmd.none
            )


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
            Core.LoggedInMsg <| LoggedIn.UploadSlideShowMsg <| LoggedIn.UploadSlideShowSuccess x
        )
        (\_ -> Core.Noop)
        result
