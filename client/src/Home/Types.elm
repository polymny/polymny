module Home.Types exposing (Msg(..))

{-| This module contains the types required for the home page.

@docs Msg

-}

import Data.User as Data
import File
import FileValue


{-| This type represents the different events that can happen on the home page
-}
type Msg
    = Toggle Data.Project
    | SlideUploadClicked
    | SlideUploadReceived (Maybe String) FileValue.File File.File
