module Acquisition.Updates exposing (update)

import Acquisition.Types as Acquisition
import Api
import Core.Types as Core


update : Api.Session -> Acquisition.Msg -> Acquisition.Model -> ( Api.Session, Acquisition.Model, Cmd Core.Msg )
update session msg acquisitionModel =
    case ( msg, acquisitionModel ) of
        -- INNER MESSAGES
        ( Acquisition.AcquisitionClicked, _ ) ->
            ( session, Acquisition.Home, Cmd.none )
