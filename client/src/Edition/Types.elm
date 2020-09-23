module Edition.Types exposing (Model, Msg(..), defaultGosProductionChoices, init, selectEditionOptions)

import Api
import Status exposing (Status)
import Webcam


type alias Model =
    { status : Status () ()
    , details : Api.CapsuleDetails
    , withVideo : Bool
    , webcamSize : Webcam.WebcamSize
    , webcamPosition : Webcam.WebcamPosition
    , currentGos : Int
    }


init : Api.CapsuleDetails -> Model
init details =
    Model Status.NotSent details True Webcam.Medium Webcam.BottomLeft 0


defaultGosProductionChoices : Api.CapsuleEditionOptions
defaultGosProductionChoices =
    Api.CapsuleEditionOptions True (Just Webcam.Medium) (Just Webcam.BottomLeft)


selectEditionOptions : Api.Session -> Api.Capsule -> Model -> Model
selectEditionOptions session capsule model =
    let
        sessionWecamSize =
            Maybe.withDefault Webcam.Medium session.webcamSize

        sessionWebcamPosition =
            Maybe.withDefault Webcam.BottomLeft session.webcamPosition
    in
    case capsule.capsuleEditionOptions of
        Just x ->
            { model
                | withVideo = x.withVideo
                , webcamSize = Maybe.withDefault sessionWecamSize x.webcamSize
                , webcamPosition = Maybe.withDefault sessionWebcamPosition x.webcamPosition
            }

        Nothing ->
            { model
                | withVideo = Maybe.withDefault True session.withVideo
                , webcamSize = sessionWecamSize
                , webcamPosition = sessionWebcamPosition
            }


type Msg
    = AutoSuccess Api.CapsuleDetails
    | AutoFailed
    | PublishVideo
    | VideoPublished
    | WithVideoChanged Bool
    | WebcamSizeChanged Webcam.WebcamSize
    | WebcamPositionChanged Webcam.WebcamPosition
    | GosWithVideoChanged Int Bool
    | GosWebcamSizeChanged Int Webcam.WebcamSize
    | GosWebcamPositionChanged Int Webcam.WebcamPosition
    | OptionsSubmitted
    | CopyUrl String
