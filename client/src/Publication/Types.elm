module Publication.Types exposing (..)

{-| This module holds the types for the publication page.
-}

import Data.Capsule exposing (Capsule)
import Data.Types as Data


type alias Model a =
    { capsule : a
    , showPrivacyPopup : Bool
    }


withCapsule : Capsule -> Model String -> Model Capsule
withCapsule capsule model =
    { capsule = capsule
    , showPrivacyPopup = model.showPrivacyPopup
    }


init : Capsule -> Model String
init capsule =
    { capsule = capsule.id
    , showPrivacyPopup = False
    }


type Msg
    = TogglePrivacyPopup
    | SetPrivacy Data.Privacy
    | SetPromptSubtitles Bool
    | PublishVideo
    | UnpublishVideo
