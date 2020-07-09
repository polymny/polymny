module Edition.Types exposing (Model, Msg(..), init)

import Api
import Status exposing (Status)


type alias Model =
    { status : Status () ()
    , details : Api.CapsuleDetails
    , withVideo : Bool
    }


init : Api.CapsuleDetails -> Model
init details =
    Model (Status.Success ()) details True


type Msg
    = AutoSuccess Api.CapsuleDetails
    | AutoFailed
    | PublishVideo
    | VideoPublished
    | WithVideoChanged Bool
    | OptionsSubmitted
