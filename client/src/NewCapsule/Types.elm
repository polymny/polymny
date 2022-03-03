module NewCapsule.Types exposing (Model, Msg(..), init)

{-| This module contains the types for the page the users land when they upload a slideshow.
-}

import RemoteData exposing (WebData)


{-| The model of the new capsule page.
-}
type alias Model =
    { slidesUpload : WebData ()
    }


{-| An init function to easily create a model for the new capsule page.
-}
init : WebData () -> Model
init slidesUpload =
    { slidesUpload = slidesUpload }


{-| The message type for the new capsule page.
-}
type Msg
    = SlideUpload (WebData ())
