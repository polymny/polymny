module NewCapsule.Updates exposing (update)

{-| This module contains the update function for the new capsule page.

@docs update

-}

import App.Types as App
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
                    RemoteData.map (\x -> ( x, NewCapsule.prepare x )) newSlideUpload
            in
            ( mkModel { m | slideUpload = prepared } model, Cmd.none )

        ( App.NewCapsule m, NewCapsule.NameChanged newName ) ->
            ( mkModel { m | capsuleName = newName } model, Cmd.none )

        ( App.NewCapsule m, NewCapsule.ProjectChanged newName ) ->
            ( mkModel { m | projectName = newName } model, Cmd.none )

        _ ->
            ( model, Cmd.none )


{-| A utility function to easily change the page of the model.
-}
mkModel : NewCapsule.Model -> App.Model -> App.Model
mkModel m model =
    { model | page = App.NewCapsule m }
