module Production.Subscriptions exposing (subscriptions)

import Browser.Events
import Capsule
import Core.Types as Core
import Json.Decode as Decode
import Production.Types as Production


type alias Event =
    { oldPageX : Float
    , oldPageY : Float
    , newPageX : Float
    , newPageY : Float
    , clientWidth : Float
    , clientHeight : Float
    }


toMsg : ( Float, Float ) -> Event -> Core.Msg
toMsg ( w, h ) event =
    let
        x =
            (event.newPageX - event.oldPageX) / event.clientWidth * w

        y =
            (event.newPageY - event.oldPageY) / event.clientHeight * h
    in
    Core.ProductionMsg (Production.ImageMoved x y event.newPageX event.newPageY)


subscriptions : Production.Model -> Sub Core.Msg
subscriptions model =
    case model.holdingImage of
        Nothing ->
            Sub.none

        Just ( _, oldPageX, oldPageY ) ->
            let
                gos : Maybe Capsule.Gos
                gos =
                    List.head (List.drop model.gos model.capsule.structure)

                imageSize : ( Float, Float )
                imageSize =
                    case Maybe.map .webcamSettings gos of
                        Just (Capsule.Pip { size }) ->
                            ( toFloat (Tuple.first size), toFloat (Tuple.second size) )

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
