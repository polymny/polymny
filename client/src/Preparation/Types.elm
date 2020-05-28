module Preparation.Types exposing (Model(..), Msg(..))

import Api
import Capsule.Types as Capsule
import NewCapsule.Types as NewCapsule
import NewProject.Types as NewProject


type Model
    = Home
    | NewProject NewProject.Model
    | Project Api.Project (Maybe NewCapsule.Model)
    | Capsule Capsule.Model


type Msg
    = PreparationClicked
    | ProjectClicked Api.Project
    | NewProjectMsg NewProject.Msg
    | NewCapsuleMsg NewCapsule.Msg
    | CapsulesReceived Api.Project (List Api.Capsule)
    | NewCapsuleClicked Api.Project
    | CapsuleClicked Api.Capsule
    | CapsuleReceived Api.CapsuleDetails
    | CapsuleMsg Capsule.Msg
