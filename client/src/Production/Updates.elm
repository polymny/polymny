module Production.Updates exposing (..)

{-| This module deals with the updates of the production page.
-}

import Api.Capsule as Api
import App.Types as App
import Data.Capsule as Data exposing (Capsule)
import Production.Types as Production


{-| Updates the model.
-}
update : Production.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case model.page of
        App.Production m ->
            let
                gos =
                    m.gos

                recordSize : Maybe ( Int, Int )
                recordSize =
                    Maybe.andThen .size gos.record
            in
            case msg of
                Production.ToggleVideo ->
                    let
                        newWebcamSettings =
                            case ( recordSize, gos.webcamSettings ) of
                                ( Just size, Data.Disabled ) ->
                                    Data.defaultWebcamSettings (Production.setWidth 533 size)

                                _ ->
                                    Data.Disabled
                    in
                    updateModel { gos | webcamSettings = newWebcamSettings } model m

                Production.SetWidth newWidth ->
                    let
                        newWebcamSettings =
                            case ( recordSize, newWidth ) of
                                ( Just _, Nothing ) ->
                                    Data.setWebcamSettingsSize Nothing gos.webcamSettings

                                ( Just size, Just width ) ->
                                    Production.setWidth width size
                                        |> (\x -> Data.setWebcamSettingsSize (Just x) gos.webcamSettings)

                                _ ->
                                    gos.webcamSettings
                    in
                    updateModel { gos | webcamSettings = newWebcamSettings } model m

                Production.Produce ->
                    ( model, Api.produceCapsule m.capsule (\_ -> App.Noop) )

        _ ->
            ( model, Cmd.none )


{-| Changes the current gos in the model.
-}
updateModel : Data.Gos -> App.Model -> Production.Model -> ( App.Model, Cmd App.Msg )
updateModel gos model m =
    let
        newCapsule =
            updateGos m.gosId gos m.capsule
    in
    ( { model | page = App.Production { m | capsule = newCapsule, gos = gos } }, Cmd.none )



-- , Api.updateCapsule Core.Noop newCapsule


{-| Changes the gos in a capsule.
-}
updateGos : Int -> Data.Gos -> Capsule -> Capsule
updateGos id gos capsule =
    let
        newStructure =
            List.indexedMap
                (\i g ->
                    if i == id then
                        gos

                    else
                        g
                )
                capsule.structure

        oldCapsule =
            capsule
    in
    { oldCapsule | structure = newStructure }
