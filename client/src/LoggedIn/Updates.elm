module LoggedIn.Updates exposing (update)

import Acquisition.Types as Acquisition
import Acquisition.Updates as Acquisition
import Api
import Core.Types as Core
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

        ( LoggedIn.Record capsule gos slides, _ ) ->
            let
                ( t, cmd ) =
                    Acquisition.withSlides capsule gos slides
            in
            ( { session = session, tab = LoggedIn.Acquisition t }, Cmd.map (\x -> Core.LoggedInMsg (LoggedIn.AcquisitionMsg x)) cmd )

        ( LoggedIn.PreparationMsg Preparation.PreparationClicked, _ ) ->
            ( { session = session, tab = LoggedIn.Preparation Preparation.Home }
            , Cmd.none
            )

        ( LoggedIn.AcquisitionMsg acquisitionMsg, LoggedIn.Acquisition model ) ->
            let
                ( newSession, newModel, cmd ) =
                    Acquisition.update session acquisitionMsg model
            in
            ( LoggedIn.Model newSession (LoggedIn.Acquisition newModel), cmd )

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

        _ ->
            ( LoggedIn.Model session tab, Cmd.none )


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
