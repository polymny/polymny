module Edition.Types exposing (Model, Msg(..), init)

import Api
import Status exposing (Status)
import Webcam


type alias Model =
    { status : Status () ()
    , details : Api.CapsuleDetails
    , withVideo : Bool
    , webcamSize : Webcam.WebcamSize
    , webcamPosition : Webcam.WebcamPosition
    }


init : Api.CapsuleDetails -> Model
init details =
    Model (Status.Success ()) details True Webcam.Medium Webcam.BottomLeft


type Msg
    = AutoSuccess Api.CapsuleDetails
    | AutoFailed
    | PublishVideo
    | VideoPublished
    | WithVideoChanged Bool
    | WebcamSizeChanged Webcam.WebcamSize
    | WebcamPositionChanged Webcam.WebcamPosition
    | OptionsSubmitted
