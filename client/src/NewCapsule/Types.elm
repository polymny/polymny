module NewCapsule.Types exposing (Model, NextPage(..), Msg(..), Slide, init, prepare, structureFromUi, toggle)

{-| This module contains the types for the page the users land when they upload a slideshow.

@docs Model, NextPage, Msg, Slide, init, prepare, structureFromUi, toggle

-}

import Data.Capsule as Data
import Lang exposing (Lang)
import RemoteData exposing (WebData)
import Strings
import Triplet
import Utils


{-| The model of the new capsule page.
-}
type alias Model =
    { slideUpload : WebData ( Data.Capsule, List Slide )
    , capsuleUpdate : ( NextPage, WebData () )
    , projectName : String
    , capsuleName : String
    , showProject : Bool
    }


{-| Whether the user clicked on preparation or acquisition.
-}
type NextPage
    = Preparation
    | Acquisition


{-| Local type for slide.

The first int is the index of the slide, the second is the index of the grain.

-}
type alias Slide =
    ( Int, Int, Data.Slide )


{-| An init function to easily create a model for the new capsule page.
-}
init : Lang -> Maybe String -> String -> WebData ( Data.Capsule, List Slide ) -> Model
init lang projectName capsuleName slideUpload =
    { slideUpload = slideUpload
    , projectName = projectName |> Maybe.withDefault (Strings.stepsPreparationNewProject lang)
    , capsuleName = capsuleName
    , showProject = projectName /= Nothing
    , capsuleUpdate = ( Preparation, RemoteData.NotAsked )
    }


{-| Prepares the capsule for easily accessing the first step of preparation.
-}
prepare : Data.Capsule -> List Slide
prepare capsule =
    List.indexedMap (\i s -> ( i, i, s )) (List.concat (List.map .slides capsule.structure))


{-| Toggles a delimiter easily.

Between each slides, there is a delimiter. The user can click on the delimiter to change its style: it can either be a
solid delimiter which indicates that the two slides belong to two different grains, which means that the slide after the
delimiter belongs to another grain, or it can be a dashed delimiter, which means that the two slides belong to the same
grain.

This function changes the state of a delimiter, and updates the indices of grains.

The boolean attribute must be true if the two slides belong to the same grain and need to be separated.

The integer attribute is the index of the delimiter (an index of 0 means a delimiter between slides 0 and 1).

-}
toggle : Bool -> Int -> List Slide -> List Slide
toggle split delimiter input =
    toggleAux [] split delimiter input |> List.reverse


{-| Auxilary function to help toggle function.

Delimiter being -1 means that the index has been reached and that the gos indices must be updated.

-}
toggleAux : List Slide -> Bool -> Int -> List Slide -> List Slide
toggleAux acc split delimiter input =
    case input of
        ( i1, g1, s1 ) :: ( i2, g2, s2 ) :: t ->
            if delimiter == -1 then
                -- If split is true, it means that the two slides belong to the same grain, and must be separated. We do
                -- that by adding 1 to every gos index after have reached the delimiter index.
                -- Otherwise, it means that the two slides belong to different grain, and must be regrouped
                -- together. It means that we need to remove 1 from all gos indices after having reached the delimiter
                -- index.
                toggleAux (( i1, g1 + Utils.tern split 1 -1, s1 ) :: acc) split delimiter (( i2, g2, s2 ) :: t)

            else
                -- We haven't find the delimiter yet, so we keep searching.
                toggleAux (( i1, g1, s1 ) :: acc) split (delimiter - 1) (( i2, g2, s2 ) :: t)

        ( i1, g1, s1 ) :: [] ->
            if delimiter == -1 then
                ( i1, g1 + Utils.tern split 1 -1, s1 ) :: acc

            else
                ( i1, g1, s1 ) :: acc

        [] ->
            acc


{-| Creates the list of gos from the list of slides.

The caspule contains the structure, which is a List of Data.Gos. In the model of this page, we keep the capsule (because
we need it update things), but also the List (Int, Int, Data.Slide) which contains the index of the gos and slide,
because it makes it really easier for both the view and the update.

This function allows to retrieve the structure of the capsule for the List (Int, Int, Data.Slide).

-}
structureFromUi : List Slide -> List Data.Gos
structureFromUi slides =
    structureFromUiAux [] slides
        |> List.map Tuple.second
        |> List.map List.reverse
        |> List.reverse
        |> List.map (List.map Triplet.third)
        |> List.map Data.gosFromSlides


{-| Auxilary function used as a helper for structureFromUiAux.

In this function, the `List (Int, List Slide)` is a simplified version of `Data.Gos`, because we only deal with slides.
We also keep the Int which is the index of the gos, that we keep so we can easily check if the next slides belong to the
same gos of if we have to create another gos.

-}
structureFromUiAux : List ( Int, List Slide ) -> List Slide -> List ( Int, List Slide )
structureFromUiAux acc slides =
    case ( slides, acc ) of
        ( [], _ ) ->
            acc

        ( h :: t, [] ) ->
            structureFromUiAux [ ( Triplet.second h, [ h ] ) ] t

        ( h :: t, ( currentGosId, currentGos ) :: t2 ) ->
            -- If the next slide from the input belongs to the same gos as the previous one
            if Triplet.second h == currentGosId then
                -- We add it into the list and keep going
                structureFromUiAux (( currentGosId, h :: currentGos ) :: t2) t

            else
                -- Otherwise, we create its own gos
                structureFromUiAux (( Triplet.second h, [ h ] ) :: ( currentGosId, currentGos ) :: t2) t


{-| The message type for the new capsule page.
-}
type Msg
    = SlideUpload (WebData Data.Capsule)
    | CapsuleUpdate ( NextPage, WebData () )
    | NameChanged String
    | ProjectChanged String
    | DelimiterClicked Bool Int
    | Submit NextPage
    | Cancel
