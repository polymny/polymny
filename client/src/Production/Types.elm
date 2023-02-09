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
                        Just (Data.Pip { position }) ->
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
    | ResetOptions


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


{-| Get webcam settings from the gos and model.
-}
getWebcamSettings : Data.Gos -> Model -> Data.WebcamSettings
getWebcamSettings gos model =
    let
        -- Get record size
        recordSize =
            case model.gos.record of
                Just r ->
                    case r.size of
                        Just s ->
                            s

                        Nothing ->
                            ( 1, 1 )

                Nothing ->
                    ( 1, 1 )

        -- Get default size
        defaultSize =
            case model.capsule.defaultWebcamSettings of
                Data.Pip s ->
                    s.size

                _ ->
                    ( 1, 1 )

        -- Reset size
        resetSize =
            let
                recoardWidth =
                    recordSize |> Tuple.first |> toFloat

                recoardHeight =
                    recordSize |> Tuple.second |> toFloat

                ratio =
                    recoardWidth / recoardHeight

                defaultWidth =
                    defaultSize |> Tuple.first |> toFloat

                newHeight =
                    defaultWidth / ratio
            in
            ( defaultWidth |> round, newHeight |> round )

        -- Get webcam settings
        webcamSettings =
            case gos.webcamSettings of
                Just s ->
                    s

                Nothing ->
                    -- Create webcam settings from default with good size
                    case model.capsule.defaultWebcamSettings of
                        Data.Pip s ->
                            Data.Pip
                                { anchor = s.anchor
                                , keycolor = s.keycolor
                                , opacity = s.opacity
                                , position = s.position
                                , size = resetSize
                                }

                        _ ->
                            model.capsule.defaultWebcamSettings
    in
    webcamSettings