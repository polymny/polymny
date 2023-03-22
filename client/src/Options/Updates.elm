port module Options.Updates exposing (..)

import Api.Capsule as Api
import App.Types as App exposing (Page(..))
import App.Utils as App
import Config
import Data.Capsule as Data
import Data.User as Data
import File
import FileValue
import Json.Decode as Decode
import Keyboard
import Options.Types as Options
import RemoteData
import Utils


{-| Updates the model.
-}
update : Options.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    let
        ( maybeCapsule, _ ) =
            App.capsuleAndGos model.user model.page
    in
    case ( model.page, maybeCapsule ) of
        ( App.Options m, Just capsule ) ->
            case msg of
                Options.ToggleVideo ->
                    let
                        newWebcamSettings =
                            case capsule.defaultWebcamSettings of
                                Data.Disabled ->
                                    Data.defaultWebcamSettings ( 533, 0 )

                                _ ->
                                    Data.Disabled
                    in
                    updateModelWebcamSettings capsule newWebcamSettings model m

                Options.SetOpacity opacity ->
                    let
                        newWebcamSettings =
                            case capsule.defaultWebcamSettings of
                                Data.Pip p ->
                                    Data.Pip { p | opacity = opacity }

                                x ->
                                    x
                    in
                    updateModelWebcamSettings capsule newWebcamSettings model m

                Options.SetWidth newWidth ->
                    let
                        newWebcamSettings =
                            case newWidth of
                                Nothing ->
                                    Data.setWebcamSettingsSize Nothing capsule.defaultWebcamSettings

                                Just width ->
                                    Data.setWebcamSettingsSize (Just ( width, 0 )) capsule.defaultWebcamSettings
                    in
                    updateModelWebcamSettings capsule newWebcamSettings model m

                Options.SetAnchor anchor ->
                    let
                        newWebcamSettings =
                            case capsule.defaultWebcamSettings of
                                Data.Pip p ->
                                    Data.Pip { p | anchor = anchor, position = ( 4, 4 ) }

                                x ->
                                    x
                    in
                    updateModelWebcamSettings capsule newWebcamSettings model { m | webcamPosition = ( 4.0, 4.0 ) }

                Options.TrackUploadRequested ->
                    ( model, selectTrack [ "audio/*" ] )

                Options.TrackUploadReceived fileValue file ->
                    let
                        isAudio : Bool
                        isAudio =
                            fileValue.mime |> String.startsWith "audio/"
                    in
                    if isAudio then
                        let
                            task : Config.TaskStatus
                            task =
                                { task = Config.UploadTrack model.config.clientState.taskId capsule.id
                                , progress = Just 0.0
                                , finished = False
                                , aborted = False
                                , global = True
                                }

                            newPage : App.Page
                            newPage =
                                App.Options { m | deleteTrack = Nothing, capsuleUpdate = RemoteData.Loading Nothing }

                            ( newConfig, _ ) =
                                Config.update (Config.UpdateTaskStatus task) model.config
                        in
                        ( { model | page = newPage, config = Config.incrementTaskId newConfig }
                        , Cmd.batch
                            [ Api.uploadTrack
                                { capsule = capsule
                                , fileValue = fileValue
                                , file = file
                                , toMsg = \x -> App.OptionsMsg (Options.TrackUpload x)
                                , taskId = model.config.clientState.taskId
                                }
                            ]
                        )

                    else
                        ( model, Cmd.none )

                Options.TrackUploadResponded _ ->
                    ( model, Cmd.none )

                Options.DeleteTrack Utils.Request track ->
                    case capsule.soundTrack of
                        Just _ ->
                            ( { model | page = App.Options { m | deleteTrack = track } }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                Options.DeleteTrack Utils.Cancel _ ->
                    case capsule.soundTrack of
                        Just _ ->
                            ( { model | page = App.Options { m | deleteTrack = Nothing } }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                Options.DeleteTrack Utils.Confirm _ ->
                    let
                        newCapsule =
                            Data.removeTrack capsule

                        ( sync, newConfig ) =
                            ( Api.updateCapsule newCapsule
                                (\_ ->
                                    RemoteData.Success newCapsule
                                        |> Options.CapsuleUpdate model.config.clientState.lastRequest
                                        |> App.OptionsMsg
                                )
                            , Config.incrementRequest model.config
                            )
                    in
                    ( { model
                        | user = Data.updateUser newCapsule model.user
                        , page = App.Options (Options.init newCapsule)
                        , config = newConfig
                      }
                    , sync
                    )

                Options.TrackUpload (RemoteData.Success c) ->
                    ( { model
                        | page = App.Options { m | capsuleUpdate = RemoteData.Success c }
                        , user = Data.updateUser c model.user
                      }
                    , Cmd.none
                    )

                Options.TrackUpload _ ->
                    ( model, Cmd.none )

                Options.CapsuleUpdate id data ->
                    if model.config.clientState.lastRequest == id + 1 then
                        ( { model | page = App.Options { m | capsuleUpdate = data } }, Cmd.none )

                    else
                        ( model, Cmd.none )

                Options.SetVolume volume ->
                    let
                        newSoundTrack =
                            capsule.soundTrack |> Maybe.map (\x -> { x | volume = volume })
                    in
                    updateModelSoundTrack capsule newSoundTrack model m

                Options.Play ->
                    case capsule.soundTrack of
                        Just _ ->
                            let
                                trackPath =
                                    Data.trackPath capsule

                                recordPath =
                                    Data.firstRecordPath capsule

                                volume =
                                    case capsule.soundTrack of
                                        Just st ->
                                            st.volume

                                        Nothing ->
                                            1.0
                            in
                            ( { model | page = App.Options { m | playPreview = True } }, playTrackPreviewPort ( trackPath, recordPath, volume ) )

                        Nothing ->
                            ( model, Cmd.none )

                Options.Stop ->
                    ( { model | page = App.Options { m | playPreview = False } }, stopTrackPreviewPort () )

                Options.EscapePressed ->
                    ( { model | page = App.Options { m | deleteTrack = Nothing } }, Cmd.none )

                Options.EnterPressed ->
                    if m.deleteTrack == Nothing then
                        ( model, Cmd.none )

                    else
                        update (Options.DeleteTrack Utils.Confirm m.deleteTrack) model

        _ ->
            ( model, Cmd.none )


{-| Changes the current webcamsettings in the model.
-}
updateModelWebcamSettings : Data.Capsule -> Data.WebcamSettings -> App.Model -> Options.Model String -> ( App.Model, Cmd App.Msg )
updateModelWebcamSettings capsule ws model _ =
    let
        newCapsule =
            { capsule | defaultWebcamSettings = ws }

        newUser =
            Data.updateUser newCapsule model.user
    in
    ( { model | user = newUser }
    , Api.updateCapsule newCapsule (\_ -> App.Noop)
    )


{-| Changes the current sound track.
-}
updateModelSoundTrack : Data.Capsule -> Maybe Data.SoundTrack -> App.Model -> Options.Model String -> ( App.Model, Cmd App.Msg )
updateModelSoundTrack capsule soundTrack model _ =
    let
        newCapsule =
            { capsule | soundTrack = soundTrack }

        newUser =
            Data.updateUser newCapsule model.user
    in
    ( { model | user = newUser }
    , Cmd.batch
        [ Api.updateCapsule newCapsule (\_ -> App.Noop)
        , volumeChangedPort (Maybe.withDefault 1.0 (Maybe.map .volume soundTrack))
        ]
    )


{-| Play the sound track.
-}
port playTrackPreviewPort : ( Maybe String, Maybe String, Float ) -> Cmd msg


{-| Stop the sound track.
-}
port stopTrackPreviewPort : () -> Cmd msg


{-| Volume changed.
-}
port volumeChangedPort : Float -> Cmd msg


{-| Subscription to record ended.
-}
port recordEnded : (Decode.Value -> msg) -> Sub msg


{-| Subscription to select a file.
-}
selectTrack : List String -> Cmd msg
selectTrack mimes =
    selectTrackPort mimes


{-| Subscription to select a file.
-}
port selectTrackPort : List String -> Cmd msg


{-| Subscription to receive the selected file.
-}
port selectedTrack : (Decode.Value -> msg) -> Sub msg


{-| Keyboard shortcuts of the options page.
-}
shortcuts : Keyboard.RawKey -> App.Msg
shortcuts msg =
    case Keyboard.rawValue msg of
        "Escape" ->
            App.OptionsMsg Options.EscapePressed

        "Enter" ->
            App.OptionsMsg Options.EnterPressed

        _ ->
            App.Noop


{-| Subscriptions of the page.
-}
subs : Sub App.Msg
subs =
    Sub.batch
        [ selectedTrack
            (\x ->
                case ( Decode.decodeValue FileValue.decoder x, Decode.decodeValue File.decoder x ) of
                    ( Ok y, Ok z ) ->
                        App.OptionsMsg (Options.TrackUploadReceived y z)

                    _ ->
                        App.Noop
            )
        , recordEnded (\_ -> App.OptionsMsg Options.Stop)
        , Keyboard.ups shortcuts
        ]
