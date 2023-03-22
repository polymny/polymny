module Home.Types exposing
    ( Msg(..)
    , Model, PopupType(..), init
    )

{-| This module contains the types required for the home page.

@docs Msg

-}

import Data.Capsule as Data
import Data.Types as Data
import Data.User as Data
import File
import FileValue
import Utils


{-| This type represents the different events that can happen on the home page
-}
type Msg
    = Toggle Data.Project
    | SlideUploadClicked (Maybe String)
    | SlideUploadReceived (Maybe String) FileValue.File File.File
    | DeleteCapsule Utils.Confirmation Data.Capsule
    | RenameCapsule Utils.Confirmation Data.Capsule
    | CapsuleNameChanged Data.Capsule String
    | DeleteProject Utils.Confirmation Data.Project
    | RenameProject Utils.Confirmation Data.Project
    | ProjectNameChanged Data.Project String
    | SortBy Data.SortKey
    | EscapePressed
    | EnterPressed
    | ExportCapsule Data.Capsule
    | CapsuleUpdated Data.Capsule
    | DuplicateCapsule Data.Capsule


type PopupType
    = DeleteCapsulePopup Data.Capsule
    | RenameCapsulePopup Data.Capsule
    | DeleteProjectPopup Data.Project
    | RenameProjectPopup Data.Project


type alias Model =
    { popupType : Maybe PopupType
    }


init : Model
init =
    { popupType = Nothing
    }
