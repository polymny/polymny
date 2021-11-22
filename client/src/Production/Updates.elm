module Production.Updates exposing (..)

import Api
import Capsule exposing (Capsule)
import Core.Types as Core
import Production.Types as Production
import User
import Utils exposing (tern)


update : Production.Msg -> Core.Model -> ( Core.Model, Cmd Core.Msg )
update msg model =
    case model.page of
        Core.Production m ->
            case List.head (List.drop m.gos m.capsule.structure) of
                Just gos ->
                    case msg of
                        Production.SetVideo b ->
                            updateModel { gos | webcamSettings = tern b Capsule.defaultWebcamSettings Capsule.Disabled } model m

                        Production.WebcamSizeChanged Production.Fullscreen ->
                            let
                                newOpacity =
                                    case gos.webcamSettings of
                                        Capsule.Pip { opacity } ->
                                            opacity

                                        Capsule.Fullscreen { opacity } ->
                                            opacity

                                        _ ->
                                            1.0

                                defaultFullscreen =
                                    Capsule.defaultFullscreen

                                newSettings =
                                    Capsule.Fullscreen { defaultFullscreen | opacity = newOpacity }
                            in
                            updateModel { gos | webcamSettings = newSettings } model m

                        Production.WebcamSizeChanged s ->
                            let
                                newSettings =
                                    case gos.webcamSettings of
                                        Capsule.Pip { anchor, position, opacity, keycolor } ->
                                            Capsule.Pip
                                                { anchor = anchor
                                                , position = position
                                                , size = Production.sizeToInt gos.record s
                                                , opacity = opacity
                                                , keycolor = keycolor
                                                }

                                        Capsule.Fullscreen { opacity } ->
                                            let
                                                defaultPip =
                                                    Capsule.defaultPip
                                            in
                                            Capsule.Pip { defaultPip | opacity = opacity, size = Production.sizeToInt gos.record s }

                                        x ->
                                            x
                            in
                            updateModel { gos | webcamSettings = newSettings } model m

                        Production.WebcamAnchorChanged a ->
                            let
                                newSettings =
                                    case gos.webcamSettings of
                                        Capsule.Pip { anchor, position, size, opacity, keycolor } ->
                                            Capsule.Pip
                                                { anchor = a
                                                , position = position
                                                , size = size
                                                , opacity = opacity
                                                , keycolor = keycolor
                                                }

                                        x ->
                                            x
                            in
                            updateModel { gos | webcamSettings = newSettings } model m

                        Production.WebcamOpacityChanged a ->
                            let
                                newSettings =
                                    case gos.webcamSettings of
                                        Capsule.Pip { anchor, position, size, opacity, keycolor } ->
                                            Capsule.Pip
                                                { anchor = anchor
                                                , position = position
                                                , size = size
                                                , opacity = a
                                                , keycolor = keycolor
                                                }

                                        Capsule.Fullscreen { opacity, keycolor } ->
                                            Capsule.Fullscreen { opacity = a, keycolor = keycolor }

                                        x ->
                                            x
                            in
                            updateModel { gos | webcamSettings = newSettings } model m

                        Production.WebcamKeyColorChanged a ->
                            let
                                newSettings =
                                    case gos.webcamSettings of
                                        Capsule.Pip { anchor, position, size, opacity, keycolor } ->
                                            Capsule.Pip
                                                { anchor = anchor
                                                , position = position
                                                , size = size
                                                , opacity = opacity
                                                , keycolor = a
                                                }

                                        Capsule.Fullscreen { opacity, keycolor } ->
                                            Capsule.Fullscreen { opacity = opacity, keycolor = a }

                                        x ->
                                            x
                            in
                            updateModel { gos | webcamSettings = newSettings } model m

                        Production.ProduceVideo ->
                            let
                                oldCapsule =
                                    m.capsule

                                newCapsule =
                                    { oldCapsule | produced = Capsule.Running Nothing, published = Capsule.Idle }
                            in
                            ( mkModel
                                { model | user = User.changeCapsule newCapsule model.user }
                                (Core.Production { m | capsule = newCapsule })
                            , Api.produceVideo (Core.ProductionMsg Production.VideoProduced) m.capsule
                            )

                        Production.CancelProduction ->
                            let
                                oldCapsule =
                                    m.capsule

                                newCapsule =
                                    { oldCapsule | produced = Capsule.Idle, published = Capsule.Idle }
                            in
                            ( mkModel
                                { model | user = User.changeCapsule newCapsule model.user }
                                (Core.Production { m | capsule = newCapsule })
                            , Api.cancelProduction Core.Noop m.capsule
                            )

                        Production.VideoProduced ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


mkModel : Core.Model -> Core.Page -> Core.Model
mkModel input newPage =
    { input | page = newPage }


updateModel : Capsule.Gos -> Core.Model -> Production.Model -> ( Core.Model, Cmd Core.Msg )
updateModel gos model m =
    let
        newCapsule =
            updateGos m.gos gos m.capsule
    in
    ( mkModel
        { model | user = User.changeCapsule newCapsule model.user }
        (Core.Production { m | capsule = newCapsule })
    , Api.updateCapsule Core.Noop newCapsule
    )


updateGos : Int -> Capsule.Gos -> Capsule -> Capsule
updateGos id gos capsule =
    let
        newStructure =
            List.indexedMap
                (\i g ->
                    if i == id then
                        gos

                    else
                        g
                )
                capsule.structure

        oldCapsule =
            capsule
    in
    { oldCapsule | structure = newStructure }