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
import Config
import Data.Capsule as Data
import Data.Types as Data
import Data.User as Data
import File
import FileValue
import Home.Types as Home
import Json.Decode as Decode
import Json.Encode as Encode
import Keyboard
import NewCapsule.Types as NewCapsule
import RemoteData
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

                Home.SlideUploadClicked projectName ->
                    ( model
                    , Utils.tern (Data.isPremium model.user) [ "application/pdf", "application/zip" ] [ "application/pdf" ]
                        |> select projectName
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

                        "application/zip" ->
                            if Data.isPremium model.user then
                                let
                                    projectName : String
                                    projectName =
                                        Maybe.withDefault
                                            (Strings.stepsPreparationNewProject model.config.clientState.lang)
                                            project

                                    task : Config.TaskStatus
                                    task =
                                        { task = Config.ImportCapsule model.config.clientState.taskId
                                        , progress = Just 0.0
                                        , finished = False
                                        , aborted = False
                                        , global = True
                                        }

                                    ( newConfig, _ ) =
                                        Config.update (Config.UpdateTaskStatus task) model.config
                                in
                                ( { model | config = Config.incrementTaskId newConfig }
                                , importCapsule projectName fileValue.value model.config.clientState.taskId
                                )

                            else
                                ( model, Cmd.none )

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

                        newProject =
                            case project of
                                Just p ->
                                    { p | capsules = List.filter (\c -> c.id /= capsule.id) p.capsules }

                                Nothing ->
                                    -- Internal error
                                    { name = capsule.project, capsules = [], folded = False }

                        user =
                            model.user

                        newUser =
                            let
                                projects =
                                    user.projects
                                        |> List.filter (\p -> p.name /= capsule.project)
                                        |> List.append
                                            (if newProject.capsules == [] then
                                                []

                                             else
                                                [ newProject ]
                                            )
                            in
                            { user | projects = projects }

                        newModel =
                            { model
                                | user = newUser
                                , page = App.Home { m | popupType = Nothing }
                            }
                    in
                    ( newModel, Api.deleteCapsule capsule (\_ -> App.Noop) )

                Home.RenameCapsule Utils.Request capsule ->
                    ( { model | page = App.Home { m | popupType = Just (Home.RenameCapsulePopup capsule) } }, Cmd.none )

                Home.RenameCapsule Utils.Cancel _ ->
                    ( { model | page = App.Home { m | popupType = Nothing } }, Cmd.none )

                Home.RenameCapsule Utils.Confirm capsule ->
                    let
                        project =
                            model.user.projects |> List.filter (\p -> p.name == capsule.project) |> List.head

                        newProject =
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

                        newUser =
                            let
                                projects =
                                    user.projects
                                        |> List.filter (\p -> p.name /= capsule.project)
                                        |> List.append [ newProject ]
                            in
                            { user | projects = projects }
                    in
                    ( { model | user = newUser, page = App.Home { m | popupType = Nothing } }
                    , Api.updateCapsule capsule (\_ -> App.Noop)
                    )

                Home.CapsuleNameChanged capsule name ->
                    let
                        newCapsule =
                            { capsule | name = name }
                    in
                    ( { model | page = App.Home { m | popupType = Just (Home.RenameCapsulePopup newCapsule) } }, Cmd.none )

                Home.DeleteProject Utils.Request project ->
                    ( { model | page = App.Home { m | popupType = Just (Home.DeleteProjectPopup project) } }, Cmd.none )

                Home.DeleteProject Utils.Cancel _ ->
                    ( { model | page = App.Home { m | popupType = Nothing } }, Cmd.none )

                Home.DeleteProject Utils.Confirm project ->
                    let
                        user =
                            model.user

                        newUser =
                            { user | projects = List.filter (\p -> p.name /= project.name) user.projects }

                        newModel =
                            { model
                                | user = newUser
                                , page = App.Home { m | popupType = Nothing }
                            }
                    in
                    ( newModel, Api.deleteProject project.name (\_ -> App.Noop) )

                Home.RenameProject Utils.Request project ->
                    ( { model | page = App.Home { m | popupType = Just (Home.RenameProjectPopup project) } }, Cmd.none )

                Home.RenameProject Utils.Cancel _ ->
                    ( { model | page = App.Home { m | popupType = Nothing } }, Cmd.none )

                Home.RenameProject Utils.Confirm project ->
                    let
                        prevProjectName =
                            project.capsules
                                |> List.map (\c -> c.project)
                                |> List.head
                                -- Internal error
                                |> Maybe.withDefault ""

                        capsulesWrite =
                            project.capsules
                                |> List.filter (\c -> c.role == Data.Write || c.role == Data.Owner)
                                |> List.map (\c -> { c | project = project.name })

                        capsulesNonWrite =
                            project.capsules
                                |> List.filter (\c -> c.role == Data.Read)

                        newProject =
                            model.user.projects
                                |> List.filter (\p -> p.name == project.name)
                                |> List.head
                                |> Maybe.withDefault { project | capsules = [], folded = False }
                                |> (\p -> { p | capsules = p.capsules |> List.append capsulesWrite })

                        prevProject =
                            case capsulesNonWrite of
                                [] ->
                                    Nothing

                                _ ->
                                    Just
                                        { name = prevProjectName
                                        , capsules = capsulesNonWrite
                                        , folded = False
                                        }

                        user =
                            model.user

                        newUser =
                            let
                                projects =
                                    user.projects
                                        |> List.filter (\p -> p.name /= prevProjectName && p.name /= project.name)
                                        |> List.append [ newProject ]
                                        |> List.append
                                            (case prevProject of
                                                Just p ->
                                                    [ p ]

                                                Nothing ->
                                                    []
                                            )
                            in
                            { user | projects = projects }

                        newModel =
                            if prevProjectName == project.name then
                                { model | page = App.Home { m | popupType = Nothing } }

                            else
                                { model | user = newUser, page = App.Home { m | popupType = Nothing } }
                    in
                    ( newModel
                    , capsulesWrite
                        |> List.map (\c -> Api.updateCapsule c (\_ -> App.Noop))
                        |> Cmd.batch
                    )

                Home.ProjectNameChanged project name ->
                    let
                        newProject =
                            { project | name = name }
                    in
                    ( { model | page = App.Home { m | popupType = Just (Home.RenameProjectPopup newProject) } }, Cmd.none )

                Home.SortBy sortKey ->
                    let
                        sortBy =
                            model.config.clientConfig.sortBy

                        newSortBy =
                            let
                                key =
                                    sortBy.key

                                ascending =
                                    sortBy.ascending
                            in
                            if key == sortKey then
                                { sortBy | ascending = not ascending }

                            else
                                { sortBy | key = sortKey }

                        clientConfig =
                            model.config.clientConfig

                        newClientConfig =
                            { clientConfig | sortBy = newSortBy }

                        config =
                            model.config

                        newConfig =
                            { config | clientConfig = newClientConfig }
                    in
                    ( { model | config = newConfig }, Cmd.none )

                Home.EscapePressed ->
                    ( { model | page = App.Home { m | popupType = Nothing } }, Cmd.none )

                Home.EnterPressed ->
                    case m.popupType of
                        Just (Home.RenameProjectPopup project) ->
                            update (Home.RenameProject Utils.Confirm project) model

                        Just (Home.RenameCapsulePopup capsule) ->
                            update (Home.RenameCapsule Utils.Confirm capsule) model

                        Just (Home.DeleteProjectPopup project) ->
                            update (Home.DeleteProject Utils.Confirm project) model

                        Just (Home.DeleteCapsulePopup capsule) ->
                            update (Home.DeleteCapsule Utils.Confirm capsule) model

                        Nothing ->
                            ( model, Cmd.none )

                Home.ExportCapsule capsule ->
                    let
                        task : Config.TaskStatus
                        task =
                            { task = Config.ExportCapsule model.config.clientState.taskId capsule.id
                            , progress = Just 0.0
                            , finished = False
                            , aborted = False
                            , global = True
                            }

                        ( newConfig, _ ) =
                            Config.update (Config.UpdateTaskStatus task) model.config
                    in
                    ( { model | config = Config.incrementTaskId newConfig }, exportCapsule capsule model.config.clientState.taskId )

                Home.CapsuleUpdated capsule ->
                    let
                        user : Data.User
                        user =
                            model.user

                        projectNames : List String
                        projectNames =
                            user.projects
                                |> List.map (\p -> p.name)

                        newProjects : List Data.Project
                        newProjects =
                            if List.member capsule.project projectNames then
                                user.projects
                                    |> List.map (\p -> { p | capsules = List.filter (\c -> c.id /= capsule.id) p.capsules })
                                    |> List.map
                                        (\p ->
                                            { p
                                                | capsules =
                                                    if p.name == capsule.project then
                                                        capsule :: p.capsules

                                                    else
                                                        p.capsules
                                            }
                                        )

                            else
                                let
                                    newProject : Data.Project
                                    newProject =
                                        { name = capsule.project
                                        , capsules = [ capsule ]
                                        , folded = False
                                        }
                                in
                                newProject :: user.projects
                    in
                    ( { model | user = { user | projects = newProjects } }, Cmd.none )

                Home.DuplicateCapsule c ->
                    ( model
                    , Api.duplicateCapsule c
                        (\r ->
                            case r of
                                RemoteData.Success duplicated ->
                                    App.HomeMsg (Home.CapsuleUpdated duplicated)

                                _ ->
                                    App.Noop
                        )
                    )

        _ ->
            ( model, Cmd.none )


{-| Port to ask to select a file.
-}
select : Maybe String -> List String -> Cmd msg
select project mimeTypesAllowed =
    selectPort ( project, mimeTypesAllowed )


{-| Port to ask to select a file.
-}
port selectPort : ( Maybe String, List String ) -> Cmd msg


{-| Subscription to receive the selected file.
-}
port selected : (( Maybe String, Decode.Value ) -> msg) -> Sub msg


{-| Keyboard shortcuts of the home page.
-}
shortcuts : Keyboard.RawKey -> App.Msg
shortcuts msg =
    case Keyboard.rawValue msg of
        "Escape" ->
            App.HomeMsg Home.EscapePressed

        "Enter" ->
            App.HomeMsg Home.EnterPressed

        _ ->
            App.Noop


exportCapsule : Data.Capsule -> Config.TaskId -> Cmd msg
exportCapsule capsule taskId =
    exportCapsulePort ( Data.encodeCapsuleAll capsule, taskId )


{-| Port to export a capsule.
-}
port exportCapsulePort : ( Decode.Value, Config.TaskId ) -> Cmd msg


{-| Port to import a capsule.
-}
importCapsule : String -> Decode.Value -> Config.TaskId -> Cmd msg
importCapsule project file taskId =
    importCapsulePort ( project, file, taskId )


{-| Port to import a capsule.
-}
port importCapsulePort : ( String, Decode.Value, Config.TaskId ) -> Cmd msg


{-| Subscription to capsule update.
-}
port capsuleUpdated : (Encode.Value -> msg) -> Sub msg


{-| Subscriptions of the page.
-}
subs : Sub App.Msg
subs =
    Sub.batch
        [ selected
            (\( p, x ) ->
                case ( Decode.decodeValue FileValue.decoder x, Decode.decodeValue File.decoder x ) of
                    ( Ok y, Ok z ) ->
                        App.HomeMsg (Home.SlideUploadReceived p y z)

                    _ ->
                        App.Noop
            )
        , Keyboard.ups shortcuts
        , capsuleUpdated
            (\x ->
                case Decode.decodeValue Data.decodeCapsule x of
                    Ok y ->
                        App.HomeMsg (Home.CapsuleUpdated y)

                    _ ->
                        App.Noop
            )
        ]
