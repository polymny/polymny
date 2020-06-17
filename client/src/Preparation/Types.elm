module Preparation.Types exposing
    ( Model(..)
    , Msg(..)
    )

import Capsule.Types as Capsule


type Model
    = Capsule Capsule.Model


type Msg
    = CapsuleMsg Capsule.Msg
