module Production.Types exposing (..)

{-| This module contains the production page of the app.
-}

import Data.Capsule as Data exposing (Capsule)


{-| Model type of the production page.
-}
type alias Model =
    { capsule : Capsule
    , gos : Int
    }


{-| Initializes a model from the capsule and gos is.
-}
init : Int -> Capsule -> Maybe ( Model, Cmd Msg )
init gos capsule =
    if gos < List.length capsule.structure && gos >= 0 then
        Just <|
            ( { capsule = capsule
              , gos = gos
              }
            , Cmd.none
            )

    else
        Nothing


{-| Message type of the app.
-}
type Msg
    = Produce
