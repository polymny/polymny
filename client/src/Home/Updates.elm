port module Home.Updates exposing
    ( update
    , selected, subs
    )

{-| This module contains the update function of the home page.

@docs update


# Subscriptions

@docs selected, subs

-}

import Api.Capsule as Api
import Api.User as Api
import App.Types as App
import Data.Types as Data
import Data.User as Data
import File
import FileValue
import Home.Types as Home
import Json.Decode as Decode
import NewCapsule.Types as NewCapsule
import RemoteData exposing (RemoteData)
import Strings
import Utils


{-| The update function of the home view.
-}
update : Home.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case model.page of
        App.Home m ->
            case msg of
                Home.Toggle p ->
                    ( { model | user = Data.toggleProject p model.user }, Cmd.none )

                Home.SlideUploadClicked ->
                    ( model
                    , Utils.tern (Data.isPremium model.user) [ "application/pdf", "application/zip" ] [ "application/pdf" ]
                        |> select Nothing
                    )

                Home.SlideUploadReceived project fileValue file ->
                    case fileValue.mime of
                        "application/pdf" ->
                            let
                                projectName =
                                    Maybe.withDefault (Strings.stepsPreparationNewProject model.config.clientState.lang) project

                                name =
                                    fileValue.name
                                        |> String.split "."
                                        |> List.reverse
                                        |> List.drop 1
                                        |> List.reverse
                                        |> String.join "."

                                newPage =
                                    RemoteData.Loading Nothing
                                        |> NewCapsule.init model.config.clientState.lang project name
                                        |> App.NewCapsule
                            in
                            ( { model | page = newPage }
                            , Api.uploadSlideShow
                                { project = projectName
                                , fileValue = fileValue
                                , file = file
                                , toMsg = \x -> App.NewCapsuleMsg (NewCapsule.SlideUpload x)
                                }
                            )

                        -- TODO : manage "application/zip"
                        _ ->
                            ( model, Cmd.none )

                Home.DeleteCapsule Utils.Request capsule ->
                    ( { model | page = App.Home { m | popupType = Just (Home.DeleteCapsulePopup capsule) } }, Cmd.none )

                Home.DeleteCapsule Utils.Cancel _ ->
                    ( { model | page = App.Home { m | popupType = Nothing } }, Cmd.none )

                Home.DeleteCapsule Utils.Confirm capsule ->
                    let
                        project =
                            model.user.projects |> List.filter (\p -> p.name == capsule.project) |> List.head

                        new_project =
                            case project of
                                Just p ->
                                    { p | capsules = List.filter (\c -> c.id /= capsule.id) p.capsules }

                                Nothing ->
                                    -- Internal error
                                    { name = capsule.project, capsules = [], folded = False }

                        user =
                            model.user

                        new_user =
                            let
                                projects =
                                    user.projects
                                        |> List.filter (\p -> p.name /= capsule.project)
                                        |> List.append
                                            (if new_project.capsules == [] then
                                                []

                                             else
                                                [ new_project ]
                                            )
                            in
                            { user | projects = projects }

                        new_model =
                            { model
                                | user = new_user
                                , page = App.Home { m | popupType = Nothing }
                            }
                    in
                    ( new_model, Api.deleteCapsule capsule (\_ -> App.Noop) )

                Home.RenameCapsule Utils.Request capsule ->
                    ( { model | page = App.Home { m | popupType = Just (Home.RenameCapsulePopup capsule) } }, Cmd.none )

                Home.RenameCapsule Utils.Cancel _ ->
                    ( { model | page = App.Home { m | popupType = Nothing } }, Cmd.none )

                Home.RenameCapsule Utils.Confirm capsule ->
                    let
                        project =
                            model.user.projects |> List.filter (\p -> p.name == capsule.project) |> List.head

                        new_project =
                            case project of
                                Just p ->
                                    { p
                                        | capsules =
                                            List.map
                                                (\c ->
                                                    if c.id == capsule.id then
                                                        capsule

                                                    else
                                                        c
                                                )
                                                p.capsules
                                    }

                                Nothing ->
                                    -- Internal error
                                    { name = capsule.project, capsules = [], folded = False }

                        user =
                            model.user

                        new_user =
                            let
                                projects =
                                    user.projects
                                        |> List.filter (\p -> p.name /= capsule.project)
                                        |> List.append [ new_project ]
                            in
                            { user | projects = projects }
                    in
                    ( { model | user = new_user, page = App.Home { m | popupType = Nothing } }
                    , Api.updateCapsule capsule (\_ -> App.Noop)
                    )

                Home.CapsuleNameChanged capsule name ->
                    let
                        new_capsule =
                            { capsule | name = name }
                    in
                    ( { model | page = App.Home { m | popupType = Just (Home.RenameCapsulePopup new_capsule) } }, Cmd.none )

                Home.DeleteProject Utils.Request project ->
                    ( { model | page = App.Home { m | popupType = Just (Home.DeleteProjectPopup project) } }, Cmd.none )

                Home.DeleteProject Utils.Cancel _ ->
                    ( { model | page = App.Home { m | popupType = Nothing } }, Cmd.none )

                Home.DeleteProject Utils.Confirm project ->
                    let
                        user =
                            model.user

                        new_user =
                            { user | projects = List.filter (\p -> p.name /= project.name) user.projects }

                        new_model =
                            { model
                                | user = new_user
                                , page = App.Home { m | popupType = Nothing }
                            }
                    in
                    ( new_model, Api.deleteProject project.name (\_ -> App.Noop) )

                Home.RenameProject Utils.Request project ->
                    ( { model | page = App.Home { m | popupType = Just (Home.RenameProjectPopup project) } }, Cmd.none )

                Home.RenameProject Utils.Cancel _ ->
                    ( { model | page = App.Home { m | popupType = Nothing } }, Cmd.none )

                Home.RenameProject Utils.Confirm project ->
                    let
                        prev_project_name =
                            project.capsules
                                |> List.map (\c -> c.project)
                                |> List.head
                                -- Internal error
                                |> Maybe.withDefault ""

                        capsules_write =
                            project.capsules
                                |> List.filter (\c -> c.role == Data.Write || c.role == Data.Owner)
                                |> List.map (\c -> { c | project = project.name })

                        capsules_non_write =
                            project.capsules
                                |> List.filter (\c -> c.role == Data.Read)

                        new_project =
                            model.user.projects
                                |> List.filter (\p -> p.name == project.name)
                                |> List.head
                                |> Maybe.withDefault { project | capsules = [], folded = False }
                                |> (\p -> { p | capsules = p.capsules |> List.append capsules_write })

                        prev_project =
                            case capsules_non_write of
                                [] ->
                                    Nothing

                                _ ->
                                    Just
                                        { name = prev_project_name
                                        , capsules = capsules_non_write
                                        , folded = False
                                        }

                        user =
                            model.user

                        new_user =
                            let
                                projects =
                                    user.projects
                                        |> List.filter (\p -> p.name /= prev_project_name && p.name /= project.name)
                                        |> List.append [ new_project ]
                                        |> List.append
                                            (case prev_project of
                                                Just p ->
                                                    [ p ]

                                                Nothing ->
                                                    []
                                            )
                            in
                            { user | projects = projects }
                    in
                    ( { model | user = new_user, page = App.Home { m | popupType = Nothing } }
                    , capsules_write
                        |> List.map (\c -> Api.updateCapsule c (\_ -> App.Noop))
                        |> Cmd.batch
                    )

                Home.ProjectNameChanged project name ->
                    let
                        new_project =
                            { project | name = name }
                    in
                    ( { model | page = App.Home { m | popupType = Just (Home.RenameProjectPopup new_project) } }, Cmd.none )

                Home.SortBy sort_key ->
                    let
                        sort_by =
                            model.config.clientConfig.sortBy

                        new_sort_by =
                            let
                                key =
                                    sort_by.key

                                ascending =
                                    sort_by.ascending
                            in
                            if key == sort_key then
                                { sort_by | ascending = not ascending }

                            else
                                { sort_by | key = sort_key }

                        client_config =
                            model.config.clientConfig

                        new_client_config =
                            { client_config | sortBy = new_sort_by }

                        config =
                            model.config

                        new_config =
                            { config | clientConfig = new_client_config }
                    in
                    ( { model | config = new_config }, Cmd.none )

        _ ->
            ( model, Cmd.none )


{-| Port to ask to select a file.
-}
select : Maybe Data.Project -> List String -> Cmd msg
select project mimeTypesAllowed =
    selectPort ( Maybe.map .name project, mimeTypesAllowed )


{-| Port to ask to select a file.
-}
port selectPort : ( Maybe String, List String ) -> Cmd msg


{-| Subscription to receive the selected file.
-}
port selected : (( Maybe String, Decode.Value ) -> msg) -> Sub msg


{-| Subscriptions of the page.
-}
subs : Sub App.Msg
subs =
    selected
        (\( p, x ) ->
            case ( Decode.decodeValue FileValue.decoder x, Decode.decodeValue File.decoder x ) of
                ( Ok y, Ok z ) ->
                    App.HomeMsg (Home.SlideUploadReceived p y z)

                _ ->
                    App.Noop
        )
