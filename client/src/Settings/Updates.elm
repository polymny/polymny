module Settings.Updates exposing (update)

import Api
import Core.Types as Core
import LoggedIn.Types as LoggedIn
import Settings.Types as Settings
import Status
import Utils
import Webcam


update : Api.Session -> Settings.Msg -> Settings.Model -> ( Api.Session, Settings.Model, Cmd Core.Msg )
update session msg model =
    case msg of
        Settings.WithVideoChanged newWithVideo ->
            ( { session | withVideo = Just newWithVideo }, model, Cmd.none )

        Settings.WebcamSizeChanged newWebcamSize ->
            ( { session | webcamSize = Just newWebcamSize }, model, Cmd.none )

        Settings.WebcamPositionChanged newWebcamPosition ->
            ( { session | webcamPosition = Just newWebcamPosition }, model, Cmd.none )

        Settings.OptionsSubmitted ->
            ( session
            , { model | status = Status.Sent }
            , Api.updateOptions resultToMsg
                { withVideo = Maybe.withDefault True session.withVideo
                , webcamSize = Maybe.withDefault Webcam.Medium session.webcamSize
                , webcamPosition = Maybe.withDefault Webcam.BottomLeft session.webcamPosition
                }
            )

        Settings.OptionsSuccess newSession ->
            ( newSession, { model | status = Status.Success () }, Cmd.none )

        Settings.OptionsFailed ->
            ( session, { model | status = Status.Error () }, Cmd.none )


resultToMsg : Result e Api.Session -> Core.Msg
resultToMsg result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <| LoggedIn.SettingsMsg <| Settings.OptionsSuccess x
        )
        (\_ -> Core.LoggedInMsg <| LoggedIn.SettingsMsg <| Settings.OptionsFailed)
        result
