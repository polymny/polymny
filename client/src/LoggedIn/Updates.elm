module LoggedIn.Updates exposing (update)

import Api
import Capsule.Types as Capsule
import Capsule.Updates as Capsule
import Core.Types as Core
import LoggedIn.Types as LoggedIn
import NewCapsule.Types as NewCapsule
import NewCapsule.Updates as NewCapsule
import NewProject.Types as NewProject
import NewProject.Updates as NewProject
import Utils


update : LoggedIn.Msg -> LoggedIn.Model -> ( LoggedIn.Model, Cmd Core.Msg )
update msg { session, page } =
    case ( msg, page ) of
        -- INNER MESSAGES
        ( LoggedIn.ProjectClicked project, _ ) ->
            ( LoggedIn.Model session (LoggedIn.Project project), Api.capsulesFromProjectId (resultToMsg1 project) project.id )

        ( LoggedIn.CapsulesReceived project capsules, _ ) ->
            ( LoggedIn.Model session (LoggedIn.Project { project | capsules = capsules }), Cmd.none )

        ( LoggedIn.CapsuleClicked capsule, _ ) ->
            ( LoggedIn.Model session page, Api.capsuleFromId resultToMsg2 capsule.id )

        ( LoggedIn.CapsuleReceived capsuleDetails, LoggedIn.Capsule capsule ) ->
            ( LoggedIn.Model session
                (LoggedIn.Capsule
                    { capsule
                        | details = capsuleDetails
                        , slides = Capsule.setupSlides capsuleDetails.slides
                    }
                )
            , Cmd.none
            )

        ( LoggedIn.CapsuleReceived capsuleDetails, _ ) ->
            ( LoggedIn.Model session (LoggedIn.Capsule (Capsule.init capsuleDetails)), Cmd.none )

        -- OTHER MESSAGES
        ( LoggedIn.NewProjectMsg newProjectMsg, LoggedIn.NewProject newProjectModel ) ->
            let
                ( newSession, newModel, cmd ) =
                    NewProject.update session newProjectMsg newProjectModel
            in
            ( LoggedIn.Model newSession (LoggedIn.NewProject newModel), cmd )

        ( LoggedIn.NewCapsuleMsg newCapsuleMsg, LoggedIn.NewCapsule projectId newCapsuleModel ) ->
            let
                ( newSession, newModel, cmd ) =
                    NewCapsule.update session projectId newCapsuleMsg newCapsuleModel
            in
            ( LoggedIn.Model newSession (LoggedIn.NewCapsule projectId newModel), cmd )

        ( LoggedIn.CapsuleMsg capsuleMsg, LoggedIn.Capsule capsule ) ->
            let
                ( newModel, cmd ) =
                    Capsule.update capsuleMsg capsule
            in
            ( LoggedIn.Model session (LoggedIn.Capsule newModel), cmd )

        _ ->
            ( LoggedIn.Model session page, Cmd.none )


resultToMsg1 : Api.Project -> Result e (List Api.Capsule) -> Core.Msg
resultToMsg1 project result =
    Utils.resultToMsg (\x -> Core.LoggedInMsg <| LoggedIn.CapsulesReceived project x) (\_ -> Core.Noop) result


resultToMsg2 : Result e Api.CapsuleDetails -> Core.Msg
resultToMsg2 result =
    Utils.resultToMsg (\x -> Core.LoggedInMsg <| LoggedIn.CapsuleReceived x) (\_ -> Core.Noop) result
