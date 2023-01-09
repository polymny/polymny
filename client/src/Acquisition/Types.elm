module Acquisition.Types exposing (Model, init, Msg(..))

{-| This module contains the types for the acqusition page, where a user can record themself.

@docs Model, init, Msg

-}

import Data.Capsule as Data exposing (Capsule)


{-| The type for the model of the acquisition page.
-}
type alias Model =
    { capsule : Capsule
    , gos : Int
    }


{-| Initializes a model from the capsule and the grain we want to record.

It returns Nothing if the grain is not in the capsule.

-}
init : Int -> Capsule -> Maybe Model
init gos capsule =
    if gos < List.length capsule.structure && gos >= 0 then
        Just { capsule = capsule, gos = gos }

    else
        Nothing


{-| The message type of the module.
-}
type Msg
    = None
