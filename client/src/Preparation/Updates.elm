module Preparation.Updates exposing (update, subs)

{-| This module contains the update function for the preparation page.

@docs update, subs

-}

import App.Types as App
import List.Extra
import Preparation.Types as Preparation


{-| The update function of the preparation page.
-}
update : Preparation.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case model.page of
        App.Preparation m ->
            case msg of
                Preparation.DnD sMsg ->
                    updateDnD sMsg m
                        |> Tuple.mapFirst (\x -> { model | page = App.Preparation x })
                        |> Tuple.mapSecond (Cmd.map (\x -> App.PreparationMsg (Preparation.DnD x)))

        _ ->
            ( model, Cmd.none )


{-| The update function for the DnD part of the page.
-}
updateDnD : Preparation.DnDMsg -> Preparation.Model -> ( Preparation.Model, Cmd Preparation.DnDMsg )
updateDnD msg model =
    case msg of
        Preparation.SlideMoved sMsg ->
            let
                pre =
                    Preparation.slideSystem.info model.slideModel

                ( slideModel, slides ) =
                    Preparation.slideSystem.update sMsg model.slideModel model.slides

                post =
                    Preparation.slideSystem.info slideModel

                newSlides =
                    case ( pre, post ) of
                        ( Just _, Nothing ) ->
                            slides
                                |> List.Extra.gatherWith (\a b -> a.totalGosId == b.totalGosId)
                                |> List.map (\( h, t ) -> h :: t)
                                |> List.map (List.filterMap .slide)
                                |> List.filter (\x -> x /= [])
                                |> Preparation.setupSlides

                        _ ->
                            slides
            in
            ( { model | slideModel = slideModel, slides = newSlides }
            , Preparation.slideSystem.commands slideModel
            )

        Preparation.GosMoved sMsg ->
            ( model, Cmd.none )


{-| Subscriptions for the prepration view.
-}
subs : Preparation.Model -> Sub App.Msg
subs model =
    Sub.batch
        [ Preparation.slideSystem.subscriptions model.slideModel
        , Preparation.gosSystem.subscriptions model.gosModel
        ]
        |> Sub.map Preparation.DnD
        |> Sub.map App.PreparationMsg
