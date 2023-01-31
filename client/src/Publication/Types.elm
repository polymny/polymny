module Publication.Types exposing (..)

{-| This module holds the types for the publication page.
-}

import Data.Capsule exposing (Capsule)


type alias Model =
    { capsule : Capsule
    }


init : Capsule -> Model
init capsule =
    { capsule = capsule }


type Msg
    = Noop
