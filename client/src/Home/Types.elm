module Home.Types exposing (Msg(..))

{-| This module contains the types required for the home page.
-}

import Data.User as Data


{-| This type represents the different events that can happen on the home page
-}
type Msg
    = Toggle Data.Project
