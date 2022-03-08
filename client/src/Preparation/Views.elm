module Preparation.Views exposing (view)

{-| The main view for the preparation page.

@docs view

-}

import App.Types as App
import Config exposing (Config)
import Data.Capsule as Data
import Data.User exposing (User)
import Element exposing (Element)
import Preparation.Types as Preparation
import Ui.Utils as Ui


{-| The view function for the preparation page.
-}
view : Config -> User -> Preparation.Model -> Element App.Msg
view config user model =
    let
        v0 : Preparation.MaybeSlide -> Element App.Msg
        v0 s =
            case s of
                Preparation.GosId { gosId, totalGosId, totalSlideId } ->
                    "GosId { "
                        ++ String.fromInt gosId
                        ++ ", "
                        ++ String.fromInt totalGosId
                        ++ ", "
                        ++ String.fromInt totalSlideId
                        ++ "}"
                        |> Element.text

                Preparation.Slide { gosId, totalGosId, slideId, totalSlideId, slide } ->
                    Element.row [ Element.spacing 10 ]
                        [ "Slide { "
                            ++ String.fromInt gosId
                            ++ ", "
                            ++ String.fromInt totalGosId
                            ++ ", "
                            ++ String.fromInt slideId
                            ++ ", "
                            ++ String.fromInt totalSlideId
                            ++ "}"
                            |> Element.text
                        , Element.image [ Ui.wpx 150 ]
                            { src = Data.slidePath model.capsule slide
                            , description = ""
                            }
                        ]
    in
    model.slides
        |> List.map (List.map v0)
        |> List.map (Element.row [ Element.spacing 10 ])
        |> Element.column [ Element.spacing 10 ]
