module Collaboration.Updates exposing (..)

{-| This module helps us deal with collaboration updates.
-}

import Api.Capsule as Api
import App.Types as App
import App.Utils as App
import Collaboration.Types as Collaboration
import Data.Types as Data
import Data.User as Data
import RemoteData


{-| Update function for the collaboration page.
-}
update : Collaboration.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    let
        ( maybeCapsule, maybeGos ) =
            App.capsuleAndGos model.user model.page
    in
    case ( model.page, maybeCapsule ) of
        ( App.Collaboration m, Just capsule ) ->
            case msg of
                Collaboration.NewCollaboratorChanged n ->
                    ( { model | page = App.Collaboration { m | newCollaborator = n } }, Cmd.none )

                Collaboration.NewCollaboratorFormChanged (RemoteData.Success ()) ->
                    let
                        newCollaborators =
                            capsule.collaborators ++ [ { username = m.newCollaborator, role = Data.Read } ]

                        newCapsule =
                            { capsule | collaborators = newCollaborators }

                        newUser =
                            Data.updateUser newCapsule model.user
                    in
                    ( { model | user = newUser, page = App.Collaboration { m | newCollaborator = "", newCollaboratorForm = RemoteData.Success () } }
                    , Cmd.none
                    )

                Collaboration.NewCollaboratorFormChanged n ->
                    ( { model | page = App.Collaboration { m | newCollaboratorForm = n } }, Cmd.none )

                Collaboration.NewCollaboratorFormSubmitted ->
                    ( { model | page = App.Collaboration { m | newCollaboratorForm = RemoteData.Loading Nothing } }
                    , Api.addCollaborator
                        capsule
                        m.newCollaborator
                        Data.Read
                        (\x -> App.CollaborationMsg <| Collaboration.NewCollaboratorFormChanged x)
                    )

                Collaboration.RemoveCollaborator u ->
                    let
                        newCollaborators =
                            capsule.collaborators
                                |> List.filter (\x -> x.username /= u.username)

                        newCapsule =
                            { capsule | collaborators = newCollaborators }

                        newUser =
                            Data.updateUser newCapsule model.user
                    in
                    ( { model | user = newUser }
                    , Api.removeCollaborator capsule u.username (\_ -> App.Noop)
                    )

                Collaboration.SwitchRole u ->
                    let
                        newRole =
                            if u.role == Data.Read then
                                Data.Write

                            else
                                Data.Read

                        collaboratorUpdater collaborator =
                            if collaborator.username == u.username then
                                { collaborator | role = newRole }

                            else
                                collaborator

                        newCapsule =
                            { capsule | collaborators = List.map collaboratorUpdater capsule.collaborators }

                        newUser =
                            Data.updateUser newCapsule model.user
                    in
                    ( { model | user = newUser }
                    , Api.changeCollaboratorRole capsule u.username newRole (\_ -> App.Noop)
                    )

        _ ->
            ( model, Cmd.none )
