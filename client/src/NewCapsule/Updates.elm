module NewCapsule.Updates exposing (update)

{-| This module contains the update function for the new capsule page.

@docs update

-}

import Api.Capsule as Api
import App.Types as App
import Data.Capsule as Data
import NewCapsule.Types as NewCapsule
import RemoteData


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
            in
            ( mkModel { m | slideUpload = prepared } model, Cmd.none )

        ( App.NewCapsule m, NewCapsule.CapsuleUpdate c ) ->
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

        ( App.NewCapsule m, NewCapsule.GoToPreparation ) ->
            ( model, RemoteData.map (\( x, _ ) -> updateCapsule x) m.slideUpload |> RemoteData.withDefault Cmd.none )

        ( App.NewCapsule m, NewCapsule.GoToAcquisition ) ->
            ( model, RemoteData.map (\( x, _ ) -> updateCapsule x) m.slideUpload |> RemoteData.withDefault Cmd.none )

        ( App.NewCapsule m, NewCapsule.Cancel ) ->
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
updateCapsule : Data.Capsule -> Cmd App.Msg
updateCapsule capsule =
    Api.updateCapsule capsule (\x -> App.NewCapsuleMsg (NewCapsule.CapsuleUpdate x))
