module Edition.Types exposing (Model, Msg(..), WebcamSize(..), init)

import Api
import Status exposing (Status)


type alias Model =
    { status : Status () ()
    , details : Api.CapsuleDetails
    , withVideo : Bool
    , webcamSize : WebcamSize
    }


init : Api.CapsuleDetails -> Model
init details =
    Model (Status.Success ()) details True Medium


type Msg
    = AutoSuccess Api.CapsuleDetails
    | AutoFailed
    | PublishVideo
    | VideoPublished
    | WithVideoChanged Bool
    | WebcamSizeChanged WebcamSize
    | OptionsSubmitted


type WebcamSize
    = Small
    | Medium
    | Large
