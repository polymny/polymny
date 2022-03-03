module NewCapsule.Types exposing (Model, Msg(..), Slide, init, prepare)

{-| This module contains the types for the page the users land when they upload a slideshow.
-}

import Data.Capsule as Data
import Lang exposing (Lang)
import RemoteData exposing (WebData)
import Strings


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


{-| The message type for the new capsule page.
-}
type Msg
    = SlideUpload (WebData Data.Capsule)
    | NameChanged String
    | ProjectChanged String
