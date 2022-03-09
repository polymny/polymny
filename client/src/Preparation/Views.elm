module Preparation.Views exposing (view)

{-| The main view for the preparation page.

@docs view

-}

import App.Types as App
import Config exposing (Config)
import Data.Capsule as Data
import Data.User exposing (User)
import DnDList
import DnDList.Groups
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Html.Attributes
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


{-| Displays a grain.
-}
gosView : Config -> User -> Preparation.Model -> List Preparation.MaybeSlide -> Element App.Msg
gosView config user model gos =
    case gos of
        [ Preparation.GosId gosId ] ->
            Element.none
                |> Element.el [ Ui.wf, Ui.bb 1, Border.color Colors.greyBorder ]
                |> Element.el [ Ui.wf, Ui.hf, Ui.py 20, Ui.id ("slide-" ++ String.fromInt gosId.totalSlideId) ]
                |> Element.el [ Ui.wf, Ui.id ("gos-" ++ String.fromInt gosId.totalGosId) ]

        (Preparation.GosId gosId) :: _ ->
            gos
                |> Utils.regroupFixed config.clientConfig.zoomLevel
                |> List.map (List.map (slideView config user model))
                |> List.map (Element.row [ Ui.wf ])
                |> Element.row [ Ui.wf, Ui.id ("gos-" ++ String.fromInt gosId.totalGosId) ]

        _ ->
            -- This should be unreachable
            Element.none


{-| Displays a slide.
-}
slideView : Config -> User -> Preparation.Model -> Maybe Preparation.MaybeSlide -> Element App.Msg
slideView config user model s =
    case s of
        Just (Preparation.Slide { gosId, slideId, totalSlideId, slide }) ->
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
            Element.el [ Ui.wf, Ui.pl 20, Ui.id ("slide-" ++ String.fromInt totalSlideId) ]
                (Element.image [ Ui.wf, Ui.b 1, Border.color Colors.greyBorder, Element.inFront inFront ]
                    { src = Data.slidePath model.capsule slide
                    , description = ""
                    }
                )

        Just (Preparation.GosId _) ->
            Element.none

        _ ->
            Element.el [ Ui.wf, Ui.pl 20 ] Element.none


{-| A helper type to help us deal with the DnD events.
-}
type DragOptions
    = Drag
    | Drop
    | Ghost
    | None


{-| A function that gives the corresponding attributes for slides.
-}
slideStyle : DnDList.Groups.Model -> Slide -> DragOptions -> List (Element.Attribute App.Msg)
slideStyle model slide options =
    (case options of
        Drag ->
            Preparation.slideSystem.dragEvents slide.totalSlideId ("slide-" ++ String.fromInt slide.totalSlideId)

        Drop ->
            Preparation.slideSystem.dropEvents slide.totalSlideId ("slide-" ++ String.fromInt slide.totalSlideId)

        Ghost ->
            Preparation.slideSystem.ghostStyles model

        None ->
            []
    )
        |> List.map Element.htmlAttribute
        |> List.map (Element.mapAttribute (\x -> App.PreparationMsg (Preparation.DnD x)))


{-| A function that gives the corresponding attributes for gos.
-}
gosStyle : DnDList.Model -> GosId -> DragOptions -> List (Element.Attribute App.Msg)
gosStyle model gos options =
    (case options of
        Drag ->
            Preparation.gosSystem.dragEvents gos.totalGosId ("gos-" ++ String.fromInt gos.totalGosId)

        Drop ->
            Preparation.gosSystem.dropEvents gos.totalGosId ("gos-" ++ String.fromInt gos.totalGosId)

        Ghost ->
            Preparation.gosSystem.ghostStyles model

        None ->
            []
    )
        |> List.map Element.htmlAttribute
        |> List.map (Element.mapAttribute (\x -> App.PreparationMsg (Preparation.DnD x)))


{-| A helper type to easily describe the content of a MaybeSlide that is a slide.
-}
type alias Slide =
    { gosId : Int
    , totalGosId : Int
    , slideId : Int
    , totalSlideId : Int
    , slide : Data.Slide
    }


{-| A helper type to easily describe the content of a MaybeSlide that is a GosId.
-}
type alias GosId =
    { gosId : Int
    , totalGosId : Int
    , totalSlideId : Int
    }
