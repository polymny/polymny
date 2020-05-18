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


update : Api.Session -> Preparation.Msg -> Preparation.Model -> ( Api.Session, Preparation.Model, Cmd Core.Msg )
update session msg preparationModel =
    case ( msg, preparationModel ) of
        -- INNER MESSAGES
        ( Preparation.PreparationClicked, _ ) ->
            ( session, Preparation.Home, Cmd.none )

        ( Preparation.ProjectClicked project, _ ) ->
            ( session, Preparation.Project project Nothing, Api.capsulesFromProjectId (resultToMsg1 project) project.id )

        ( Preparation.CapsulesReceived project capsules, _ ) ->
            ( { session | active_project = Just project }
            , Preparation.Project { project | capsules = capsules } Nothing
            , Cmd.none
            )

        ( Preparation.CapsuleClicked capsule, _ ) ->
            ( session, preparationModel, Api.capsuleFromId resultToMsg2 capsule.id )

        ( Preparation.CapsuleReceived capsuleDetails, Preparation.Capsule capsule ) ->
            ( session
            , Preparation.Capsule
                { capsule
                    | details = capsuleDetails
                    , slides = Capsule.setupSlides capsuleDetails.slides
                }
            , Cmd.none
            )

        ( Preparation.CapsuleReceived capsuleDetails, _ ) ->
            ( session, Preparation.Capsule (Capsule.init capsuleDetails), Cmd.none )

        -- OTHER MESSAGES
        ( Preparation.NewProjectMsg newProjectMsg, Preparation.NewProject newProjectModel ) ->
            let
                ( newSession, newModel, cmd ) =
                    NewProject.update session newProjectMsg newProjectModel
            in
            ( newSession, Preparation.NewProject newModel, cmd )

        ( Preparation.NewCapsuleMsg newCapsuleMsg, Preparation.Project project (Just newCapsuleModel) ) ->
            let
                ( newModel, cmd ) =
                    NewCapsule.update project newCapsuleMsg newCapsuleModel
            in
            ( session, newModel, cmd )

        ( Preparation.CapsuleMsg capsuleMsg, Preparation.Capsule capsule ) ->
            let
                ( newModel, cmd ) =
                    Capsule.update capsuleMsg capsule
            in
            ( session, Preparation.Capsule newModel, cmd )

        _ ->
            ( session, preparationModel, Cmd.none )


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
