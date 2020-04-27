module LoggedIn.Types exposing (..)

import Api
import Capsule.Types as Capsule
import NewProject.Types as NewProject


type alias Model =
    { session : Api.Session
    , page : Page
    }


type Page
    = Home
    | NewProject NewProject.Model
    | Project Api.Project
    | Capsule Capsule.Model


type Msg
    = ProjectClicked Api.Project
    | NewProjectMsg NewProject.Msg
    | CapsulesReceived Api.Project (List Api.Capsule)
    | CapsuleClicked Api.Capsule
    | CapsuleReceived Api.CapsuleDetails
    | CapsuleMsg Capsule.Msg
