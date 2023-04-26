module Publication.Types exposing (..)

import Capsule exposing (Capsule)


type alias Model =
    { capsule : Capsule
    , showPrivacyPopup : Bool
    }


init : Capsule -> Model
init capsule =
    { capsule = capsule, showPrivacyPopup = False }


type Msg
    = Publish
    | Published
    | Unpublish
    | Cancel
    | PrivacyChanged Capsule.Privacy
    | PromptSubtitlesChanged Bool
    | TogglePrivacyPopup
