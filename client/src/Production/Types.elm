module Production.Types exposing (..)

import Capsule exposing (Capsule)


type alias Model =
    { capsule : Capsule
    , gos : Int
    }


init : Capsule -> Int -> Model
init capsule gos =
    { capsule = capsule, gos = gos }


type WebcamSize
    = Small
    | Medium
    | Large
    | Fullscreen


sizeToInt : Maybe Capsule.Record -> WebcamSize -> ( Int, Int )
sizeToInt record webcamSize =
    let
        ( rWidth, rHeight ) =
            case Maybe.andThen .size record of
                Just ( width, height ) ->
                    ( width, height )

                _ ->
                    ( 4, 3 )

        w =
            case webcamSize of
                Small ->
                    200

                Medium ->
                    400

                Large ->
                    800

                Fullscreen ->
                    1920
    in
    ( w, w * rHeight // rWidth )


intToSize : ( Int, Int ) -> Maybe WebcamSize
intToSize pair =
    case Tuple.first pair of
        200 ->
            Just Small

        400 ->
            Just Medium

        800 ->
            Just Large

        1920 ->
            Just Fullscreen

        _ ->
            Nothing


type Msg
    = SetVideo Bool
    | WebcamSizeChanged WebcamSize
    | WebcamAnchorChanged Capsule.Anchor
    | WebcamOpacityChanged Float
    | WebcamKeyColorChanged (Maybe String)
    | ProduceVideo
    | VideoProduced
    | CancelProduction
