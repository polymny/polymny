module Edition.Types exposing (Model, Msg(..), WebcamPosition(..), WebcamSize(..), init)

import Api
import Status exposing (Status)


type alias Model =
    { status : Status () ()
    , details : Api.CapsuleDetails
    , withVideo : Bool
    , webcamSize : WebcamSize
    , webcamPosition : WebcamPosition
    }


init : Api.CapsuleDetails -> Model
init details =
    Model (Status.Success ()) details True Medium BottomLeft


type Msg
    = AutoSuccess Api.CapsuleDetails
    | AutoFailed
    | PublishVideo
    | VideoPublished
    | WithVideoChanged Bool
    | WebcamSizeChanged WebcamSize
    | WebcamPositionChanged WebcamPosition
    | OptionsSubmitted


type WebcamSize
    = Small
    | Medium
    | Large


type WebcamPosition
    = TopLeft
    | TopRight
    | BottomLeft
    | BottomRight
