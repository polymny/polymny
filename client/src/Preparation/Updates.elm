module Preparation.Updates exposing (update)

import Api
import Capsule.Types as Capsule
import Capsule.Updates as Capsule
import Core.Types as Core
import Preparation.Types as Preparation


update : Api.Session -> Preparation.Msg -> Preparation.Model -> ( Api.Session, Preparation.Model, Cmd Core.Msg )
update session msg preparationModel =
    case ( msg, preparationModel ) of
        -- INNER MESSAGES
        ( Preparation.PreparationClicked, _ ) ->
            ( session, Preparation.Home, Cmd.none )

        ( Preparation.CapsuleReceived capsuleDetails, Preparation.Capsule capsule ) ->
            ( session
            , Preparation.Capsule
                { capsule
                    | details = capsuleDetails
                    , slides = Capsule.setupSlides capsuleDetails
                }
            , Cmd.none
            )

        ( Preparation.CapsuleReceived capsuleDetails, _ ) ->
            ( session, Preparation.Capsule (Capsule.init capsuleDetails), Cmd.none )

        -- OTHER MESSAGES
        ( Preparation.CapsuleMsg capsuleMsg, Preparation.Capsule capsule ) ->
            let
                ( newModel, cmd ) =
                    Capsule.update capsuleMsg capsule
            in
            ( session, Preparation.Capsule newModel, cmd )

        _ ->
            ( session, preparationModel, Cmd.none )
