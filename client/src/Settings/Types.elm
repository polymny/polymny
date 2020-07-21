module Settings.Types exposing (Model, Msg(..), init)

import Api
import Status exposing (Status)
import Webcam


type alias Model =
    { status : Status () ()
    }


init : Model
init =
    Model Status.NotSent


type Msg
    = WithVideoChanged Bool
    | WebcamSizeChanged Webcam.WebcamSize
    | WebcamPositionChanged Webcam.WebcamPosition
    | OptionsSubmitted
    | OptionsSuccess Api.Session
    | OptionsFailed
