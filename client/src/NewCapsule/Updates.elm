module NewCapsule.Updates exposing (update)

import Api
import Core.Types as Core
import LoggedIn.Types as LoggedIn
import NewCapsule.Types as NewCapsule
import Preparation.Types as Preparation
import Status
import Utils exposing (resultToMsg)


update : Api.Project -> NewCapsule.Msg -> NewCapsule.Model -> ( LoggedIn.Tab, Cmd Core.Msg )
update project msg model =
    case msg of
        NewCapsule.NameChanged newCapsuleName ->
            ( LoggedIn.Project project (Just { model | name = newCapsuleName }), Cmd.none )

        NewCapsule.TitleChanged newTitleName ->
            ( LoggedIn.Project project (Just { model | title = newTitleName }), Cmd.none )

        NewCapsule.DescriptionChanged newDescriptionName ->
            ( LoggedIn.Project project (Just { model | description = newDescriptionName }), Cmd.none )

        NewCapsule.Submitted ->
            ( LoggedIn.Project project (Just { model | status = Status.Sent })
            , Api.newCapsule resultToMsg project.id model
            )

        NewCapsule.Success _ ->
            ( LoggedIn.Project project Nothing
            , Api.capsulesFromProjectId (resultToMsg1 project) project.id
            )

        NewCapsule.Cancel ->
            ( LoggedIn.Project project Nothing
            , Cmd.none
            )


resultToMsg : Result e Api.Capsule -> Core.Msg
resultToMsg result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <|
                LoggedIn.NewCapsuleMsg <|
                    NewCapsule.Success <|
                        x
        )
        (\_ -> Core.Noop)
        result


resultToMsg1 : Api.Project -> Result e (List Api.Capsule) -> Core.Msg
resultToMsg1 project result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <|
                LoggedIn.CapsulesReceived project x
        )
        (\_ -> Core.Noop)
        result
