module Preparation.Updates exposing (update)

import Api
import Capsule.Types as Capsule
import Capsule.Updates as Capsule
import Core.Types as Core
import Preparation.Types as Preparation


update : Api.Session -> Preparation.Msg -> Preparation.Model -> ( Api.Session, Preparation.Model, Cmd Core.Msg )
update session msg preparationModel =
    case ( msg, preparationModel ) of
        -- OTHER MESSAGES
        ( Preparation.CapsuleMsg capsuleMsg, Preparation.Capsule capsule ) ->
            let
                ( newModel, cmd ) =
                    Capsule.update capsuleMsg capsule
            in
            ( session, Preparation.Capsule newModel, cmd )
