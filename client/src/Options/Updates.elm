module Options.Updates exposing (..)

import Api.Capsule as Api
import App.Types as App exposing (Page(..))
import Data.Capsule as Data exposing (Capsule)
import Data.User as Data
import Options.Types as Options


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
                                    Data.defaultWebcamSettings (533, 0)

                                x ->
                                    Data.Disabled
                    in
                    updateModel newWebcamSettings model m

                Options.SetOpacity opacity ->
                    let
                        newWebcamSettings =
                            case m.capsule.defaultWebcamSettings of
                                Data.Pip p ->
                                    Data.Pip { p | opacity = opacity }

                                x ->
                                    x
                    in
                    updateModel newWebcamSettings model m

                Options.SetWidth newWidth ->
                    let
                        newWebcamSettings =
                            case newWidth of
                                Nothing ->
                                    Data.setWebcamSettingsSize Nothing m.capsule.defaultWebcamSettings

                                Just width ->
                                    Data.setWebcamSettingsSize (Just ( width, 0 )) m.capsule.defaultWebcamSettings
                    in
                    updateModel newWebcamSettings model m

                Options.SetAnchor anchor ->
                    let
                        newWebcamSettings =
                            case m.capsule.defaultWebcamSettings of
                                Data.Pip p ->
                                    Data.Pip { p | anchor = anchor, position = ( 4, 4 ) }

                                x ->
                                    x
                    in
                    updateModel newWebcamSettings model { m | webcamPosition = ( 4.0, 4.0 ) }

        _ ->
            ( model, Cmd.none )


{-| Changes the current webcamsettings in the model.
-}
updateModel : Data.WebcamSettings -> App.Model -> Options.Model -> ( App.Model, Cmd App.Msg )
updateModel ws model m =
    let
        newCapsule0 =
            m.capsule

        newCapsule =
            { newCapsule0 | defaultWebcamSettings = ws }

        newUser =
            Data.updateUser newCapsule model.user
    in
    ( { model | user = newUser, page = App.Options { m | capsule = newCapsule } }
    , Api.updateCapsule newCapsule (\_ -> App.Noop)
    )
