module Edition.Updates exposing (update)

import Api
import Core.Types as Core
import Edition.Types as Edition
import LoggedIn.Types as LoggedIn
import Status
import Utils


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

        Edition.AutoFailed ->
            ( makeModel { model | status = Status.Error () }, Cmd.none )

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

        Edition.WithVideoChanged newWithVideo ->
            ( makeModel { model | withVideo = newWithVideo }, Cmd.none )

        Edition.WebcamSizeChanged newWebcamSize ->
            ( makeModel { model | webcamSize = newWebcamSize }, Cmd.none )

        Edition.WebcamPositionChanged newWebcamPosition ->
            ( makeModel { model | webcamPosition = newWebcamPosition }, Cmd.none )

        Edition.OptionsSubmitted ->
            ( makeModel { model | status = Status.Sent }
            , Api.editionAuto resultToMsg
                model.details.capsule.id
                { withVideo = model.withVideo
                , webcamSize = model.webcamSize
                , webcamPosition = model.webcamPosition
                }
            )


resultToMsg : Result e Api.CapsuleDetails -> Core.Msg
resultToMsg result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <| LoggedIn.EditionMsg <| Edition.AutoSuccess x
        )
        (\_ -> Core.LoggedInMsg <| LoggedIn.EditionMsg <| Edition.AutoFailed)
        result
