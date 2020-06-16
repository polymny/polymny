module Edition.Types exposing (Model, Msg(..))

import Api
import Status exposing (Status)


type alias Model =
    { status : Status () ()
    , details : Api.CapsuleDetails
    }


type Msg
    = AutoSuccess Api.CapsuleDetails
