module NewCapsule.Updates exposing (update)

import Api
import Core.Types as Core
import LoggedIn.Types as LoggedIn
import NewCapsule.Types as NewCapsule
import Preparation.Types as Preparation
import Status
import Utils exposing (resultToMsg)


update : Api.Session -> Int -> NewCapsule.Msg -> NewCapsule.Model -> ( Api.Session, NewCapsule.Model, Cmd Core.Msg )
update session projectId msg model =
    case msg of
        NewCapsule.NameChanged newCapsuleName ->
            ( session, { model | name = newCapsuleName }, Cmd.none )

        NewCapsule.TitleChanged newTitleName ->
            ( session, { model | title = newTitleName }, Cmd.none )

        NewCapsule.DescriptionChanged newDescriptionName ->
            ( session, { model | description = newDescriptionName }, Cmd.none )

        NewCapsule.Submitted ->
            ( session
            , { model | status = Status.Sent }
            , Api.newCapsule resultToMsg projectId model
            )

        NewCapsule.Success _ ->
            ( session
            , { model | status = Status.Success () }
            , Cmd.none
            )


resultToMsg : Result e Api.Capsule -> Core.Msg
resultToMsg result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <|
                LoggedIn.PreparationMsg <|
                    Preparation.NewCapsuleMsg <|
                        NewCapsule.Success <|
                            x
        )
        (\_ -> Core.Noop)
        result
