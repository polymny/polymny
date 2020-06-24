module Edition.Types exposing (Model, Msg(..), init)

import Api
import Status exposing (Status)


type alias Model =
    { status : Status () ()
    , details : Api.CapsuleDetails
    }


init : Api.CapsuleDetails -> Model
init details =
    Model (Status.Success ()) details


type Msg
    = AutoSuccess Api.CapsuleDetails
    | PublishVideo
    | VideoPublished
