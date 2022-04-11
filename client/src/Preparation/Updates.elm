module Preparation.Updates exposing (update, subs)

{-| This module contains the update function for the preparation page.

@docs update, subs

-}

import Api.Capsule as Api
import App.Types as App
import Config exposing (Config)
import Data.Capsule as Data
import Dict exposing (Dict)
import File
import File.Select as Select
import List.Extra
import Preparation.Types as Preparation
import RemoteData
import Utils


{-| The update function of the preparation page.
-}
update : Preparation.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case model.page of
        App.Preparation m ->
            case msg of
                Preparation.DnD sMsg ->
                    updateDnD sMsg m model.config
                        |> Tuple.mapFirst (\( x, y ) -> { model | page = App.Preparation x, config = y })

                Preparation.CapsuleUpdate id data ->
                    let
                        _ =
                            Debug.log "" ( model.config.clientState.lastRequest, id + 1 )
                    in
                    if model.config.clientState.lastRequest == id + 1 then
                        ( { model | page = App.Preparation { m | capsuleUpdate = data } }, Cmd.none )

                    else
                        ( model, Cmd.none )

                Preparation.DeleteSlide Utils.Request slide ->
                    ( { model | page = App.Preparation { m | deleteSlide = Just slide } }, Cmd.none )

                Preparation.DeleteSlide Utils.Cancel _ ->
                    ( { model | page = App.Preparation { m | deleteSlide = Nothing } }, Cmd.none )

                Preparation.DeleteSlide Utils.Confirm slide ->
                    let
                        capsule =
                            Data.deleteSlide slide m.capsule

                        ( sync, newConfig ) =
                            ( Api.updateCapsule capsule
                                (\x -> App.PreparationMsg (Preparation.CapsuleUpdate model.config.clientState.lastRequest x))
                            , Config.incrementRequest model.config
                            )
                    in
                    ( { model | page = App.Preparation (Preparation.init capsule), config = newConfig }
                    , sync
                    )

                Preparation.Extra sMsg ->
                    updateExtra sMsg m
                        |> Tuple.mapFirst (\x -> { model | page = App.Preparation x })

        _ ->
            ( model, Cmd.none )


{-| The update function that deals with extra resources.
-}
updateExtra : Preparation.ExtraMsg -> Preparation.Model -> ( Preparation.Model, Cmd App.Msg )
updateExtra msg model =
    case msg of
        Preparation.Select changeSlide ->
            let
                mimes =
                    case changeSlide of
                        Preparation.ReplaceSlide _ ->
                            [ "image/*", "application/pdf", "video/*" ]

                        _ ->
                            [ "image/*", "application/pdf" ]

                cmd =
                    Select.file mimes (\x -> App.PreparationMsg (Preparation.Extra (Preparation.Selected changeSlide x Nothing)))
            in
            ( model, cmd )

        Preparation.Selected changeSlide file page ->
            case ( File.mime file, page ) of
                ( "application/pdf", Nothing ) ->
                    ( { model | changeSlideForm = Just { slide = changeSlide, file = file, page = "1" } }, Cmd.none )

                _ ->
                    let
                        p =
                            Maybe.withDefault 0 page

                        mkMsg x =
                            App.PreparationMsg <| Preparation.Extra <| Preparation.ChangeSlideUpdated x
                    in
                    case changeSlide of
                        Preparation.AddSlide gos ->
                            ( { model | changeSlide = RemoteData.Loading Nothing }, Api.addSlide model.capsule gos p file mkMsg )

                        Preparation.AddGos gos ->
                            ( { model | changeSlide = RemoteData.Loading Nothing }, Api.addGos model.capsule gos p file mkMsg )

                        Preparation.ReplaceSlide slide ->
                            ( { model | changeSlide = RemoteData.Loading Nothing }, Api.replaceSlide model.capsule slide p file mkMsg )

        Preparation.PageChanged page ->
            let
                changeSlideForm =
                    Maybe.map (\x -> { x | page = page }) model.changeSlideForm
            in
            ( { model | changeSlideForm = changeSlideForm }, Cmd.none )

        Preparation.PageCancel ->
            ( { model | changeSlideForm = Nothing }, Cmd.none )

        Preparation.ChangeSlideUpdated d ->
            case d of
                RemoteData.Success c ->
                    ( Preparation.init c, Cmd.none )

                _ ->
                    ( { model | changeSlide = d }, Cmd.none )


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
                        ( Api.updateCapsule
                            { capsule | structure = newStructure }
                            (\x -> App.PreparationMsg (Preparation.CapsuleUpdate config.clientState.lastRequest x))
                        , Config.incrementRequest config
                        )

                    else
                        ( Cmd.none, config )
            in
            ( ( { model | slideModel = slideModel, capsule = { capsule | structure = newStructure }, slides = newSlides }, newConfig )
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
