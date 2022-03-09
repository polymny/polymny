module Preparation.Types exposing
    ( Model, init, MaybeSlide(..), toSlide, enumerate
    , DnDMsg(..), Msg(..), gosSystem, regroupSlides, setupSlides, slideSystem
    )

{-| This module contains the type for the preparation page, where user can manage a capsule.

In all the following documentation, DnD refers to Drag'n'Drop. It is necessary to have a user-friendly interface, but is
quite a pain to deal with.

@docs Model, init, MaybeSlide, toSlide, enumerate

-}

import Data.Capsule as Data exposing (Capsule)
import DnDList
import DnDList.Groups


{-| The type for the model of the preparation page.
-}
type alias Model =
    { capsule : Capsule
    , slides : List (List MaybeSlide)
    , slideModel : DnDList.Groups.Model
    , gosModel : DnDList.Model
    }


{-| A helper function to initialiaze a model.
-}
init : Capsule -> Model
init capsule =
    { capsule = capsule
    , slides = capsule.structure |> List.map .slides |> setupSlides
    , slideModel = slideSystem.model
    , gosModel = gosSystem.model
    }


{-| The message type of this page.
-}
type Msg
    = DnD DnDMsg


{-| The different DnD messages that can occur.
-}
type DnDMsg
    = SlideMoved DnDList.Groups.Msg
    | GosMoved DnDList.Msg


{-| Something that can be either a gos id or a slide.

We need this type to deal with DnD.

In the case of a `GosId`:

  - the `gosId` attribute is the real gos id, starting at 0 and counting the capsules.
  - the `totalGosId` is the id of the gos in the view. Each gos is separated by an empty gos that theoritically doesn't
    exist, but is present in our model because a user can drop a slide on it, and actually create the gos.
  - the `totalSlideId` is present because virtual gos contain a slide.

If a gos (List MaybeSlide) contains only a GosId, then, it is a virtual gos, and its totalSlideId is the id corresponding
to the virtual slide, otherwise, its a real gos, which contains slides, and its totalSlideId will be the totalSlideId of
the first slide of the gos.

In the case of a `Slide`:

  - the `gosId` is the real gos id to which the slide belongs.
  - the `totalGosId` is the id of the gos the the view.
  - the `slideId` is the real id of the slide, starting from 0 from the first slide of the first gos, and counting every
    slide.
  - the `totalSlideId` takes also into account the fact that an virtual gos contains a virtual slide.

-}
type MaybeSlide
    = GosId { gosId : Int, totalGosId : Int, totalSlideId : Int }
    | Slide { gosId : Int, totalGosId : Int, slideId : Int, totalSlideId : Int, slide : Data.Slide }


{-| A helper function to easily create a gos id.
-}
makeGosId : Int -> Int -> Int -> MaybeSlide
makeGosId gosId totalGosId totalSlideId =
    GosId { gosId = gosId, totalGosId = totalGosId, totalSlideId = totalSlideId }


{-| A helper function to easily create a slide.
-}
makeSlide : Int -> Int -> Int -> Int -> Data.Slide -> MaybeSlide
makeSlide gosId totalGosId slideId totalSlideId slide =
    Slide { gosId = gosId, totalGosId = totalGosId, slideId = slideId, totalSlideId = totalSlideId, slide = slide }


{-| A helper function to prepare the List (List MaybeSlide) from the capsule.
-}
setupSlides : List (List Data.Slide) -> List (List MaybeSlide)
setupSlides structure =
    let
        slideMapper : Int -> ( Int, Data.Slide ) -> MaybeSlide
        slideMapper gosId ( slideId, slide ) =
            makeSlide gosId -1 slideId -1 slide

        gosMapper : ( Int, List ( Int, Data.Slide ) ) -> List MaybeSlide
        gosMapper ( gosId, slides ) =
            makeGosId gosId -1 -1 :: List.map (slideMapper gosId) slides
    in
    structure
        |> enumerate
        |> List.map gosMapper
        |> List.intersperse [ GosId { gosId = -1, totalGosId = -1, totalSlideId = -1 } ]
        |> (\x -> [ makeGosId -1 -1 -1 ] :: x ++ [ [ makeGosId -1 -1 -1 ] ])
        |> reindex


{-| An util function to doubly enumerate elements.
-}
enumerate : List (List a) -> List ( Int, List ( Int, a ) )
enumerate input =
    enumerateAux 0 0 [] input
        |> List.map (Tuple.mapSecond List.reverse)
        |> List.reverse


{-| An auxilary function to help doubly enumerate elements.
-}
enumerateAux : Int -> Int -> List ( Int, List ( Int, a ) ) -> List (List a) -> List ( Int, List ( Int, a ) )
enumerateAux currentOuter currentInner acc input =
    case ( input, acc ) of
        ( [], _ ) ->
            acc

        ( [] :: [], _ ) ->
            acc

        ( [] :: t, _ ) ->
            enumerateAux (currentOuter + 1) currentInner (( currentOuter + 1, [] ) :: acc) t

        ( (h :: t) :: t2, [] ) ->
            enumerateAux currentOuter (currentInner + 1) [ ( currentOuter, [ ( currentInner, h ) ] ) ] (t :: t2)

        ( (h :: t) :: t2, ( hiA, [] ) :: t1 ) ->
            enumerateAux currentOuter (currentInner + 1) (( hiA, [ ( currentInner, h ) ] ) :: t1) (t :: t2)

        ( (h :: t) :: t2, ( hiA, hlAh :: hlAt ) :: t1 ) ->
            enumerateAux currentOuter (currentInner + 1) (( hiA, ( currentInner, h ) :: hlAh :: hlAt ) :: t1) (t :: t2)


{-| A helper function that recomputes the totalGosId and totalSlideId of the List (List MaybeSlide).
-}
reindex : List (List MaybeSlide) -> List (List MaybeSlide)
reindex input =
    reindexAux 0 0 [] input
        |> List.map List.reverse
        |> List.reverse


{-| An auxilary function to help us write the reindex functions.
-}
reindexAux : Int -> Int -> List (List MaybeSlide) -> List (List MaybeSlide) -> List (List MaybeSlide)
reindexAux currentOuter currentInner acc input =
    case input of
        [] ->
            acc

        [] :: [] ->
            acc

        [] :: t ->
            reindexAux (currentOuter + 1) currentInner acc t

        [ GosId { gosId } ] :: t ->
            -- This is the case of a virtual gos.
            -- We need to increase currentInner because the virtual gos contains a virtual slide.
            reindexAux (currentOuter + 1) (currentInner + 1) ([ makeGosId gosId currentOuter currentInner ] :: acc) t

        ((GosId { gosId }) :: t) :: t2 ->
            reindexAux currentOuter currentInner ([ makeGosId gosId currentOuter currentInner ] :: acc) (t :: t2)

        ((Slide { gosId, slideId, slide }) :: t) :: t2 ->
            let
                newAcc =
                    case acc of
                        [] ->
                            [ [ makeSlide gosId currentOuter slideId currentInner slide ] ]

                        hA :: tA ->
                            (makeSlide gosId currentOuter slideId currentInner slide :: hA) :: tA
            in
            reindexAux currentOuter (currentInner + 1) newAcc (t :: t2)


{-| Regroups maybe slides togheter correctly.
-}
regroupSlides : List MaybeSlide -> List (List MaybeSlide)
regroupSlides input =
    regroupSlidesAux [] input |> List.map List.reverse |> List.reverse


{-| Auxilary function to help write regroup slides function.
-}
regroupSlidesAux : List (List MaybeSlide) -> List MaybeSlide -> List (List MaybeSlide)
regroupSlidesAux acc input =
    case ( input, acc ) of
        ( [], _ ) ->
            acc

        ( (GosId a) :: t, _ ) ->
            regroupSlidesAux ([ GosId a ] :: acc) t

        ( (Slide a) :: t, [] ) ->
            -- This should be unreachable
            regroupSlidesAux [ [ Slide a ] ] t

        ( (Slide a) :: t, hA :: tA ) ->
            regroupSlidesAux ((Slide a :: hA) :: tA) t


{-| Converts a MaybeSlide to a Maybe Data.Slide.
-}
toSlide : MaybeSlide -> Maybe { gosId : Int, totalGosId : Int, slideId : Int, totalSlideId : Int, slide : Data.Slide }
toSlide s =
    case s of
        Slide slide ->
            Just slide

        _ ->
            Nothing


{-| Configuration for DnD of slides.
-}
slideConfig : DnDList.Groups.Config MaybeSlide
slideConfig =
    { beforeUpdate = \_ _ a -> a
    , listen = DnDList.Groups.OnDrag
    , operation = DnDList.Groups.Rotate
    , groups =
        { listen = DnDList.Groups.OnDrag
        , operation = DnDList.Groups.InsertAfter
        , comparator = slideComparator
        , setter = slideSetter
        }
    }


{-| Compares two slides to know if they're in the same gos.
-}
slideComparator : MaybeSlide -> MaybeSlide -> Bool
slideComparator slide1 slide2 =
    case ( slide1, slide2 ) of
        ( Slide s1, Slide s2 ) ->
            s1.gosId == s2.gosId

        ( GosId gos1, GosId gos2 ) ->
            gos1.gosId == gos2.gosId

        _ ->
            False


{-| Updates a maybe slide to add into another maybe slide.
-}
slideSetter : MaybeSlide -> MaybeSlide -> MaybeSlide
slideSetter slide1 slide2 =
    case ( slide1, slide2 ) of
        ( Slide s1, Slide s2 ) ->
            Slide { s2 | gosId = s1.gosId, totalGosId = s1.totalGosId }

        ( GosId gos, Slide s2 ) ->
            Slide { s2 | gosId = gos.gosId, totalGosId = gos.totalGosId }

        ( Slide s1, GosId gos ) ->
            Slide { s1 | gosId = gos.gosId, totalGosId = gos.totalGosId }

        ( GosId i1, GosId _ ) ->
            GosId i1


{-| The slide system for DnD.
-}
slideSystem : DnDList.Groups.System MaybeSlide DnDMsg
slideSystem =
    DnDList.Groups.create slideConfig SlideMoved


{-| Configuration for DnD of gos.
-}
gosConfig : DnDList.Config (List MaybeSlide)
gosConfig =
    { beforeUpdate = \_ _ a -> a
    , movement = DnDList.Free
    , listen = DnDList.OnDrag
    , operation = DnDList.Rotate
    }


{-| The gos system for DnD.
-}
gosSystem : DnDList.System (List MaybeSlide) DnDMsg
gosSystem =
    DnDList.create gosConfig GosMoved
