module Publication.Types exposing (..)

import Capsule exposing (Capsule)


type alias Model =
    { capsule : Capsule }


init : Capsule -> Model
init capsule =
    { capsule = capsule }


type Msg
    = Publish
    | Published
    | Unpublish
    | Cancel
    | PrivacyChanged Capsule.Privacy
    | PromptSubtitlesChanged Bool
