module Home.Types exposing (Msg(..))

{-| This module contains the types required for the home page.

@docs Model, init, Msg

-}

import Data.User as Data
import FileValue exposing (File)


{-| This type represents the different events that can happen on the home page
-}
type Msg
    = Toggle Data.Project
    | SlideUploadClicked
    | SlideUploadReceived String File
