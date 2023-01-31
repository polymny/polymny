module Production.Types exposing (..)

{-| This module contains the production page of the app.
-}

import Data.Capsule as Data exposing (Capsule)


{-| Model type of the production page.
-}
type alias Model =
    { capsule : Capsule
    , gosId : Int
    , gos : Data.Gos
    , webcamPosition : ( Float, Float )
    , holdingImage : Maybe ( Int, Float, Float )
    }


{-| Initializes a model from the capsule and gos is.
-}
init : Int -> Capsule -> Maybe ( Model, Cmd Msg )
init gos capsule =
    case List.drop gos capsule.structure of
        h :: _ ->
            let
                webcamPosition =
                    case h.webcamSettings of
                        Data.Pip { position } ->
                            Tuple.mapBoth toFloat toFloat position

                        _ ->
                            ( 0.0, 0.0 )
            in
            Just
                ( { capsule = capsule
                  , gos = h
                  , gosId = gos
                  , webcamPosition = webcamPosition
                  , holdingImage = Nothing
                  }
                , Cmd.none
                )

        _ ->
            Nothing


{-| Message type of the app.
-}
type Msg
    = ToggleVideo
    | SetWidth (Maybe Int) -- Nothing means fullscreen
    | SetAnchor Data.Anchor
    | SetOpacity Float
    | ImageMoved Float Float Float Float
    | HoldingImageChanged (Maybe ( Int, Float, Float ))
    | Produce


{-| Changes the height preserving aspect ratio.
-}
setHeight : Int -> ( Int, Int ) -> ( Int, Int )
setHeight newHeight ( width, height ) =
    ( width * newHeight // height, newHeight )


{-| Changes the width preserving aspect ratio.
-}
setWidth : Int -> ( Int, Int ) -> ( Int, Int )
setWidth newWidth ( width, height ) =
    ( newWidth, height * newWidth // width )


{-| The ID of the miniature of the webcam.
-}
miniatureId : String
miniatureId =
    "webcam-miniature"
