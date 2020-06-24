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

        Edition.PublishVideo ->
            let
                capsule =
                    model.details.capsule

                details =
                    model.details

                newCapsule =
                    { capsule | published = Api.Publishing }

                newDetails =
                    { details | capsule = newCapsule }

                cmd =
                    Api.publishVideo (\_ -> Edition.VideoPublished) model.details.capsule.id
                        |> Cmd.map LoggedIn.EditionMsg
                        |> Cmd.map Core.LoggedInMsg
            in
            ( makeModel { model | details = newDetails }, cmd )

        Edition.VideoPublished ->
            let
                capsule =
                    model.details.capsule

                details =
                    model.details

                newCapsule =
                    { capsule | published = Api.Published }

                newDetails =
                    { details | capsule = newCapsule }
            in
            ( makeModel { model | details = newDetails }, Cmd.none )
