module Home.Types exposing
    ( Msg(..)
    , Model, init
    )

{-| This module contains the types required for the home page.

@docs Msg

-}

import Data.Capsule as Data
import Data.User as Data
import File
import FileValue
import RemoteData
import Utils


{-| This type represents the different events that can happen on the home page
-}
type Msg
    = Toggle Data.Project
    | SlideUploadClicked
    | SlideUploadReceived (Maybe String) FileValue.File File.File
    | DeleteCapsule Utils.Confirmation Data.Capsule
    | DeleteProject Utils.Confirmation Data.Project


type alias Model =
    { deleteCapsule : Maybe Data.Capsule
    , deleteProject : Maybe Data.Project
    }


init : Model
init =
    { deleteCapsule = Nothing
    , deleteProject = Nothing
    }
