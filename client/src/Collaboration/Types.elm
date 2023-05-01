module Collaboration.Types exposing (..)

{-| This module contains the collaborators page, usefull to add people to projects.
-}

import Data.Capsule as Data exposing (Capsule)
import RemoteData exposing (WebData)


{-| Model type for this page.
-}
type alias Model a =
    { capsule : a
    , newCollaborator : String
    , newCollaboratorForm : WebData ()
    }


{-| Creates a new model from a capsule.
-}
init : Capsule -> Model String
init capsule =
    { capsule = capsule.id
    , newCollaborator = ""
    , newCollaboratorForm = RemoteData.NotAsked
    }


{-| Adds a capsule to the collaboration model.
-}
withCapsule : Capsule -> Model String -> Model Capsule
withCapsule capsule model =
    { capsule = capsule
    , newCollaborator = model.newCollaborator
    , newCollaboratorForm = model.newCollaboratorForm
    }


{-| Msg type for this page.
-}
type Msg
    = NewCollaboratorChanged String
    | NewCollaboratorFormChanged (WebData ())
    | NewCollaboratorFormSubmitted
    | RemoveCollaborator Data.Collaborator
    | SwitchRole Data.Collaborator
