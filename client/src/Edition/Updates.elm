module Edition.Updates exposing (update)

import Api
import Core.Types as Core
import Edition.Ports as Ports
import Edition.Types as Edition
import LoggedIn.Types as LoggedIn
import Status
import Utils
import Webcam


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
            let
                editionOptions =
                    Maybe.withDefault Edition.defaultGosProductionChoices model.details.capsule.capsuleEditionOptions

                newEditionOptions =
                    { editionOptions | withVideo = newWithVideo }

                capsule =
                    model.details.capsule

                newCapsule =
                    { capsule | capsuleEditionOptions = Just newEditionOptions }

                details =
                    model.details

                newDetails =
                    { details | capsule = newCapsule }
            in
            ( makeModel { model | details = newDetails }
            , Api.updateCapsuleOptions (\_ -> Core.Noop)
                capsule.id
                { webcamPosition = Maybe.withDefault Webcam.BottomLeft newEditionOptions.webcamPosition
                , webcamSize = Maybe.withDefault Webcam.Medium newEditionOptions.webcamSize
                , withVideo = newEditionOptions.withVideo
                }
            )

        Edition.WebcamSizeChanged newWebcamSize ->
            let
                editionOptions =
                    Maybe.withDefault Edition.defaultGosProductionChoices model.details.capsule.capsuleEditionOptions

                newEditionOptions =
                    { editionOptions | webcamSize = Just newWebcamSize }

                capsule =
                    model.details.capsule

                newCapsule =
                    { capsule | capsuleEditionOptions = Just newEditionOptions }

                details =
                    model.details

                newDetails =
                    { details | capsule = newCapsule }
            in
            ( makeModel { model | details = newDetails }
            , Api.updateCapsuleOptions (\_ -> Core.Noop)
                capsule.id
                { webcamPosition = Maybe.withDefault Webcam.BottomLeft newEditionOptions.webcamPosition
                , webcamSize = Maybe.withDefault Webcam.Medium newEditionOptions.webcamSize
                , withVideo = newEditionOptions.withVideo
                }
            )

        Edition.WebcamPositionChanged newWebcamPosition ->
            let
                editionOptions =
                    Maybe.withDefault Edition.defaultGosProductionChoices model.details.capsule.capsuleEditionOptions

                newEditionOptions =
                    { editionOptions | webcamPosition = Just newWebcamPosition }

                capsule =
                    model.details.capsule

                newCapsule =
                    { capsule | capsuleEditionOptions = Just newEditionOptions }

                details =
                    model.details

                newDetails =
                    { details | capsule = newCapsule }
            in
            ( makeModel { model | details = newDetails }
            , Api.updateCapsuleOptions (\_ -> Core.Noop)
                capsule.id
                { webcamPosition = Maybe.withDefault Webcam.BottomLeft newEditionOptions.webcamPosition
                , webcamSize = Maybe.withDefault Webcam.Medium newEditionOptions.webcamSize
                , withVideo = newEditionOptions.withVideo
                }
            )

        Edition.OptionsSubmitted ->
            let
                editionOptions =
                    Maybe.withDefault Edition.defaultGosProductionChoices model.details.capsule.capsuleEditionOptions
            in
            ( makeModel { model | status = Status.Sent }
            , Api.editionAuto resultToMsg
                model.details.capsule.id
                { withVideo = editionOptions.withVideo
                , webcamSize = Maybe.withDefault Webcam.Medium editionOptions.webcamSize
                , webcamPosition = Maybe.withDefault Webcam.BottomLeft editionOptions.webcamPosition
                }
                model.details
            )

        Edition.GosUseDefaultChanged gosIndex newUseDefault ->
            let
                gosStructure : Maybe Api.Gos
                gosStructure =
                    List.head (List.drop gosIndex model.details.structure)

                gosUpdatedStructure : Maybe Api.Gos
                gosUpdatedStructure =
                    Maybe.map
                        (\x ->
                            let
                                newP =
                                    if newUseDefault then
                                        Nothing

                                    else
                                        case model.details.capsule.capsuleEditionOptions of
                                            Just o ->
                                                Just o

                                            Nothing ->
                                                Just Edition.defaultGosProductionChoices
                            in
                            { x | production_choices = newP }
                        )
                        gosStructure

                ( newDetails, cmd ) =
                    newDetailsAux model gosIndex gosUpdatedStructure
            in
            ( makeModel { model | details = newDetails }, cmd )

        Edition.GosWithVideoChanged gosIndex newWithVideo ->
            let
                gosStructure : Maybe Api.Gos
                gosStructure =
                    List.head (List.drop gosIndex model.details.structure)

                gosUpdatedStructure : Maybe Api.Gos
                gosUpdatedStructure =
                    Maybe.map
                        (\x ->
                            let
                                newP =
                                    case x.production_choices of
                                        Just p ->
                                            { p | withVideo = newWithVideo }

                                        Nothing ->
                                            Api.CapsuleEditionOptions newWithVideo (Just Webcam.Medium) (Just Webcam.BottomLeft)
                            in
                            { x | production_choices = Just newP }
                        )
                        gosStructure

                ( newDetails, cmd ) =
                    newDetailsAux model gosIndex gosUpdatedStructure
            in
            ( makeModel { model | details = newDetails }, cmd )

        Edition.GosWebcamSizeChanged gosIndex newWebcamSize ->
            let
                gosStructure : Maybe Api.Gos
                gosStructure =
                    List.head (List.drop gosIndex model.details.structure)

                gosUpdatedStructure : Maybe Api.Gos
                gosUpdatedStructure =
                    Maybe.map
                        (\x ->
                            let
                                newP =
                                    case x.production_choices of
                                        Just p ->
                                            { p | webcamSize = Just newWebcamSize }

                                        Nothing ->
                                            Api.CapsuleEditionOptions True (Just newWebcamSize) (Just Webcam.BottomLeft)
                            in
                            { x | production_choices = Just newP }
                        )
                        gosStructure

                ( newDetails, cmd ) =
                    newDetailsAux model gosIndex gosUpdatedStructure
            in
            ( makeModel { model | details = newDetails }, cmd )

        Edition.GosWebcamPositionChanged gosIndex newWebcamPosition ->
            let
                gosStructure : Maybe Api.Gos
                gosStructure =
                    List.head (List.drop gosIndex model.details.structure)

                gosUpdatedStructure : Maybe Api.Gos
                gosUpdatedStructure =
                    Maybe.map
                        (\x ->
                            let
                                newP =
                                    case x.production_choices of
                                        Just p ->
                                            { p | webcamPosition = Just newWebcamPosition }

                                        Nothing ->
                                            Api.CapsuleEditionOptions True (Just Webcam.Medium) (Just newWebcamPosition)
                            in
                            { x | production_choices = Just newP }
                        )
                        gosStructure

                ( newDetails, cmd ) =
                    newDetailsAux model gosIndex gosUpdatedStructure
            in
            ( makeModel { model | details = newDetails }, cmd )

        Edition.CopyUrl url ->
            ( makeModel model, Ports.copyString url )

        Edition.ToggleEditDefault ->
            ( makeModel { model | editCapsuleOptions = not model.editCapsuleOptions }, Cmd.none )


newDetailsAux : Edition.Model -> Int -> Maybe Api.Gos -> ( Api.CapsuleDetails, Cmd Core.Msg )
newDetailsAux model i gosUpdatedStructure =
    let
        details =
            model.details

        newStructure =
            case gosUpdatedStructure of
                Just new ->
                    List.take i model.details.structure
                        ++ (new :: List.drop (i + 1) model.details.structure)

                _ ->
                    model.details.structure

        newDetails =
            { details | structure = newStructure }
    in
    ( newDetails, Api.updateSlideStructure resultToMsg newDetails )


resultToMsg : Result e Api.CapsuleDetails -> Core.Msg
resultToMsg result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <| LoggedIn.EditionMsg <| Edition.AutoSuccess x
        )
        (\_ -> Core.LoggedInMsg <| LoggedIn.EditionMsg <| Edition.AutoFailed)
        result
