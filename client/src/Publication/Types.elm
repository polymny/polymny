module Publication.Types exposing (..)

{-| This module holds the types for the publication page.
-}

import Data.Capsule exposing (Capsule)
import Data.Types as Data


type alias Model =
    { capsule : Capsule
    , showPrivacyPopup : Bool
    }


init : Capsule -> Model
init capsule =
    { capsule = capsule
    , showPrivacyPopup = False
    }


type Msg
    = TogglePrivacyPopup
    | SetPrivacy Data.Privacy
    | SetPromptSubtitles Bool
    | PublishVideo
