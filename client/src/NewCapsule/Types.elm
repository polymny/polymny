module NewCapsule.Types exposing (Model, Msg(..), Slide, init, prepare, toggle)

{-| This module contains the types for the page the users land when they upload a slideshow.
-}

import Data.Capsule as Data
import Lang exposing (Lang)
import RemoteData exposing (WebData)
import Strings
import Utils


{-| The model of the new capsule page.
-}
type alias Model =
    { slideUpload : WebData ( Data.Capsule, List Slide )
    , projectName : String
    , capsuleName : String
    , showProject : Bool
    }


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
    , showProject = projectName == Nothing
    }


{-| Prepares the capsule for easily accessing the first step of preparation.
-}
prepare : Data.Capsule -> List Slide
prepare capsule =
    List.indexedMap (\i s -> ( i, i, s )) (List.concat (List.map .slides capsule.structure))


{-| Toggles a delimiter easily.
-}
toggle : Bool -> Int -> List Slide -> List Slide
toggle split delimiter input =
    toggleAux [] split delimiter input |> List.reverse


{-| Auxilary function to help toggle function.
-}
toggleAux : List Slide -> Bool -> Int -> List Slide -> List Slide
toggleAux acc split delimiter input =
    case input of
        ( i1, g1, s1 ) :: ( i2, g2, s2 ) :: t ->
            if delimiter == -1 then
                toggleAux (( i1, g1 + Utils.tern split 1 -1, s1 ) :: acc) split delimiter (( i2, g2, s2 ) :: t)

            else
                toggleAux (( i1, g1, s1 ) :: acc) split (delimiter - 1) (( i2, g2, s2 ) :: t)

        ( i1, g1, s1 ) :: t ->
            if delimiter == -1 then
                ( i1, g1 + Utils.tern split 1 -1, s1 ) :: acc

            else
                ( i1, g1, s1 ) :: acc

        [] ->
            acc


{-| The message type for the new capsule page.
-}
type Msg
    = SlideUpload (WebData Data.Capsule)
    | NameChanged String
    | ProjectChanged String
    | DelimiterClicked Bool Int
