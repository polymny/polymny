module Preparation.Subscriptions exposing (..)

import Core.Types as Core
import Http
import Preparation.Types as Preparation


subscriptions : Preparation.Model -> Sub Core.Msg
subscriptions model =
    Sub.batch
        [ Preparation.slideSystem.subscriptions model.slideModel |> Sub.map Preparation.DnD |> Sub.map Core.PreparationMsg
        , Preparation.gosSystem.subscriptions model.gosModel |> Sub.map Preparation.DnD |> Sub.map Core.PreparationMsg
        , case model.tracker of
            Just ( s, _ ) ->
                Http.track s
                    (\x ->
                        case x of
                            Http.Sending e ->
                                Core.PreparationMsg (Preparation.ExtraResourceProgress s (Preparation.Upload (Http.fractionSent e)))

                            _ ->
                                Core.Noop
                    )

            _ ->
                Sub.none
        ]
