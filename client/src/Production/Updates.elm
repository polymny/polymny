port module Production.Updates exposing (..)

{-| This module deals with the updates of the production page.
-}

import Api.Capsule as Api
import App.Types as App
import App.Utils as App
import Browser.Events
import Config
import Data.Capsule as Data exposing (Capsule)
import Data.Types as Data
import Data.User as Data
import Json.Decode as Decode
import Material.Icons exposing (anchor)
import Production.Types as Production exposing (getWebcamSettings)


{-| Updates the model.
-}
update : Production.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    let
        ( maybeCapsule, maybeGos ) =
            App.capsuleAndGos model.user model.page
    in
    case ( model.page, maybeCapsule, maybeGos ) of
        ( App.Production m, Just capsule, Just gos ) ->
            let
                recordSize : Maybe ( Int, Int )
                recordSize =
                    Maybe.andThen .size gos.record
            in
            case msg of
                Production.ResetOptions ->
                    let
                        newPosition : ( Float, Float )
                        newPosition =
                            case capsule.defaultWebcamSettings of
                                Data.Pip { position } ->
                                    Tuple.mapBoth toFloat toFloat position

                                _ ->
                                    ( 0.0, 0.0 )
                    in
                    updateModel capsule (resetOptions gos) model { m | webcamPosition = newPosition }

                Production.ToggleVideo ->
                    let
                        newWebcamSettings =
                            case ( recordSize, getWebcamSettings capsule gos ) of
                                ( Just size, Data.Disabled ) ->
                                    Nothing

                                _ ->
                                    Just Data.Disabled
                    in
                    updateModel capsule { gos | webcamSettings = newWebcamSettings } model m

                Production.SetAnchor anchor ->
                    let
                        newWebcamSettings =
                            case getWebcamSettings capsule gos of
                                Data.Pip p ->
                                    Data.Pip { p | anchor = anchor, position = ( 4, 4 ) }

                                x ->
                                    x
                    in
                    updateModel capsule { gos | webcamSettings = Just newWebcamSettings } model { m | webcamPosition = ( 4.0, 4.0 ) }

                Production.SetOpacity opacity ->
                    let
                        newWebcamSettings =
                            case getWebcamSettings capsule gos of
                                Data.Pip p ->
                                    Data.Pip { p | opacity = opacity }

                                x ->
                                    x
                    in
                    updateModel capsule { gos | webcamSettings = Just newWebcamSettings } model m

                Production.SetWidth newWidth ->
                    let
                        newWebcamSettings =
                            case ( recordSize, newWidth ) of
                                ( Just _, Nothing ) ->
                                    Data.setWebcamSettingsSize Nothing (getWebcamSettings capsule gos)

                                ( Just size, Just width ) ->
                                    Production.setWidth width size
                                        |> (\x -> Data.setWebcamSettingsSize (Just x) (getWebcamSettings capsule gos))

                                _ ->
                                    getWebcamSettings capsule gos
                    in
                    updateModel capsule { gos | webcamSettings = Just newWebcamSettings } model m

                Production.HoldingImageChanged Nothing ->
                    -- User released mouse, update capsule
                    let
                        newWebcamSettings =
                            case getWebcamSettings capsule gos of
                                Data.Pip p ->
                                    Data.Pip { p | position = Tuple.mapBoth round round m.webcamPosition }

                                x ->
                                    x
                    in
                    updateModel capsule { gos | webcamSettings = Just newWebcamSettings } model { m | holdingImage = Nothing }

                Production.HoldingImageChanged (Just ( id, x, y )) ->
                    ( { model | page = App.Production { m | holdingImage = Just ( id, x, y ) } }
                    , setPointerCapture id
                    )

                Production.ImageMoved x y newPageX newPageY ->
                    let
                        newModel =
                            case ( getWebcamSettings capsule gos, m.holdingImage ) of
                                ( Data.Pip { anchor }, Just ( id, _, _ ) ) ->
                                    let
                                        motion =
                                            case anchor of
                                                Data.TopLeft ->
                                                    ( x, y )

                                                Data.TopRight ->
                                                    ( -x, y )

                                                Data.BottomLeft ->
                                                    ( x, -y )

                                                Data.BottomRight ->
                                                    ( -x, -y )

                                        newPosition =
                                            ( Tuple.first m.webcamPosition + Tuple.first motion
                                            , Tuple.second m.webcamPosition + Tuple.second motion
                                            )
                                    in
                                    { m | webcamPosition = newPosition, holdingImage = Just ( id, newPageX, newPageY ) }

                                _ ->
                                    m
                    in
                    ( { model | page = App.Production newModel }, Cmd.none )

                Production.Produce ->
                    let
                        newCapsule : Capsule
                        newCapsule =
                            { capsule | produced = Data.Running Nothing }

                        task : Config.TaskStatus
                        task =
                            { task = Config.Production model.config.clientState.taskId capsule.id
                            , progress = Just 0.0
                            , finished = False
                            , aborted = False
                            , global = True
                            }

                        ( newConfig, _ ) =
                            Config.update (Config.UpdateTaskStatus task) model.config

                        newModel : App.Model
                        newModel =
                            { model
                                | user =
                                    Data.updateUser
                                        { capsule
                                            | produced = Data.Running (Just 0.0)
                                            , published = Data.Idle
                                        }
                                        model.user
                                , config = Config.incrementTaskId newConfig
                            }
                    in
                    ( newModel, Api.produceCapsule capsule (\_ -> App.Noop) )

        _ ->
            ( model, Cmd.none )


{-| Changes the current gos in the model.
-}
updateModel : Data.Capsule -> Data.Gos -> App.Model -> Production.Model String Int -> ( App.Model, Cmd App.Msg )
updateModel capsule gos model m =
    let
        newCapsule =
            updateGos m.gos gos capsule

        newUser =
            Data.updateUser newCapsule model.user
    in
    ( { model | user = newUser, page = App.Production m }, Api.updateCapsule newCapsule (\_ -> App.Noop) )


{-| Reset to default options. (Set to Nothing)
-}
resetOptions : Data.Gos -> Data.Gos
resetOptions gos =
    { gos | webcamSettings = Nothing }


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


type alias Event =
    { oldPageX : Float
    , oldPageY : Float
    , newPageX : Float
    , newPageY : Float
    , clientWidth : Float
    , clientHeight : Float
    }


toMsg : ( Float, Float ) -> Event -> App.Msg
toMsg ( w, h ) event =
    let
        x =
            (event.newPageX - event.oldPageX) / event.clientWidth * w

        y =
            (event.newPageY - event.oldPageY) / event.clientHeight * h
    in
    App.ProductionMsg (Production.ImageMoved x y event.newPageX event.newPageY)


subs : Production.Model Data.Capsule Data.Gos -> Sub App.Msg
subs model =
    case model.holdingImage of
        Nothing ->
            Sub.none

        Just ( _, oldPageX, oldPageY ) ->
            let
                imageSize : ( Float, Float )
                imageSize =
                    case getWebcamSettings model.capsule model.gos of
                        Data.Pip { size } ->
                            Tuple.mapBoth toFloat toFloat size

                        _ ->
                            ( 0, 0 )
            in
            Decode.map6 Event
                (Decode.succeed oldPageX)
                (Decode.succeed oldPageY)
                (Decode.field "pageX" Decode.float)
                (Decode.field "pageY" Decode.float)
                (Decode.field "target" (Decode.field "clientWidth" Decode.float))
                (Decode.field "target" (Decode.field "clientHeight" Decode.float))
                |> Decode.map (toMsg imageSize)
                |> Browser.Events.onMouseMove


setPointerCapture : Int -> Cmd msg
setPointerCapture id =
    setPointerCapturePort ( Production.miniatureId, id )


port setPointerCapturePort : ( String, Int ) -> Cmd msg
