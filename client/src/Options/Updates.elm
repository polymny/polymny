port module Options.Updates exposing (..)

import Api.Capsule as Api
import App.Types as App exposing (Page(..))
import Config exposing (Config)
import Data.Capsule as Data exposing (Capsule, removeTrack)
import Data.User as Data
import File
import FileValue
import Json.Decode as Decode
import Options.Types as Options exposing (init)
import RemoteData
import Utils


{-| Updates the model.
-}
update : Options.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case model.page of
        App.Options m ->
            case msg of
                Options.ToggleVideo ->
                    let
                        newWebcamSettings =
                            case m.capsule.defaultWebcamSettings of
                                Data.Disabled ->
                                    Data.defaultWebcamSettings ( 533, 0 )

                                x ->
                                    Data.Disabled
                    in
                    updateModelWebcamSettings newWebcamSettings model m

                Options.SetOpacity opacity ->
                    let
                        newWebcamSettings =
                            case m.capsule.defaultWebcamSettings of
                                Data.Pip p ->
                                    Data.Pip { p | opacity = opacity }

                                x ->
                                    x
                    in
                    updateModelWebcamSettings newWebcamSettings model m

                Options.SetWidth newWidth ->
                    let
                        newWebcamSettings =
                            case newWidth of
                                Nothing ->
                                    Data.setWebcamSettingsSize Nothing m.capsule.defaultWebcamSettings

                                Just width ->
                                    Data.setWebcamSettingsSize (Just ( width, 0 )) m.capsule.defaultWebcamSettings
                    in
                    updateModelWebcamSettings newWebcamSettings model m

                Options.SetAnchor anchor ->
                    let
                        newWebcamSettings =
                            case m.capsule.defaultWebcamSettings of
                                Data.Pip p ->
                                    Data.Pip { p | anchor = anchor, position = ( 4, 4 ) }

                                x ->
                                    x
                    in
                    updateModelWebcamSettings newWebcamSettings model { m | webcamPosition = ( 4.0, 4.0 ) }

                Options.TrackUploadRequested ->
                    ( model, selectTrack [ "audio/*" ] )

                Options.TrackUploadReceived fileValue file ->
                    let
                        isAudio =
                            fileValue.mime |> String.startsWith "audio/"
                    in
                    if isAudio then
                        let
                            newPage =
                                App.Options { m | deleteTrack = Nothing, capsuleUpdate = RemoteData.Loading Nothing }
                        in
                        ( { model | page = newPage }
                        , Api.uploadTrack
                            { capsule = m.capsule
                            , fileValue = fileValue
                            , file = file
                            , toMsg = \x -> App.OptionsMsg (Options.TrackUpload x)
                            }
                        )

                    else
                        ( model, Cmd.none )

                Options.TrackUploadResponded response ->
                    ( model, Cmd.none )

                Options.DeleteTrack Utils.Request track ->
                    case m.capsule.soundTrack of
                        Just _ ->
                            ( { model | page = App.Options { m | deleteTrack = track } }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                Options.DeleteTrack Utils.Cancel _ ->
                    case m.capsule.soundTrack of
                        Just _ ->
                            ( { model | page = App.Options { m | deleteTrack = Nothing } }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                Options.DeleteTrack Utils.Confirm track ->
                    let
                        capsule =
                            Data.removeTrack m.capsule

                        ( sync, newConfig ) =
                            ( Api.updateCapsule capsule
                                (\_ -> App.OptionsMsg (Options.CapsuleUpdate model.config.clientState.lastRequest (RemoteData.Success capsule)))
                            , Config.incrementRequest model.config
                            )
                    in
                    ( { model
                        | user = Data.updateUser capsule model.user
                        , page = App.Options (Options.init capsule)
                        , config = newConfig
                      }
                    , sync
                    )

                Options.TrackUpload (RemoteData.Success c) ->
                    ( { model
                        | page = App.Options { m | capsule = c, capsuleUpdate = RemoteData.Success c }
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
                        soundTrack =
                            m.capsule.soundTrack

                        newSoundTrack =
                            case soundTrack of
                                Just st ->
                                    Just { st | volume = volume }

                                Nothing ->
                                    Nothing
                    in
                    updateModelSoundTrack newSoundTrack model m

                Options.Play ->
                    case m.capsule.soundTrack of
                        Just _ ->
                            let
                                track_path =
                                    Data.trackPath m.capsule

                                record_path =
                                    Data.firstRecordPath m.capsule

                                volume =
                                    case m.capsule.soundTrack of
                                        Just st ->
                                            st.volume

                                        Nothing ->
                                            1.0
                            in
                            ( model, playTrackPreviewPort ( track_path, record_path, volume ) )

                        Nothing ->
                            ( model, Cmd.none )

                Options.Stop ->
                    ( model, stopTrackPreviewPort () )

        _ ->
            ( model, Cmd.none )


{-| Changes the current webcamsettings in the model.
-}
updateModelWebcamSettings : Data.WebcamSettings -> App.Model -> Options.Model -> ( App.Model, Cmd App.Msg )
updateModelWebcamSettings ws model m =
    let
        capsule =
            m.capsule

        newCapsule =
            { capsule | defaultWebcamSettings = ws }

        newUser =
            Data.updateUser newCapsule model.user
    in
    ( { model | user = newUser, page = App.Options { m | capsule = newCapsule } }
    , Api.updateCapsule newCapsule (\_ -> App.Noop)
    )


{-| Changes the current sound track.
-}
updateModelSoundTrack : Maybe Data.SoundTrack -> App.Model -> Options.Model -> ( App.Model, Cmd App.Msg )
updateModelSoundTrack sound_track model m =
    let
        capsule =
            m.capsule

        newCapsule =
            { capsule | soundTrack = sound_track }

        newUser =
            Data.updateUser newCapsule model.user
    in
    ( { model | user = newUser, page = App.Options { m | capsule = newCapsule } }
    , Cmd.batch
        [ Api.updateCapsule newCapsule (\_ -> App.Noop)
        , volumeChangedPort (Maybe.withDefault 1.0 (Maybe.map .volume sound_track))
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


{-| Subscriptions of the page.
-}
subs : Sub App.Msg
subs =
    selectedTrack
        (\x ->
            case ( Decode.decodeValue FileValue.decoder x, Decode.decodeValue File.decoder x ) of
                ( Ok y, Ok z ) ->
                    App.OptionsMsg (Options.TrackUploadReceived y z)

                _ ->
                    App.Noop
        )
