module Preparation.Types exposing
    ( Model(..)
    , Msg(..)
    )

import Api
import Capsule.Types as Capsule


type Model
    = Home
    | Capsule Capsule.Model


type Msg
    = PreparationClicked
    | CapsuleReceived Api.CapsuleDetails
    | CapsuleMsg Capsule.Msg
