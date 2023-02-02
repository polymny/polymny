module Publication.Updates exposing (..)

{-| This module contains the updates for the publication view.
-}

import Api.Capsule as Api
import App.Types as App
import Data.Capsule as Data exposing (Capsule)
import Data.User as Data
import Publication.Types as Publication


update : Publication.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case model.page of
        App.Publication m ->
            let
                capsule =
                    m.capsule
            in
            case msg of
                Publication.TogglePrivacyPopup ->
                    ( { model | page = App.Publication { m | showPrivacyPopup = not m.showPrivacyPopup } }
                    , Cmd.none
                    )

                Publication.SetPrivacy privacy ->
                    updateModel { capsule | privacy = privacy } model m

                Publication.SetPromptSubtitles promptSubtitles ->
                    updateModel { capsule | promptSubtitles = promptSubtitles } model m

                Publication.PublishVideo ->
                    ( model, Api.publishCapsule m.capsule (\_ -> App.Noop) )

        _ ->
            ( model, Cmd.none )


{-| Changes the current gos in the model.
-}
updateModel : Capsule -> App.Model -> Publication.Model -> ( App.Model, Cmd App.Msg )
updateModel newCapsule model m =
    let
        newUser =
            Data.updateUser newCapsule model.user
    in
    ( { model | user = newUser, page = App.Publication { m | capsule = newCapsule } }
    , Api.updateCapsule newCapsule (\_ -> App.Noop)
    )
