module NewCapsule.Updates exposing (update)

{-| This module contains the update function for the new capsule page.

@docs update

-}

import App.Types as App
import NewCapsule.Types as NewCapsule


{-| The update function of the new capsule page.
-}
update : NewCapsule.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case ( model.page, msg ) of
        ( App.NewCapsule m, NewCapsule.SlideUpload newSlideUpload ) ->
            ( { model | page = App.NewCapsule { m | slideUpload = newSlideUpload } }, Cmd.none )

        _ ->
            ( model, Cmd.none )
