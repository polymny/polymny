module Preparation.Updates exposing (update, subs)

{-| This module contains the update function for the preparation page.

@docs update, subs

-}

import Api.Capsule as Api
import App.Types as App
import Config exposing (Config)
import Data.Capsule as Data
import Dict exposing (Dict)
import List.Extra
import Preparation.Types as Preparation
import RemoteData
import Triplet


{-| The update function of the preparation page.
-}
update : Preparation.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case model.page of
        App.Preparation m ->
            case msg of
                Preparation.DnD sMsg ->
                    updateDnD sMsg m model.config
                        |> Tuple.mapFirst (\( x, y ) -> { model | page = App.Preparation x })

                Preparation.CapsuleUpdate id data ->
                    if model.config.clientState.lastRequest == id + 1 then
                        ( { model | page = App.Preparation { m | capsuleUpdate = data } }, Cmd.none )

                    else
                        ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


{-| The update function for the DnD part of the page.
-}
updateDnD : Preparation.DnDMsg -> Preparation.Model -> Config -> ( ( Preparation.Model, Config ), Cmd App.Msg )
updateDnD msg model config =
    case msg of
        Preparation.SlideMoved sMsg ->
            let
                capsule =
                    model.capsule

                pre =
                    Preparation.slideSystem.info model.slideModel

                ( slideModel, slides ) =
                    Preparation.slideSystem.update sMsg model.slideModel model.slides

                post =
                    Preparation.slideSystem.info slideModel

                dropped =
                    pre /= Nothing && post == Nothing

                ( ( broken, newStructure ), newSlides ) =
                    case ( pre, post ) of
                        ( Just _, Nothing ) ->
                            let
                                extracted =
                                    extractStructure slides
                            in
                            ( fixStructure model.capsule.structure extracted
                            , extracted |> List.map .slides |> Preparation.setupSlides
                            )

                        _ ->
                            ( ( False, model.capsule.structure ), slides )

                ( syncCmd, newConfig ) =
                    if dropped && model.capsule.structure /= newStructure then
                        ( Api.updateCapsule { capsule | structure = newStructure } (\x -> App.Noop)
                        , Config.incrementRequest config
                        )

                    else
                        ( Cmd.none, config )
            in
            ( ( { model | slideModel = slideModel, slides = newSlides }, config )
            , Cmd.batch
                [ syncCmd
                , Preparation.slideSystem.commands slideModel
                    |> Cmd.map (\x -> App.PreparationMsg (Preparation.DnD x))
                ]
            )

        Preparation.GosMoved sMsg ->
            ( ( model, config ), Cmd.none )


{-| Creates a dummy capsule structure given a list of slides.
-}
extractStructure : List Preparation.Slide -> List Data.Gos
extractStructure slides =
    slides
        |> List.Extra.gatherWith (\a b -> a.totalGosId == b.totalGosId)
        |> List.map (\( a, b ) -> a :: b)
        |> List.map (List.filterMap .slide)
        |> List.filter (\x -> x /= [])
        |> List.map Data.gosFromSlides


{-| Retrieves the information in the structure from the old structure given a structure that contains only slides.

Returns the new structure as well as a boolean indicating if records have been lost.

-}
fixStructure : List Data.Gos -> List Data.Gos -> ( Bool, List Data.Gos )
fixStructure old new =
    let
        -- The dict that associates the list of slides id to the gos in the previous list of gos
        oldGos : Dict (List String) Data.Gos
        oldGos =
            Dict.fromList (List.map (\x -> ( List.map .uuid x.slides, x )) old)

        -- The dict that associates the list of slides id to the gos in the new
        -- list of gos, which doesn't contain any records or other stuff
        newGos : Dict (List String) Data.Gos
        newGos =
            Dict.fromList (List.map (\x -> ( List.map .uuid x.slides, x )) new)

        -- Retrieves the old gos from the new gos, allownig to get the record and other stuff back
        fix : Data.Gos -> Data.Gos
        fix gos =
            case Dict.get (List.map .uuid gos.slides) oldGos of
                Nothing ->
                    gos

                Just x ->
                    x

        -- Retrieves the new gos from the old gos, if not found and the old gos
        -- has records and stuff, it will be lost
        isBroken : Data.Gos -> Bool
        isBroken gos =
            case ( Dict.get (List.map .uuid gos.slides) newGos, gos.record ) of
                -- if not found but the previous gos has a record, the record will be lost
                ( Nothing, Just _ ) ->
                    True

                -- otherwise, everything is fine
                _ ->
                    False

        broken =
            List.any isBroken old

        ret =
            List.map fix new
    in
    ( broken, ret )


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
