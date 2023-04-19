module NewCapsule.Updates exposing (..)

import Api
import Capsule
import Core.Types as Core
import NewCapsule.Types as NewCapsule
import RemoteData exposing (RemoteData)
import Route
import User


update : NewCapsule.Msg -> Core.Model -> ( Core.Model, Cmd Core.Msg )
update msg model =
    case model.page of
        Core.NewCapsule m ->
            case msg of
                NewCapsule.SlideClicked index ->
                    let
                        increment : List ( Int, Capsule.Slide ) -> List ( Int, Capsule.Slide )
                        increment =
                            List.map (\( x, y ) -> ( x + 1, y ))

                        slides =
                            RemoteData.andThen
                                (\( c, s ) ->
                                    case ( List.head (List.drop (index - 1) s), List.head (List.drop index s) ) of
                                        ( _, Nothing ) ->
                                            RemoteData.Failure ()

                                        ( Nothing, _ ) ->
                                            RemoteData.mapError (\_ -> ()) m.capsule

                                        ( Just ( ip, _ ), Just ( i, slide ) ) ->
                                            if ip == i then
                                                RemoteData.Success ( c, List.take index s ++ (( i + 1, slide ) :: List.drop (index + 1) (increment s)) )

                                            else
                                                RemoteData.Success ( c, List.take index s ++ (( ip, slide ) :: List.drop (index + 1) s) )
                                )
                                (RemoteData.mapError (\_ -> ()) m.capsule)

                        reindexSlidesAux : Int -> Int -> List ( Int, Capsule.Slide ) -> List ( Int, Capsule.Slide ) -> List ( Int, Capsule.Slide )
                        reindexSlidesAux counter currentValue current input =
                            case input of
                                [] ->
                                    current

                                ( i, s ) :: t ->
                                    if i /= currentValue then
                                        reindexSlidesAux (counter + 1) i (( counter + 1, s ) :: current) t

                                    else
                                        reindexSlidesAux counter i (( counter, s ) :: current) t

                        reindexSlides : List ( Int, Capsule.Slide ) -> List ( Int, Capsule.Slide )
                        reindexSlides input =
                            List.reverse (reindexSlidesAux 0 0 [] input)

                        newSlides : RemoteData () (List ( Int, Capsule.Slide ))
                        newSlides =
                            RemoteData.map reindexSlides (RemoteData.map Tuple.second slides)

                        ( newCapsule, newUser, cmd ) =
                            case ( m.capsule, newSlides ) of
                                ( RemoteData.Success ( c, _ ), RemoteData.Success n ) ->
                                    let
                                        newStructure =
                                            NewCapsule.structureFromUi n

                                        newC =
                                            { c | structure = newStructure }
                                    in
                                    ( RemoteData.Success ( newC, n )
                                    , User.changeCapsule newC model.user
                                    , Api.updateCapsule Core.Noop newC
                                    )

                                _ ->
                                    ( m.capsule, model.user, Cmd.none )

                        new =
                            { m | capsule = newCapsule }
                    in
                    ( { model | page = Core.NewCapsule new, user = newUser }, cmd )

                NewCapsule.Cancel ->
                    case m.capsule of
                        RemoteData.Success ( c, _ ) ->
                            ( { model | page = Core.Home Core.newHomeModel, user = User.removeCapsule c.id model.user }
                            , Api.deleteCapsule (\_ -> Core.Noop) c.id
                            )

                        _ ->
                            ( { model | page = Core.Home Core.newHomeModel }, Cmd.none )

                NewCapsule.ProjectChanged newProject ->
                    let
                        tmp =
                            { m | project = newProject }
                    in
                    ( { model | page = Core.NewCapsule tmp }, Cmd.none )

                NewCapsule.NameChanged newName ->
                    let
                        tmp =
                            { m | name = newName }
                    in
                    ( { model | page = Core.NewCapsule tmp }, Cmd.none )

                NewCapsule.GoToPreparation ->
                    case m.capsule of
                        RemoteData.Success ( c, _ ) ->
                            ( model
                            , Cmd.batch
                                [ Api.updateCapsule Core.Noop { c | name = m.name, project = m.project }
                                , Route.pushUrl model.global.key (Route.Preparation c.id Nothing)
                                ]
                            )

                        _ ->
                            ( model, Cmd.none )

                NewCapsule.GoToAcquisition ->
                    case m.capsule of
                        RemoteData.Success ( c, _ ) ->
                            ( model
                            , Cmd.batch
                                [ Api.updateCapsule Core.Noop { c | name = m.name, project = m.project }
                                , Route.pushUrl model.global.key (Route.Acquisition c.id 0)
                                ]
                            )

                        _ ->
                            ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )
