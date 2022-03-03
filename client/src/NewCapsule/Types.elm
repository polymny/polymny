module NewCapsule.Types exposing (Model, Msg(..), SlideUploadError(..), init)

{-| This module contains the types for the page the users land when they upload a slideshow.
-}

import Http
import RemoteData exposing (RemoteData)


{-| The model of the new capsule page.
-}
type alias Model =
    { slideUpload : RemoteData SlideUploadError ()
    }


{-| An init function to easily create a model for the new capsule page.
-}
init : RemoteData SlideUploadError () -> Model
init slideUpload =
    { slideUpload = slideUpload }


{-| The message type for the new capsule page.
-}
type Msg
    = SlideUpload (RemoteData SlideUploadError ())


{-| The error that can occurs when uploading slides.
-}
type SlideUploadError
    = ReadFileError
    | HttpError Http.Error
    | DecodeResponseError
