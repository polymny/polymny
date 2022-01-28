module Core.Subscriptions exposing (..)

import Acquisition.Subscriptions as Acquisition
import Acquisition.Types as Acquisition
import Capsule
import Core.Ports as Ports
import Core.Types as Core
import FileValue
import Json.Decode as Decode exposing (Decoder)
import Log
import Preparation.Subscriptions as Preparation
import Preparation.Types as Preparation
import Production.Subscriptions as Production
import User


decodeWebsocketMsg : Decoder Core.Msg
decodeWebsocketMsg =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\x ->
                case x of
                    "notification" ->
                        User.decodeNotification |> Decode.map Core.NotificationReceived

                    "capsule_production_finished" ->
                        Decode.field "id" Decode.string |> Decode.map Core.ProductionFinished

                    "capsule_publication_finished" ->
                        Decode.field "id" Decode.string |> Decode.map Core.PublicationFinished

                    "capsule_production_progress" ->
                        Decode.map2 Core.ProductionProgress
                            (Decode.field "id" Decode.string)
                            (Decode.field "msg" Decode.float)

                    "video_upload_progress" ->
                        Decode.map2 Core.VideoUploadProgress
                            (Decode.field "id" Decode.string)
                            (Decode.field "msg" Decode.float)

                    "video_upload_finished" ->
                        Decode.field "id" Decode.string |> Decode.map Core.VideoUploadFinished

                    "capsule_changed" ->
                        Capsule.decode |> Decode.map Core.CapsuleChanged

                    _ ->
                        Decode.fail ("Unknown message type " ++ x)
            )


subscriptions : Maybe Core.Model -> Sub Core.Msg
subscriptions model =
    Sub.batch
        [ Ports.websocketMsg
            (\x ->
                case Decode.decodeValue decodeWebsocketMsg x of
                    Ok y ->
                        y

                    Err e ->
                        let
                            _ =
                                Log.debug "error parsing websocket msg" e
                        in
                        Core.Noop
            )
        , Ports.selected
            (\( p, x ) ->
                case Decode.decodeValue FileValue.decoder x of
                    Ok y ->
                        Core.SlideUploaded p y

                    _ ->
                        Core.Noop
            )
        , Acquisition.devicesReceived |> Sub.map Core.AcquisitionMsg
        , case model of
            Just m ->
                case m.page of
                    Core.Preparation p ->
                        Preparation.subscriptions p

                    Core.Acquisition p ->
                        Acquisition.subscriptions p

                    Core.Production p ->
                        Production.subscriptions p

                    _ ->
                        Sub.none

            _ ->
                Sub.none
        ]
