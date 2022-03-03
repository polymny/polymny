module NewCapsule.Types exposing (Model, Msg(..), init)

{-| This module contains the types for the page the users land when they upload a slideshow.
-}

import Data.Capsule as Data
import Http
import RemoteData exposing (WebData)


{-| The model of the new capsule page.
-}
type alias Model =
    { slideUpload : WebData Data.Capsule
    }


{-| An init function to easily create a model for the new capsule page.
-}
init : WebData Data.Capsule -> Model
init slideUpload =
    { slideUpload = slideUpload }


{-| The message type for the new capsule page.
-}
type Msg
    = SlideUpload (WebData Data.Capsule)
