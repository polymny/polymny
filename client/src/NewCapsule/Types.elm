module NewCapsule.Types exposing (Model, Msg(..), init, prepare)

{-| This module contains the types for the page the users land when they upload a slideshow.
-}

import Data.Capsule as Data
import Lang exposing (Lang)
import RemoteData exposing (WebData)
import Strings


{-| The model of the new capsule page.
-}
type alias Model =
    { slideUpload : WebData ( Data.Capsule, List ( Int, Data.Slide ) )
    , projectName : String
    , capsuleName : String
    , showProject : Bool
    }


{-| An init function to easily create a model for the new capsule page.
-}
init : Lang -> Maybe String -> String -> WebData ( Data.Capsule, List ( Int, Data.Slide ) ) -> Model
init lang projectName capsuleName slideUpload =
    { slideUpload = slideUpload
    , projectName = projectName |> Maybe.withDefault (Strings.stepsPreparationNewProject lang)
    , capsuleName = capsuleName
    , showProject = projectName == Nothing
    }


{-| Prepares the capsule for easily accessing the first step of preparation.
-}
prepare : Data.Capsule -> List ( Int, Data.Slide )
prepare capsule =
    List.indexedMap Tuple.pair (List.concat (List.map .slides capsule.structure))


{-| The message type for the new capsule page.
-}
type Msg
    = SlideUpload (WebData Data.Capsule)
    | NameChanged String
    | ProjectChanged String
