port module App.Updates exposing (update, updateModel, subs)

{-| This module contains the update function of the polymny application.

@docs update, updateModel, subs

-}

import Acquisition.Types as Acquisition
import Acquisition.Updates as Acquisition
import Api.User as Api
import App.Types as App
import App.Utils as App
import Browser.Navigation
import Collaboration.Types as Collaboration
import Collaboration.Updates as Collaboration
import Config
import Data.Capsule as Data
import Data.Types as Data
import Data.User as Data
import Device
import Home.Updates as Home
import Json.Decode as Decode exposing (Decoder)
import NewCapsule.Types as NewCapsule
import NewCapsule.Updates as NewCapsule
import Options.Types as Options
import Options.Updates as Options
import Preparation.Types as Preparation
import Preparation.Updates as Preparation
import Production.Types as Production
import Production.Updates as Production
import Profile.Types as Profile
import Profile.Updates as Profile
import Publication.Types as Publication
import Publication.Updates as Publication
import RemoteData
import Route
import Unlogged.Types as Unlogged
import Unlogged.Updates as Unlogged
import Utils


{-| Updates the model from a message, and returns the new model as well as the command to send.
-}
update : App.MaybeMsg -> App.MaybeModel -> ( App.MaybeModel, Cmd App.MaybeMsg )
update message model =
    case ( message, model ) of
        -- In some cases (transitions from unlogged to logged or vice versa), the update needs to be managed here
        -- because the submodulse will not know about UnloggedModel or LoggedModel.
        -- This can happen :
        -- When login succeeds
        ( App.UnloggedMsg (Unlogged.LoginRequestChanged (RemoteData.Success _)), App.Unlogged _ ) ->
            -- Reload page to fetch server data and connect to websocket
            ( model, Browser.Navigation.reload )

        -- When the user deletes their account
        ( App.LoggedMsg (App.ProfileMsg (Profile.DeleteAccountDataChanged (RemoteData.Success _))), App.Logged m ) ->
            ( model
            , case m.config.serverConfig.home of
                Just url ->
                    Browser.Navigation.load url

                _ ->
                    Route.push m.config.clientState.key Route.Home
            )

        -- If the sortBy is changed, we need to update the logged model's user
        ( App.LoggedMsg (App.ConfigMsg (Config.SortByChanged newSortBy)), App.Logged m ) ->
            let
                user =
                    m.user
            in
            updateModel (App.ConfigMsg (Config.SortByChanged newSortBy))
                { m | user = { user | projects = Data.sortProjects newSortBy user.projects } }
                |> Tuple.mapBoth App.Logged (Cmd.map App.LoggedMsg)

        -- If a config msg indicates that an upload record is finished
        ( App.LoggedMsg (App.ConfigMsg (Config.UpdateTaskStatus t)), App.Logged inputModel ) ->
            let
                ( m, cmd ) =
                    updateModel (App.ConfigMsg (Config.UpdateTaskStatus t)) inputModel
            in
            case ( t.finished, t.task ) of
                ( True, Config.UploadRecord taskId capsuleId gosId value ) ->
                    let
                        record : Maybe Data.Record
                        record =
                            case Decode.decodeValue Data.decodeRecord value of
                                Ok r ->
                                    Just r

                                _ ->
                                    Nothing

                        capsule : Maybe Data.Capsule
                        capsule =
                            Data.getCapsuleById capsuleId m.user

                        gos : Maybe Data.Gos
                        gos =
                            capsule
                                |> Maybe.andThen (\x -> List.drop gosId x.structure |> List.head)
                                |> Maybe.map (\x -> { x | record = record })

                        newCapsule : Maybe Data.Capsule
                        newCapsule =
                            case ( capsule, gos ) of
                                ( Just c, Just g ) ->
                                    Just <| Data.updateGos gosId g c

                                _ ->
                                    capsule

                        user : Data.User
                        user =
                            Maybe.map (\x -> Data.updateUser x m.user) newCapsule
                                |> Maybe.withDefault m.user
                    in
                    ( App.Logged { m | user = user }, Cmd.map App.LoggedMsg cmd )

                _ ->
                    ( App.Logged m, Cmd.map App.LoggedMsg cmd )

        -- If the user cancel the track upload.
        ( App.LoggedMsg (App.ConfigMsg (Config.AbortTask (Config.UploadTrack id capsuleId))), App.Logged { config, page, user } ) ->
            case page of
                App.Options _ ->
                    let
                        ( newConfig, cmdConfig ) =
                            Config.update (Config.AbortTask (Config.UploadTrack id capsuleId)) config

                        ( newModel, cmdOptions ) =
                            Options.update (Options.DeleteTrack Utils.Confirm Nothing) { config = newConfig, page = page, user = user }
                    in
                    ( App.Logged newModel, Cmd.map App.LoggedMsg <| Cmd.batch [ Cmd.map App.ConfigMsg cmdConfig, cmdOptions ] )

                _ ->
                    ( model, Cmd.none )

        ( App.LoggedMsg msg, App.Logged m ) ->
            updateModel msg m |> Tuple.mapBoth App.Logged (Cmd.map App.LoggedMsg)

        ( App.UnloggedMsg msg, App.Unlogged m ) ->
            Unlogged.update msg m
                |> Tuple.mapBoth App.Unlogged (Cmd.map App.UnloggedMsg)

        _ ->
            ( model, Cmd.none )


{-| Updates a well formed model from a message, and returns the new model as well as the command to send.
-}
updateModel : App.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
updateModel msg model =
    let
        -- We check if the user exited the acqusition page, in that case,
        -- we unbind the device to turn off the webcam light.
        unbindDevice =
            case ( model.page, updatedModel.page, leavingAcquisitionWithRecord ) of
                ( _, App.Acquisition _, _ ) ->
                    Cmd.none

                ( App.Acquisition _, _, False ) ->
                    Device.unbindDevice

                _ ->
                    Cmd.none

        -- We check if the user exited the options page, in which case we should
        -- stop the playing of the soundtrack.
        stopSoundtrackCmd =
            case ( model.page, updatedModel.page ) of
                ( _, App.Options _ ) ->
                    Cmd.none

                ( App.Options _, _ ) ->
                    Options.stopTrackPreviewPort ()

                _ ->
                    Cmd.none

        -- We check if the user is moving from acquisition to another acquisition, in which case we need to clear the
        -- pointer and the callbacks.
        clearPointerAndCallbacksCmd =
            let
                shouldClear =
                    case ( model.page, updatedModel.page ) of
                        -- If we're staying on acqusition page
                        ( App.Acquisition m1, App.Acquisition m2 ) ->
                            -- but we changed gos or capsule
                            m1.gos /= m2.gos || m1.capsule /= m2.capsule || m1.warnLeaving /= Nothing

                        ( _, App.Acquisition _ ) ->
                            False

                        _ ->
                            True
            in
            if shouldClear then
                clearPointerAndCallbacksPort ()

            else
                Cmd.none

        -- We check if the user is leaving the acquisition page, and if they have an unvalidated record.
        ( leavingAcquisitionWithRecord, leavingModel ) =
            case ( model.page, updatedModel.page ) of
                -- If we're staying on acqusition page
                ( App.Acquisition m1, App.Acquisition m2 ) ->
                    -- We should warn if we're changing gos or capsule and have new records
                    if (m1.gos /= m2.gos || m1.capsule /= m2.capsule) && List.any (\x -> not x.old) m1.records && m1.warnLeaving == Nothing then
                        ( True, { model | page = App.Acquisition { m1 | warnLeaving = Just <| Route.Acquisition m2.capsule m2.gos } } )

                    else
                        ( False, finalModel )

                -- We should not warn if you're ending in acqusition page otherwise
                ( _, App.Acquisition _ ) ->
                    ( False, finalModel )

                -- However, we should warn if you're leaving the acquisition page
                ( App.Acquisition m, newPage ) ->
                    -- Only if you have new records though
                    if List.any (\x -> not x.old) m.records && m.warnLeaving == Nothing then
                        ( True, { model | page = App.Acquisition { m | warnLeaving = Just <| App.routeFromPage newPage } } )

                    else
                        ( False, finalModel )

                _ ->
                    ( False, finalModel )

        -- We check if the user exited the new capsule page,
        -- in which case we should concidered they canceled.
        ( finalModel, cancelNewCapsCmd ) =
            case ( model.page, updatedModel.page, App.capsuleAndGos updatedModel.user updatedModel.page ) of
                ( _, App.NewCapsule _, _ ) ->
                    ( updatedModel, Cmd.none )

                ( App.NewCapsule m, _, ( c2, _ ) ) ->
                    case m.slideUpload of
                        RemoteData.Success ( c, _ ) ->
                            if Just c.id /= Maybe.map .id c2 then
                                ( { updatedModel
                                    | user = Data.deleteCapsule c updatedModel.user
                                  }
                                , Api.deleteCapsule c (\_ -> App.Noop)
                                )

                            else
                                ( updatedModel, Cmd.none )

                        _ ->
                            ( updatedModel, Cmd.none )

                _ ->
                    ( updatedModel, Cmd.none )

        -- Check if we need to change the before unload value
        clientTasksRemaining =
            model.config.clientState.tasks
                |> List.any (\x -> Config.isClientTask x && not x.finished)

        -- Check if some records where not uploaded
        unuploadedRecords =
            case model.page of
                App.Acquisition m ->
                    m.records |> List.any (\x -> not x.old)

                _ ->
                    False

        -- The command that updates the before unload value
        beforeUnloadCmd =
            onBeforeUnloadPort <| clientTasksRemaining || unuploadedRecords

        ( updatedModel, updatedCmd ) =
            case msg of
                App.Noop ->
                    ( model, Cmd.none )

                App.ConfigMsg sMsg ->
                    let
                        oldPreferredDevice =
                            model.config.clientConfig.preferredDevice

                        ( nextConfig, nextCmd ) =
                            Config.update sMsg model.config

                        ( newModel, newCmd ) =
                            if oldPreferredDevice /= nextConfig.clientConfig.preferredDevice then
                                -- We need to tell the acquisition page that the device changed
                                let
                                    ( tmpModel, tmpCmd ) =
                                        updateModel (App.AcquisitionMsg Acquisition.DeviceChanged) { model | config = nextConfig }
                                in
                                ( tmpModel, Cmd.batch [ tmpCmd, Cmd.map App.ConfigMsg nextCmd ] )

                            else
                                ( { model | config = nextConfig }, Cmd.map App.ConfigMsg nextCmd )
                    in
                    ( newModel, newCmd )

                App.HomeMsg sMsg ->
                    Home.update sMsg model

                App.NewCapsuleMsg sMsg ->
                    NewCapsule.update sMsg model

                App.PreparationMsg sMsg ->
                    Preparation.update sMsg model

                App.AcquisitionMsg aMsg ->
                    Acquisition.update aMsg model

                App.ProductionMsg pMsg ->
                    Production.update pMsg model

                App.PublicationMsg pMsg ->
                    Publication.update pMsg model

                App.OptionsMsg oMsg ->
                    Options.update oMsg model

                App.CollaborationMsg cMsg ->
                    Collaboration.update cMsg model

                App.ProfileMsg sMsg ->
                    Profile.update sMsg model

                App.WebSocketMsg (App.CapsuleUpdated c) ->
                    let
                        newPage =
                            case model.page of
                                App.Preparation m ->
                                    let
                                        newModel =
                                            Preparation.init c

                                        final =
                                            { newModel | popupType = m.popupType, displayPopup = m.displayPopup }
                                    in
                                    App.Preparation final

                                _ ->
                                    model.page
                    in
                    ( { model | user = Data.updateUser c model.user, page = newPage }, Cmd.none )

                App.WebSocketMsg (App.ProductionProgress id progress finished) ->
                    let
                        task : Config.TaskStatus
                        task =
                            { task = Config.Production -1 id
                            , progress = Just progress
                            , finished = finished
                            , aborted = False
                            , global = True
                            }

                        newConfig : Config.Config
                        newConfig =
                            Tuple.first <| Config.update (Config.UpdateTaskStatus task) model.config

                        capsule : Data.Capsule
                        capsule =
                            model.user.projects
                                |> List.concatMap .capsules
                                |> List.filter (\x -> x.id == id)
                                |> List.head
                                |> Maybe.withDefault Data.emptyCapsule

                        newModel : App.Model
                        newModel =
                            { model
                                | config = newConfig
                                , user =
                                    Data.updateUser
                                        { capsule
                                            | produced =
                                                Utils.tern
                                                    finished
                                                    Data.Done
                                                    (Data.Running (Just progress))
                                        }
                                        model.user
                            }
                    in
                    ( newModel, Cmd.none )

                App.WebSocketMsg (App.PublicationProgress id progress finished) ->
                    let
                        task : Config.TaskStatus
                        task =
                            { task = Config.Publication -1 id
                            , progress = Just progress
                            , finished = finished
                            , aborted = False
                            , global = True
                            }

                        newConfig : Config.Config
                        newConfig =
                            Tuple.first <| Config.update (Config.UpdateTaskStatus task) model.config

                        capsule : Data.Capsule
                        capsule =
                            model.user.projects
                                |> List.concatMap .capsules
                                |> List.filter (\x -> x.id == id)
                                |> List.head
                                |> Maybe.withDefault Data.emptyCapsule

                        newModel : App.Model
                        newModel =
                            { model
                                | config = newConfig
                                , user =
                                    Data.updateUser
                                        { capsule
                                            | published =
                                                Utils.tern
                                                    finished
                                                    Data.Done
                                                    (Data.Running (Just progress))
                                        }
                                        model.user
                            }
                    in
                    ( newModel, Cmd.none )

                App.WebSocketMsg (App.ExtraRecordProgress slideId capsuleId progress finished) ->
                    let
                        task : Config.TaskStatus
                        task =
                            { task = Config.TranscodeExtra -1 slideId capsuleId
                            , progress = Just progress
                            , finished = finished
                            , aborted = False
                            , global = True
                            }

                        newConfig : Config.Config
                        newConfig =
                            Tuple.first <| Config.update (Config.UpdateTaskStatus task) model.config

                        newModel : App.Model
                        newModel =
                            { model | config = newConfig }
                    in
                    ( newModel, Cmd.none )

                App.OnUrlChange url ->
                    let
                        route =
                            Route.fromUrl url

                        ( page, cmd ) =
                            App.pageFromRoute model.config model.user route
                    in
                    if route == App.routeFromPage model.page then
                        case model.page of
                            App.Acquisition m ->
                                -- This is ugly but I don't know how to do it otherwise.
                                -- When the user has non validated records, but try to leave the acquisition page, a
                                -- popup appears warning them. This is done when the route changes, so if they cancel,
                                -- we restore the previous route by using Nav.back. The page hasn't changed, so the page
                                -- is acquisition, and the model is acquisition. We can't just use the page from
                                -- App.pageFromRoute beacuse we would lose their records, but we still need to remove
                                -- the warning popup which is what we do here;
                                -- For a reason I don't understand, Nav.back prevents us from removing the popup from
                                -- within the Acquisition.Updates module...
                                ( { model | page = App.Acquisition { m | warnLeaving = Nothing } }, Cmd.none )

                            _ ->
                                ( model, Cmd.none )

                    else
                        ( { model | page = page }, cmd )

                App.InternalUrl url ->
                    case ( String.startsWith "/data/" url.path || String.startsWith "/o" url.path, model.config.clientState.key ) of
                        ( True, _ ) ->
                            ( model, Browser.Navigation.load url.path )

                        ( _, Just k ) ->
                            ( model, Browser.Navigation.pushUrl k url.path )

                        _ ->
                            ( model, Cmd.none )

                App.ExternalUrl url ->
                    ( model, Browser.Navigation.load url )

                App.Logout ->
                    ( model, Api.logout App.LoggedOut )

                App.LoggedOut ->
                    ( model
                    , Browser.Navigation.load (Maybe.withDefault model.config.serverConfig.root model.config.serverConfig.home)
                    )

                App.CopyString string ->
                    ( model, copyStringPort string )
    in
    ( if leavingAcquisitionWithRecord then
        leavingModel

      else
        finalModel
    , Cmd.batch
        [ updatedCmd
        , stopSoundtrackCmd
        , cancelNewCapsCmd
        , unbindDevice
        , beforeUnloadCmd
        , clearPointerAndCallbacksCmd
        ]
    )


{-| Returns the subscriptions of the app.
-}
subs : App.MaybeModel -> Sub App.MaybeMsg
subs m =
    case m of
        App.Logged model ->
            Sub.batch
                [ Sub.map App.ConfigMsg (Config.subs model.config)
                , webSocketMsg <|
                    \x ->
                        case Decode.decodeValue webSocketMsgDecoder x of
                            Ok a ->
                                App.WebSocketMsg <| a

                            _ ->
                                App.Noop
                , let
                    ( maybeCapsule, maybeGos ) =
                        App.capsuleAndGos model.user model.page
                  in
                  case ( model.page, maybeCapsule, maybeGos ) of
                    ( App.Home _, _, _ ) ->
                        Home.subs

                    ( App.NewCapsule _, _, _ ) ->
                        Sub.none

                    ( App.Preparation x, _, _ ) ->
                        Preparation.subs x

                    ( App.Acquisition x, _, _ ) ->
                        Acquisition.subs x

                    ( App.Production x, Just capsule, Just gos ) ->
                        Production.subs <| Production.withCapsuleAndGos capsule gos x

                    ( App.Publication _, _, _ ) ->
                        Sub.none

                    ( App.Options _, _, _ ) ->
                        Options.subs

                    ( App.Profile _, _, _ ) ->
                        Profile.subs

                    _ ->
                        Sub.none
                ]
                |> Sub.map App.LoggedMsg

        App.Unlogged _ ->
            Unlogged.subs |> Sub.map App.UnloggedMsg

        _ ->
            Sub.none


{-| Function that decodes websocket messages.
-}
webSocketMsgDecoder : Decoder App.WebSocketMsg
webSocketMsgDecoder =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\x ->
                case x of
                    "capsule_changed" ->
                        Decode.map App.CapsuleUpdated Data.decodeCapsule

                    "capsule_production_progress" ->
                        Decode.map2 (\y z -> App.ProductionProgress y z False)
                            (Decode.field "id" Decode.string)
                            (Decode.field "msg" Decode.float)

                    "capsule_production_finished" ->
                        Decode.map (\p -> App.ProductionProgress p 1.0 True)
                            (Decode.field "id" Decode.string)

                    "capsule_publication_finished" ->
                        Decode.map (\p -> App.PublicationProgress p 1.0 True)
                            (Decode.field "id" Decode.string)

                    "video_upload_progress" ->
                        Decode.map3 (\y z t -> App.ExtraRecordProgress y z t False)
                            (Decode.field "slide_id" Decode.string)
                            (Decode.field "capsule_id" Decode.string)
                            (Decode.field "msg" Decode.float)

                    "video_upload_finished" ->
                        Decode.map2 (\p q -> App.ExtraRecordProgress p q 1.0 True)
                            (Decode.field "slide_id" Decode.string)
                            (Decode.field "capsule_id" Decode.string)

                    _ ->
                        Decode.fail <| "Unknown websocket msg type " ++ x
            )


{-| Port to received messages via web sockets.
-}
port webSocketMsg : (Decode.Value -> msg) -> Sub msg


{-| Port to set the on before unload value.
-}
port onBeforeUnloadPort : Bool -> Cmd msg


{-| Port to set the clear flag to true (clear pointer and callbacks).
-}
port clearPointerAndCallbacksPort : () -> Cmd msg


{-| Copies a string to the clipboard.
-}
port copyStringPort : String -> Cmd msg
