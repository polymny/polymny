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
            ( { session = session, tab = LoggedIn.Preparation <| Preparation.Project project False }
            , Api.capsulesFromProjectId (resultToMsg project) project.id
            )

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

        ( LoggedIn.AcquisitionMsg Acquisition.AcquisitionClicked, _ ) ->
            ( { session = session, tab = LoggedIn.Acquisition Acquisition.Home }
            , Cmd.none
            )

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
