module Preparation.Views exposing (view)

{-| The main view for the preparation page.

@docs view

-}

import App.Types as App
import Config exposing (Config)
import Data.Capsule as Data
import Data.User exposing (User)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Preparation.Types as Preparation
import Strings
import Ui.Colors as Colors
import Ui.Utils as Ui
import Utils


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
        |> List.map (gosView config user model)
        |> Element.column [ Ui.wf ]


gosView : Config -> User -> Preparation.Model -> List Preparation.MaybeSlide -> Element App.Msg
gosView config user model gos =
    case gos of
        [ Preparation.GosId gosId ] ->
            Element.none
                |> Element.el [ Ui.wf, Ui.bb 1, Border.color Colors.greyBorder ]
                |> Element.el [ Ui.wf, Ui.py 20 ]

        _ ->
            gos
                |> Utils.regroupFixed config.clientConfig.zoomLevel
                |> List.map (List.map (slideView config user model))
                |> List.map (Element.row [ Ui.wf ])
                |> Element.row [ Ui.wf ]


slideView : Config -> User -> Preparation.Model -> Maybe Preparation.MaybeSlide -> Element App.Msg
slideView config user model s =
    case s of
        Just (Preparation.Slide { gosId, slideId, slide }) ->
            let
                inFront =
                    Element.el [ Ui.p 5, Ui.rbr 5, Background.color Colors.greyBorder ]
                        (Strings.dataCapsuleGrain config.clientState.lang 1
                            ++ " "
                            ++ String.fromInt (gosId + 1)
                            ++ " / "
                            ++ Strings.dataCapsuleSlide config.clientState.lang 1
                            ++ " "
                            ++ String.fromInt (slideId + 1)
                            |> Element.text
                        )
            in
            Element.el [ Ui.wf, Ui.pl 20 ]
                (Element.image [ Ui.wf, Ui.b 1, Border.color Colors.greyBorder, Element.inFront inFront ]
                    { src = Data.slidePath model.capsule slide
                    , description = ""
                    }
                )

        Just (Preparation.GosId _) ->
            Element.none

        _ ->
            Element.el [ Ui.wf, Ui.pl 20 ] Element.none
