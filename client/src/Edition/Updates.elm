module Edition.Updates exposing (update)

import Api
import Core.Types as Core
import Edition.Types as Edition
import LoggedIn.Types as LoggedIn
import Status


update : Api.Session -> Edition.Msg -> Edition.Model -> ( LoggedIn.Model, Cmd Core.Msg )
update session msg model =
    let
        makeModel : Edition.Model -> LoggedIn.Model
        makeModel m =
            { session = session, tab = LoggedIn.Edition m }
    in
    case msg of
        Edition.AutoSuccess capsuleDetails ->
            ( makeModel { model | status = Status.Success (), details = capsuleDetails }, Cmd.none )
