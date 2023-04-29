module Collaboration.Types exposing (..)

{-| This module contains the collaborators page, usefull to add people to projects.
-}

import Data.Capsule exposing (Capsule)


{-| Model type for this page.
-}
type alias Model a =
    { capsule : a
    }


{-| Creates a new model from a capsule.
-}
init : Capsule -> Model String
init capsule =
    { capsule = capsule.id }


{-| Adds a capsule to the collaboration model.
-}
withCapsule : Capsule -> Model String -> Model Capsule
withCapsule capsule model =
    { capsule = capsule }


{-| Msg type for this page.
-}
type Msg
    = Noop
