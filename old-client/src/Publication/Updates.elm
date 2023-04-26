module Publication.Updates exposing (..)

import Api
import Capsule
import Core.Types as Core
import Publication.Types as Publication
import User


update : Publication.Msg -> Core.Model -> ( Core.Model, Cmd Core.Msg )
update msg model =
    case model.page of
        Core.Publication m ->
            case msg of
                Publication.Publish ->
                    let
                        oldCapsule =
                            m.capsule

                        newCapsule =
                            { oldCapsule | published = Capsule.Running Nothing }

                        newShowPrivacyPopup =
                            m.capsule.privacy == Capsule.Private
                    in
                    ( mkModel
                        { model | user = User.changeCapsule newCapsule model.user }
                        (Core.Publication { m | capsule = newCapsule, showPrivacyPopup = newShowPrivacyPopup })
                    , Api.publishVideo (Core.PublicationMsg Publication.Published) m.capsule
                    )

                Publication.Unpublish ->
                    let
                        oldCapsule =
                            m.capsule

                        newCapsule =
                            { oldCapsule | published = Capsule.Idle }
                    in
                    ( mkModel
                        { model | user = User.changeCapsule newCapsule model.user }
                        (Core.Publication { m | capsule = newCapsule })
                    , Api.unpublishVideo Core.Noop m.capsule
                    )

                Publication.Published ->
                    ( model, Cmd.none )

                Publication.Cancel ->
                    let
                        oldCapsule =
                            m.capsule

                        newCapsule =
                            { oldCapsule | published = Capsule.Idle }
                    in
                    ( mkModel
                        { model | user = User.changeCapsule newCapsule model.user }
                        (Core.Publication { m | capsule = newCapsule })
                    , Api.cancelPublication (Core.PublicationMsg Publication.Published) m.capsule
                    )

                Publication.PrivacyChanged newPrivacy ->
                    let
                        oldCapsule =
                            m.capsule

                        newCapsule =
                            { oldCapsule | privacy = newPrivacy }
                    in
                    ( mkModel
                        { model | user = User.changeCapsule newCapsule model.user }
                        (Core.Publication { m | capsule = newCapsule })
                    , Api.updateCapsule Core.Noop newCapsule
                    )

                Publication.PromptSubtitlesChanged newPromptSubtitles ->
                    let
                        oldCapsule =
                            m.capsule

                        newCapsule =
                            { oldCapsule | promptSubtitles = newPromptSubtitles }
                    in
                    ( mkModel
                        { model | user = User.changeCapsule newCapsule model.user }
                        (Core.Publication { m | capsule = newCapsule })
                    , Api.updateCapsule Core.Noop newCapsule
                    )

                Publication.TogglePrivacyPopup ->
                    ( mkModel model (Core.Publication { m | showPrivacyPopup = not m.showPrivacyPopup }), Cmd.none )

        _ ->
            ( model, Cmd.none )


mkModel : Core.Model -> Core.Page -> Core.Model
mkModel input newPage =
    { input | page = newPage }
