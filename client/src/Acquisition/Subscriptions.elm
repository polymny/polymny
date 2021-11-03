module Acquisition.Subscriptions exposing (subscriptions)

import Acquisition.Ports as Ports
import Acquisition.Types as Acquisition
import Acquisition.Views as Acquisition
import Capsule
import Core.Types as Core
import Json.Decode as Decode
import Keyboard


subscriptions : Acquisition.Model -> Sub Core.Msg
subscriptions model =
    Sub.batch
        [ Ports.webcamBound (\_ -> Core.AcquisitionMsg Acquisition.WebcamBound)
        , Ports.recordArrived
            (\x ->
                case Decode.decodeValue Acquisition.decodeRecord x of
                    Ok o ->
                        Core.AcquisitionMsg (Acquisition.RecordArrived o)

                    _ ->
                        Core.Noop
            )
        , Keyboard.ups (Acquisition.shortcuts model)
        , Ports.nextSlideReceived (\_ -> Core.AcquisitionMsg Acquisition.NextSlideReceived)
        , Ports.playRecordFinished (\_ -> Core.AcquisitionMsg Acquisition.PlayRecordFinished)
        , Ports.capsuleUpdated
            (\x ->
                case Decode.decodeValue (Decode.maybe Capsule.decode) x of
                    Ok c ->
                        Core.AcquisitionMsg (Acquisition.CapsuleUpdated c)

                    _ ->
                        Core.Noop
            )
        , Ports.progressReceived (\x -> Core.AcquisitionMsg (Acquisition.ProgressReceived x))
        , Ports.deviceDetectionFailed (\_ -> Core.AcquisitionMsg Acquisition.DeviceDetectionFailed)
        , Ports.bindingWebcamFailed (\_ -> Core.AcquisitionMsg Acquisition.WebcamBindingFailed)
        , Ports.uploadRecordFailed (\_ -> Core.AcquisitionMsg Acquisition.UploadRecordFailed)
        ]
