module LoggedIn.Updates exposing (update)

import Core.Types as Core
import LoggedIn.Types as LoggedIn
import Preparation.Types as Preparation
import Preparation.Updates as Preparation


update : LoggedIn.Msg -> LoggedIn.Model -> ( LoggedIn.Model, Cmd Core.Msg )
update msg { session, tab } =
    case ( msg, tab ) of
        ( LoggedIn.PreparationMsg preparationMsg, LoggedIn.Preparation model ) ->
            let
                ( newModel, cmd ) =
                    Preparation.update preparationMsg model
            in
            ( LoggedIn.Model session (LoggedIn.Preparation newModel), cmd )

        _ ->
            ( LoggedIn.Model session tab, Cmd.none )
