module Preparation.Updates exposing (update)

import Api
import Capsule.Types as Capsule
import Capsule.Updates as Capsule
import Core.Types as Core
import LoggedIn.Types as LoggedIn
import NewCapsule.Types as NewCapsule
import NewCapsule.Updates as NewCapsule
import NewProject.Types as NewProject
import NewProject.Updates as NewProject
import Preparation.Types as Preparation
import Utils


update : Preparation.Msg -> Preparation.Model -> ( Preparation.Model, Cmd Core.Msg )
update msg { session, page } =
    case ( msg, page ) of
        -- INNER MESSAGES
        ( Preparation.ProjectClicked project, _ ) ->
            ( Preparation.Model session (Preparation.Project project), Api.capsulesFromProjectId (resultToMsg1 project) project.id )

        ( Preparation.CapsulesReceived project capsules, _ ) ->
            ( Preparation.Model session (Preparation.Project { project | capsules = capsules }), Cmd.none )

        ( Preparation.CapsuleClicked capsule, _ ) ->
            ( Preparation.Model session page, Api.capsuleFromId resultToMsg2 capsule.id )

        ( Preparation.CapsuleReceived capsuleDetails, Preparation.Capsule capsule ) ->
            ( Preparation.Model session
                (Preparation.Capsule
                    { capsule
                        | details = capsuleDetails
                        , slides = Capsule.setupSlides capsuleDetails.slides
                    }
                )
            , Cmd.none
            )

        ( Preparation.CapsuleReceived capsuleDetails, _ ) ->
            ( Preparation.Model session (Preparation.Capsule (Capsule.init capsuleDetails)), Cmd.none )

        -- OTHER MESSAGES
        ( Preparation.NewProjectMsg newProjectMsg, Preparation.NewProject newProjectModel ) ->
            let
                ( newSession, newModel, cmd ) =
                    NewProject.update session newProjectMsg newProjectModel
            in
            ( Preparation.Model newSession (Preparation.NewProject newModel), cmd )

        ( Preparation.NewCapsuleMsg newCapsuleMsg, Preparation.NewCapsule projectId newCapsuleModel ) ->
            let
                ( newSession, newModel, cmd ) =
                    NewCapsule.update session projectId newCapsuleMsg newCapsuleModel
            in
            ( Preparation.Model newSession (Preparation.NewCapsule projectId newModel), cmd )

        ( Preparation.CapsuleMsg capsuleMsg, Preparation.Capsule capsule ) ->
            let
                ( newModel, cmd ) =
                    Capsule.update capsuleMsg capsule
            in
            ( Preparation.Model session (Preparation.Capsule newModel), cmd )

        _ ->
            ( Preparation.Model session page, Cmd.none )


resultToMsg1 : Api.Project -> Result e (List Api.Capsule) -> Core.Msg
resultToMsg1 project result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <|
                LoggedIn.PreparationMsg <|
                    Preparation.CapsulesReceived project x
        )
        (\_ -> Core.Noop)
        result


resultToMsg2 : Result e Api.CapsuleDetails -> Core.Msg
resultToMsg2 result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <|
                LoggedIn.PreparationMsg <|
                    Preparation.CapsuleReceived x
        )
        (\_ -> Core.Noop)
        result
