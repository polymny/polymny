module LoggedIn.Types exposing (Model, Msg(..), Page(..))

import Api
import Capsule.Types as Capsule
import NewCapsule.Types as NewCapsule
import NewProject.Types as NewProject


type alias Model =
    { session : Api.Session
    , page : Page
    }


type Page
    = Home
    | NewProject NewProject.Model
    | NewCapsule Int NewCapsule.Model
    | Project Api.Project
    | Capsule Capsule.Model


type Msg
    = ProjectClicked Api.Project
    | NewProjectMsg NewProject.Msg
    | NewCapsuleMsg NewCapsule.Msg
    | CapsulesReceived Api.Project (List Api.Capsule)
    | CapsuleClicked Api.Capsule
    | CapsuleReceived Api.CapsuleDetails
    | CapsuleMsg Capsule.Msg
