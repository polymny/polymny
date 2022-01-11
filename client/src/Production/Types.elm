module Production.Types exposing (..)

import Capsule exposing (Capsule)


type alias Model =
    { capsule : Capsule
    , gos : Int
    , webcamPosition : ( Float, Float )
    , holdingImage : Maybe ( Int, Float, Float )
    }


init : Capsule -> Int -> Model
init capsule gosNumber =
    let
        gos : Maybe Capsule.Gos
        gos =
            List.head (List.drop gosNumber capsule.structure)

        webcamPosition : ( Float, Float )
        webcamPosition =
            case Maybe.map .webcamSettings gos of
                Just (Capsule.Pip { position }) ->
                    ( toFloat (Tuple.first position), toFloat (Tuple.second position) )

                _ ->
                    ( 0, 0 )
    in
    { capsule = capsule, gos = gosNumber, webcamPosition = webcamPosition, holdingImage = Nothing }


type WebcamSize
    = Small
    | Medium
    | Large
    | Custom Int
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

                Custom x ->
                    x

                Fullscreen ->
                    1920
    in
    ( w, w * rHeight // rWidth )


intToSize : ( Int, Int ) -> WebcamSize
intToSize pair =
    case Tuple.first pair of
        200 ->
            Small

        400 ->
            Medium

        800 ->
            Large

        1920 ->
            Fullscreen

        x ->
            Custom x


type Msg
    = SetVideo Bool
    | WebcamSizeChanged WebcamSize
    | WebcamAnchorChanged Capsule.Anchor
    | WebcamOpacityChanged Float
    | WebcamKeyColorChanged (Maybe String)
    | FadeChanged Capsule.Fade
    | HoldingImageChanged (Maybe ( Int, Float, Float ))
    | ImageMoved Float Float Float Float
    | ProduceVideo
    | ProduceGos Int
    | VideoProduced
    | CancelProduction
