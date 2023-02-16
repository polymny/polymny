port module Production.Updates exposing (..)

{-| This module deals with the updates of the production page.
-}

import Api.Capsule as Api
import App.Types as App
import Browser.Events
import Data.Capsule as Data exposing (Capsule)
import Data.User as Data
import Json.Decode as Decode
import Production.Types as Production exposing (getWebcamSettings)


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
                Production.ResetOptions ->
                    updateModel (resetOptions gos) model m

                Production.ToggleVideo ->
                    let
                        newWebcamSettings =
                            case ( recordSize, getWebcamSettings gos m ) of
                                ( Just size, Data.Disabled ) ->
                                    Data.defaultWebcamSettings (Production.setWidth 533 size)

                                _ ->
                                    Data.Disabled
                    in
                    updateModel { gos | webcamSettings = Just newWebcamSettings } model m

                Production.SetAnchor anchor ->
                    let
                        newWebcamSettings =
                            case getWebcamSettings gos m of
                                Data.Pip p ->
                                    Data.Pip { p | anchor = anchor, position = ( 4, 4 ) }

                                x ->
                                    x
                    in
                    updateModel { gos | webcamSettings = Just newWebcamSettings } model { m | webcamPosition = ( 4.0, 4.0 ) }

                Production.SetOpacity opacity ->
                    let
                        newWebcamSettings =
                            case getWebcamSettings gos m of
                                Data.Pip p ->
                                    Data.Pip { p | opacity = opacity }

                                x ->
                                    x
                    in
                    updateModel { gos | webcamSettings = Just newWebcamSettings } model m

                Production.SetWidth newWidth ->
                    let
                        newWebcamSettings =
                            case ( recordSize, newWidth ) of
                                ( Just _, Nothing ) ->
                                    Data.setWebcamSettingsSize Nothing (getWebcamSettings gos m)

                                ( Just size, Just width ) ->
                                    Production.setWidth width size
                                        |> (\x -> Data.setWebcamSettingsSize (Just x) (getWebcamSettings gos m))

                                _ ->
                                    getWebcamSettings gos m
                    in
                    updateModel { gos | webcamSettings = Just newWebcamSettings } model m

                Production.HoldingImageChanged Nothing ->
                    -- User released mouse, update capsule
                    let
                        newWebcamSettings =
                            case getWebcamSettings gos m of
                                Data.Pip p ->
                                    Data.Pip { p | position = Tuple.mapBoth round round m.webcamPosition }

                                x ->
                                    x
                    in
                    updateModel { gos | webcamSettings = Just newWebcamSettings } model { m | holdingImage = Nothing }

                Production.HoldingImageChanged (Just ( id, x, y )) ->
                    ( { model | page = App.Production { m | holdingImage = Just ( id, x, y ) } }
                    , setPointerCapture id
                    )

                Production.ImageMoved x y newPageX newPageY ->
                    let
                        newModel =
                            case ( getWebcamSettings gos m, m.holdingImage ) of
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

        newUser =
            Data.updateUser newCapsule model.user
    in
    ( { model | user = newUser, page = App.Production { m | capsule = newCapsule, gos = gos } }
    , Api.updateCapsule newCapsule (\_ -> App.Noop)
    )


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


subs : Production.Model -> Sub App.Msg
subs model =
    case model.holdingImage of
        Nothing ->
            Sub.none

        Just ( _, oldPageX, oldPageY ) ->
            let
                imageSize : ( Float, Float )
                imageSize =
                    case getWebcamSettings model.gos model of
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
