module NewCapsule.Updates exposing (update)

{-| This module contains the update function for the new capsule page.

@docs update

-}

import Api.Capsule as Api
import Api.User as Api
import App.Types as App
import Data.Capsule as Data
import Data.User as Data
import Home.Types as Home
import NewCapsule.Types as NewCapsule
import Keyboard
import RemoteData
import Route


{-| The update function of the new capsule page.
-}
update : NewCapsule.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case ( model.page, msg ) of
        ( App.NewCapsule m, NewCapsule.SlideUpload newSlideUpload ) ->
            let
                prepared =
                    RemoteData.map
                        (\x -> ( { x | name = m.capsuleName, project = m.projectName }, NewCapsule.prepare x ))
                        newSlideUpload

                newUser =
                    RemoteData.map (\x -> Data.addCapsule x model.user) newSlideUpload
                        |> RemoteData.withDefault model.user
            in
            ( mkModel { m | slideUpload = prepared } { model | user = newUser }, Cmd.none )

        ( App.NewCapsule m, NewCapsule.CapsuleUpdate c ) ->
            case ( m.slideUpload, c ) of
                ( RemoteData.Success ( capsule, _ ), ( nextPage, RemoteData.Success () ) ) ->
                    let
                        cmd =
                            case nextPage of
                                NewCapsule.Preparation ->
                                    Route.push model.config.clientState.key (Route.Preparation capsule.id)

                                NewCapsule.Acquisition ->
                                    Route.push model.config.clientState.key (Route.Acquisition capsule.id 0)
                    in
                    ( { model | user = Data.updateUser capsule model.user }, cmd )

                _ ->
                    ( mkModel { m | capsuleUpdate = c } model, Cmd.none )

        ( App.NewCapsule m, NewCapsule.NameChanged newName ) ->
            let
                newSlideUpload =
                    RemoteData.map (\( x, y ) -> ( { x | name = newName }, y ))
                        m.slideUpload
            in
            ( mkModel { m | capsuleName = newName, slideUpload = newSlideUpload } model, Cmd.none )

        ( App.NewCapsule m, NewCapsule.ProjectChanged newName ) ->
            let
                newSlideUpload =
                    RemoteData.map (\( x, y ) -> ( { x | project = newName }, y ))
                        m.slideUpload
            in
            ( mkModel { m | projectName = newName, slideUpload = newSlideUpload } model, Cmd.none )

        ( App.NewCapsule m, NewCapsule.DelimiterClicked b i ) ->
            let
                slideUploadMapper : ( Data.Capsule, List NewCapsule.Slide ) -> ( Data.Capsule, List NewCapsule.Slide )
                slideUploadMapper ( capsule, slides ) =
                    let
                        newSlides =
                            NewCapsule.toggle b i slides

                        newCapsule =
                            { capsule | structure = NewCapsule.structureFromUi newSlides }
                    in
                    ( newCapsule, newSlides )
            in
            ( mkModel { m | slideUpload = RemoteData.map slideUploadMapper m.slideUpload } model, Cmd.none )

        ( App.NewCapsule m, NewCapsule.Submit nextPage ) ->
            ( model, RemoteData.map (\( x, _ ) -> updateCapsule nextPage x) m.slideUpload |> RemoteData.withDefault Cmd.none )

        ( App.NewCapsule m, NewCapsule.Cancel ) ->
            case m.slideUpload of
                RemoteData.Success ( c, _ ) ->
                    ( { model | page = App.Home Home.init }, Api.deleteCapsule c (\_ -> App.Noop) )

                _ ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


{-| A utility function to easily change the page of the model.
-}
mkModel : NewCapsule.Model -> App.Model -> App.Model
mkModel m model =
    { model | page = App.NewCapsule m }


{-| A utility function to easily create the command to update the capsule.
-}
updateCapsule : NewCapsule.NextPage -> Data.Capsule -> Cmd App.Msg
updateCapsule nextPage capsule =
    Api.updateCapsule capsule (\x -> App.NewCapsuleMsg (NewCapsule.CapsuleUpdate ( nextPage, x )))


{-| Keyboard shortcuts of the home page.
-}
shortcuts : Keyboard.RawKey -> App.Msg
shortcuts msg =
    case Keyboard.rawValue msg of
        "Escape" ->
            App.NewCapsuleMsg NewCapsule.Cancel

        "Enter" ->
            App.NewCapsuleMsg <| NewCapsule.Submit NewCapsule.Preparation

        _ ->
            App.Noop


{-| Subscriptions of the page.
-}
subs : Sub App.Msg
subs =
    Sub.batch
        [ Keyboard.ups shortcuts ]
