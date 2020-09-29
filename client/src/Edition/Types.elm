module Edition.Types exposing (Model, Msg(..), defaultGosProductionChoices, init)

import Api
import Status exposing (Status)
import Webcam


type alias Model =
    { status : Status () ()
    , details : Api.CapsuleDetails
    , currentGos : Int
    , editCapsuleOptions : Bool
    }


init : Api.CapsuleDetails -> Model
init details =
    Model Status.NotSent details 0 False


defaultGosProductionChoices : Api.CapsuleEditionOptions
defaultGosProductionChoices =
    Api.CapsuleEditionOptions True (Just Webcam.Medium) (Just Webcam.BottomLeft)


type Msg
    = AutoSuccess Api.CapsuleDetails
    | AutoFailed
    | PublishVideo
    | VideoPublished
    | WithVideoChanged Bool
    | WebcamSizeChanged Webcam.WebcamSize
    | WebcamPositionChanged Webcam.WebcamPosition
    | GosUseDefaultChanged Int Bool
    | GosWithVideoChanged Int Bool
    | GosWebcamSizeChanged Int Webcam.WebcamSize
    | GosWebcamPositionChanged Int Webcam.WebcamPosition
    | OptionsSubmitted
    | CopyUrl String
    | ToggleEditDefault
