port module Config exposing
    ( Config, incrementRequest, addTask, incrementTaskId
    , ServerConfig, decodeServerConfig
    , ClientConfig, defaultClientConfig, encodeClientConfig, decodeClientConfig
    , ClientState, initClientState, Task(..), TaskStatus
    , Msg(..)
    , update, subs
    , saveStorage
    , PopupType(..), TaskId, decodeTaskStatus, isClientTask, isServerTask, taskProgress
    )

{-| This module contains the core types for Polymny app.

It defines the [`Config`](#Config) type which contain a lot of information that can be useful and that will be available
at all times in the client.

@docs Config, incrementRequest, addTask, incrementTaskId


# Server configuration

@docs ServerConfig, decodeServerConfig


# Client configuration

@docs ClientConfig, defaultClientConfig, encodeClientConfig, decodeClientConfig


# Client state

@docs ClientState, initClientState, Task, TaskStatus


# Messages

@docs Msg


# Updates

@docs update, subs


# Ports

@docs saveStorage

-}

import Browser.Dom as Dom
import Browser.Navigation
import Data.Types as Data
import Device
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Lang exposing (Lang)
import Task
import Time
import Utils


{-| This type stores the settings from the server, such as various URL and options that are enabled or disabled on the
server.

They are useful because the UI must reflect these settings.

  - `root` is the full URL of the root of the application server, e.g. `https://app.polymny.studio`.
  - `socketRoot` is the full URL of the root of the websocket server, e.g. `wss://ws.polymny.studio`.
  - `videoRoot` is the full URL of the root of the video streaming server, e.g. `https://polymny.studio/v`, or
    `https://app.polymny.studio/v`.
  - `version` is the string representing the version of the app, e.g. "1.0.0".
  - `commit` is the id of the commit on which the server is running. It can be helpful for debugging purposes, but the
    server might not send it.
  - `home` is the home page of the app. If the app is running at `https://app.polymny.studio`, a portal can be at
    `https://polymny.studio`.
  - `registrationDisabled` indicates whether the server allows new users to register.
  - `authMethods` is the list of authentication methods that you can use for Polymny Studio.

-}
type alias ServerConfig =
    { root : String
    , socketRoot : String
    , videoRoot : String
    , version : String
    , commit : Maybe String
    , home : Maybe String
    , registrationDisabled : Bool
    , authMethods : List AuthMethod
    }


{-| The different authentication methods supported by Polymny Studio.
-}
type AuthMethod
    = Local
    | OpenId OpenIdConfig


{-| An Open Id configuration.
-}
type alias OpenIdConfig =
    { root : String
    , client : String
    }


{-| Decodes an OpenID configuration.
-}
decodeOpenId : Decoder OpenIdConfig
decodeOpenId =
    Decode.map2 OpenIdConfig
        (Decode.field "root" Decode.string)
        (Decode.field "client" Decode.string)


{-| Decodes an authentication method.
-}
decodeAuthMethods : Decoder (List AuthMethod)
decodeAuthMethods =
    Decode.maybe (Decode.field "openid" decodeOpenId)
        |> Decode.map (Maybe.map OpenId)
        |> Decode.map (Maybe.withDefault Local)
        |> Decode.map (\x -> [ x ])


{-| JSON decoder for [`ServerConfig`](#ServerConfig).
-}
decodeServerConfig : Decoder ServerConfig
decodeServerConfig =
    Decode.map8 ServerConfig
        (Decode.field "root" Decode.string)
        (Decode.field "socketRoot" Decode.string)
        (Decode.field "videoRoot" Decode.string)
        (Decode.field "version" Decode.string)
        (Decode.maybe (Decode.field "commit" Decode.string))
        (Decode.maybe (Decode.field "home" Decode.string))
        (Decode.field "registrationDisabled" Decode.bool)
        decodeAuthMethods


{-| This type holds the settings of the client.

This will be stored and retrieved from the local storage.

  - `lang` is the lang that has been set by the user. If it hasn't been set, we will use the browser or the default one.
  - `zoomLevel` represents the number of slides to put on the same line in the preparation tab.
  - `acquisitionInverted` at true means that the prompter should be on the bottom of the screen and the slide on the top
    during acquisition (useful for people who have their webcams below their screen).
  - `promptSize` is the size in pt of the text inside the prompter.
  - `sortBy` describes how the user wants to sort their capsules.
  - `devices` are the devices that have been detected in a previous session a stored so that we don't have to detect
    them again. It does not mean that they're currently available (they could be unplugged).

-}
type alias ClientConfig =
    { lang : Maybe Lang
    , zoomLevel : Int
    , promptSize : Int
    , sortBy : Data.SortBy
    , devices : Device.Devices
    , preferredDevice : Maybe Device.Device
    }


{-| Default values for [`ClientConfig`](#ClientConfig).
-}
defaultClientConfig : ClientConfig
defaultClientConfig =
    { lang = Nothing
    , zoomLevel = 4
    , promptSize = 20
    , sortBy = { key = Data.LastModified, ascending = False }
    , devices = { audio = [], video = [] }
    , preferredDevice = Nothing
    }


{-| JSON encoder for [`ClientConfig`](#ClientConfig).
-}
encodeClientConfig : ClientConfig -> Encode.Value
encodeClientConfig config =
    Encode.object
        [ ( "lang", Maybe.map Encode.string (Maybe.map Lang.toString config.lang) |> Maybe.withDefault Encode.null )
        , ( "zoomLevel", Encode.int config.zoomLevel )
        , ( "promptSize", Encode.int config.promptSize )
        , ( "sortBy", Data.encodeSortBy config.sortBy )
        , ( "devices", Device.encodeDevices config.devices )
        , ( "preferredDevice", Maybe.map Device.encodeDevice config.preferredDevice |> Maybe.withDefault Encode.null )
        ]


{-| Gives a default value to a decoder
-}
makeDefault : a -> Decoder a -> Decoder a
makeDefault default arg =
    arg |> Decode.maybe |> Decode.map (Maybe.withDefault default)


{-| JSON decoder for [`ClientConfig`](#ClientConfig).
-}
decodeClientConfig : Decoder ClientConfig
decodeClientConfig =
    Decode.map6 ClientConfig
        (Decode.field "lang" Decode.string |> Decode.map Lang.fromString |> makeDefault defaultClientConfig.lang)
        (Decode.field "zoomLevel" Decode.int |> makeDefault defaultClientConfig.zoomLevel)
        (Decode.field "promptSize" Decode.int |> makeDefault defaultClientConfig.promptSize)
        (Decode.field "sortBy" Data.decodeSortBy |> makeDefault defaultClientConfig.sortBy)
        (Decode.field "devices" Device.decodeDevices |> makeDefault defaultClientConfig.devices)
        (Decode.maybe (Decode.field "preferredDevice" Device.decodeDevice))


{-| This type holds the client global state.

It is not in the client config since it cannot be persisted, and is recreated with each new client.

  - `zone` is the time zone of the users. It is required to display dates and times.
  - `key` is the [`Browser.Navigation.Key`](/packages/elm/browser/1.0.2/Browser-Navigation#Key). It contains the
    history, and allows us to change the URL or to do certain specific actions, like previous page or next page.
  - `lang` is the lang that will be used to display text. If the `lang` in the [`ClientConfig`](#ClientConfig) is set,
    this will mimic it, but otherwise, it will give a lang chosen either by requesting info from the browser or a
    default lang.
  - `lastRequest` is the number of the last request sent. It allows us to ignore responses to old requests.
  - `tasks` is the list of tasks being run by the client.
  - `showLangPicker` is a bool that tells us whether we should show the lang picker or not.
  - `showNotificationPanel` is a bool that tells us whether we should show the notification panel or not.
  - `showTaskPanel` is a bool that tells if the task panel is visible on the client
  - `taskId` is a integer that represents the id of the next task to spawn, it must be incremented when a new task is
    addeda.
  - `webSocketStatus` is a bool that tells if the web socket is correctly connected or not.

-}
type alias ClientState =
    { zone : Time.Zone
    , time : Time.Posix
    , key : Maybe Browser.Navigation.Key
    , lang : Lang
    , lastRequest : Int
    , tasks : List TaskStatus
    , showTaskPanel : Bool
    , taskId : TaskId
    , webSocketStatus : Bool
    , popupType : PopupType
    }


type PopupType
    = NoPopup
    | LangPicker
    | WebSocketInfo


{-| Task id
-}
type alias TaskId =
    Int


{-| All the task that the user can see.
-}
type Task
    = UploadRecord TaskId String Int Decode.Value
    | UploadTrack TaskId String
    | AddSlide TaskId String
    | AddGos TaskId String
    | ReplaceSlide TaskId String
    | Production TaskId String
    | Publication TaskId String
    | ExportCapsule TaskId String
    | ImportCapsule TaskId
    | TranscodeExtra TaskId String String


{-| Returns true if the task is a client task.
-}
isClientTask : TaskStatus -> Bool
isClientTask task =
    case task.task of
        UploadRecord _ _ _ _ ->
            True

        UploadTrack _ _ ->
            True

        AddSlide _ _ ->
            True

        AddGos _ _ ->
            True

        ReplaceSlide _ _ ->
            True

        ExportCapsule _ _ ->
            True

        ImportCapsule _ ->
            True

        _ ->
            False


{-| Returns true if the task is a server task.
-}
isServerTask : TaskStatus -> Bool
isServerTask task =
    not (isClientTask task)


{-| Decodes a task id.
-}
decodeTaskId : Decoder TaskId
decodeTaskId =
    Decode.int


{-| Decodes a task.
-}
decodeTask : Decoder Task
decodeTask =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\x ->
                case x of
                    "UploadRecord" ->
                        Decode.map4 UploadRecord
                            (Decode.field "taskId" decodeTaskId)
                            (Decode.field "capsuleId" Decode.string)
                            (Decode.field "gos" Decode.int)
                            (Decode.field "value" Decode.value)

                    "UploadTrack" ->
                        Decode.map2 UploadTrack
                            (Decode.field "taskId" decodeTaskId)
                            (Decode.field "capsuleId" Decode.string)

                    "AddSlide" ->
                        Decode.map2 AddSlide
                            (Decode.field "taskId" decodeTaskId)
                            (Decode.field "capsuleId" Decode.string)

                    "AddGos" ->
                        Decode.map2 AddGos
                            (Decode.field "taskId" decodeTaskId)
                            (Decode.field "capsuleId" Decode.string)

                    "ReplaceSlide" ->
                        Decode.map2 ReplaceSlide
                            (Decode.field "taskId" decodeTaskId)
                            (Decode.field "capsuleId" Decode.string)

                    "Production" ->
                        Decode.map2 Production
                            (Decode.field "taskId" decodeTaskId)
                            (Decode.field "capsuleId" Decode.string)

                    "ExportCapsule" ->
                        Decode.map2 ExportCapsule
                            (Decode.field "taskId" decodeTaskId)
                            (Decode.field "capsuleId" Decode.string)

                    "ImportCapsule" ->
                        Decode.map ImportCapsule
                            (Decode.field "taskId" decodeTaskId)

                    _ ->
                        Decode.fail <| "type " ++ x ++ " not recognized as task type"
            )


{-| The status of a task, containing the task and its progress if available.
-}
type alias TaskStatus =
    { task : Task
    , progress : Maybe Float
    , finished : Bool
    , aborted : Bool
    , global : Bool
    }


{-| Decodes a task status.
-}
decodeTaskStatus : Decoder TaskStatus
decodeTaskStatus =
    Decode.map5 TaskStatus
        (Decode.field "task" decodeTask)
        (Decode.maybe (Decode.field "progress" Decode.float))
        (Decode.field "finished" Decode.bool)
        (Decode.field "aborted" Decode.bool)
        (Decode.map (Maybe.withDefault True) <| Decode.maybe <| Decode.field "global" Decode.bool)


{-| Initializes a client state.
-}
initClientState : Maybe Browser.Navigation.Key -> Maybe Lang -> ClientState
initClientState key lang =
    { key = key
    , zone = Time.utc
    , time = Time.millisToPosix 0
    , lang = Maybe.withDefault Lang.default lang
    , lastRequest = 0
    , tasks = []
    , popupType = NoPopup
    , showTaskPanel = False
    , taskId = 0
    , webSocketStatus = False
    }


{-| This type aggregates [`ServerConfig`](#ServerConfig), [`ClientConfig`](#ClientConfig) and
[`ClientState`](#ClientState) into a type that will be available at all times.
-}
type alias Config =
    { serverConfig : ServerConfig
    , clientConfig : ClientConfig
    , clientState : ClientState
    }


{-| Increments the lastRequest of the clientState easily.
-}
incrementRequest : Config -> Config
incrementRequest config =
    let
        clientState =
            config.clientState

        newClientState =
            { clientState | lastRequest = clientState.lastRequest + 1 }
    in
    { config | clientState = newClientState }


{-| Adds an task to the config.
-}
addTask : TaskStatus -> Config -> Config
addTask task { serverConfig, clientConfig, clientState } =
    { serverConfig = serverConfig
    , clientConfig = clientConfig
    , clientState = { clientState | tasks = task :: clientState.tasks }
    }


{-| Returns true if the tasks correspond to the same task.
-}
compareTasks : Task -> Task -> Bool
compareTasks t1 t2 =
    case ( t1, t2 ) of
        ( UploadRecord id1 _ _ _, UploadRecord id2 _ _ _ ) ->
            id1 == id2

        ( UploadTrack id1 capsuleId1, UploadTrack id2 capsuleId2 ) ->
            if id1 < 0 || id2 < 0 then
                capsuleId1 == capsuleId2

            else
                id1 == id2

        ( AddSlide id1 _, AddSlide id2 _ ) ->
            id1 == id2

        ( AddGos id1 _, AddGos id2 _ ) ->
            id1 == id2

        ( ReplaceSlide id1 _, ReplaceSlide id2 _ ) ->
            id1 == id2

        ( Production id1 capsuleId1, Production id2 capsuleId2 ) ->
            if id1 < 0 || id2 < 0 then
                capsuleId1 == capsuleId2

            else
                id1 == id2

        ( Publication id1 capsuleId1, Publication id2 capsuleId2 ) ->
            if id1 < 0 || id2 < 0 then
                capsuleId1 == capsuleId2

            else
                id1 == id2

        ( TranscodeExtra id1 slideId1 capsuleId1, TranscodeExtra id2 slideId2 capsuleId2 ) ->
            if id1 < 0 || id2 < 0 then
                slideId1 == slideId2 && capsuleId1 == capsuleId2

            else
                id1 == id2

        ( ExportCapsule id1 _, ExportCapsule id2 _ ) ->
            id1 == id2

        ( ImportCapsule id1, ImportCapsule id2 ) ->
            id1 == id2

        _ ->
            False


{-| This type contains all the messages that trigger a modification of the config.
-}
type Msg
    = Noop
    | Time Time.Posix
    | ZoneChanged Time.Zone
    | LangChanged Lang
    | ZoomLevelChanged Int
    | PromptSizeChanged Int
    | SortByChanged Data.SortBy
    | DetectDevicesResponse Device.Devices (Maybe Device.Device)
    | SetAudio Device.Audio
    | SetVideo (Maybe ( Device.Video, Device.Resolution ))
    | ReinitializeDevices
    | UpdateTaskStatus TaskStatus
    | ToggleLangPicker
    | ToggleWebSocketInfo
    | ToggleTaskPanel
    | FocusResult (Result Dom.Error ())
    | DisableTaskPanel
    | RemoveTask Task
    | AbortTask Task
    | ScrollToGos Float String
    | WebSocketStatus Bool


{-| This functions updates the config.

It also sends a command to save the part of the config that requires saving.

-}
update : Msg -> Config -> ( Config, Cmd Msg )
update msg { serverConfig, clientConfig, clientState } =
    let
        ( newConfig, saveRequired, extraCmd ) =
            case msg of
                Noop ->
                    ( { serverConfig = serverConfig
                      , clientConfig = clientConfig
                      , clientState = clientState
                      }
                    , False
                    , []
                    )

                Time time ->
                    ( { serverConfig = serverConfig
                      , clientConfig = clientConfig
                      , clientState = { clientState | time = time }
                      }
                    , False
                    , []
                    )

                ZoneChanged zone ->
                    ( { serverConfig = serverConfig
                      , clientConfig = clientConfig
                      , clientState = { clientState | zone = zone }
                      }
                    , False
                    , []
                    )

                LangChanged lang ->
                    ( { serverConfig = serverConfig
                      , clientConfig = { clientConfig | lang = Just lang }
                      , clientState = { clientState | lang = lang }
                      }
                    , True
                    , []
                    )

                ZoomLevelChanged zoomLevel ->
                    ( { serverConfig = serverConfig
                      , clientConfig = { clientConfig | zoomLevel = zoomLevel }
                      , clientState = clientState
                      }
                    , True
                    , []
                    )

                PromptSizeChanged promptSize ->
                    ( { serverConfig = serverConfig
                      , clientConfig = { clientConfig | promptSize = promptSize }
                      , clientState = clientState
                      }
                    , True
                    , []
                    )

                SortByChanged sortBy ->
                    ( { serverConfig = serverConfig
                      , clientConfig = { clientConfig | sortBy = sortBy }
                      , clientState = clientState
                      }
                    , True
                    , []
                    )

                DetectDevicesResponse devices preferredDevice ->
                    let
                        currentPreferredDevice =
                            Device.getDevice newDevices clientConfig.preferredDevice

                        newDevices =
                            Device.mergeDevices clientConfig.devices devices

                        newPreferredDevice =
                            preferredDevice
                                |> Maybe.withDefault currentPreferredDevice
                                |> (\x ->
                                        { x
                                            | audio =
                                                case x.audio of
                                                    Nothing ->
                                                        currentPreferredDevice.audio

                                                    Just y ->
                                                        Just y
                                        }
                                   )
                    in
                    ( { serverConfig = serverConfig
                      , clientConfig = { clientConfig | devices = newDevices, preferredDevice = Just newPreferredDevice }
                      , clientState = clientState
                      }
                    , True
                    , []
                    )

                SetAudio audio ->
                    let
                        preferredDevice =
                            clientConfig.preferredDevice
                                |> Maybe.map (\device -> { device | audio = Just audio })
                                |> Maybe.withDefault { audio = Just audio, video = Nothing }
                                |> Just
                    in
                    ( { serverConfig = serverConfig
                      , clientConfig = { clientConfig | preferredDevice = preferredDevice }
                      , clientState = clientState
                      }
                    , True
                    , []
                    )

                SetVideo video ->
                    let
                        preferredDevice =
                            clientConfig.preferredDevice
                                |> Maybe.map (\device -> { device | video = video })
                                |> Maybe.withDefault { audio = Nothing, video = video }
                                |> Just
                    in
                    ( { serverConfig = serverConfig
                      , clientConfig = { clientConfig | preferredDevice = preferredDevice }
                      , clientState = clientState
                      }
                    , True
                    , []
                    )

                ReinitializeDevices ->
                    ( { clientConfig =
                            { clientConfig
                                | devices = { audio = [], video = [] }
                                , preferredDevice = Nothing
                            }
                      , serverConfig = serverConfig
                      , clientState = clientState
                      }
                      -- The port will clear the cache itself
                    , False
                    , [ Device.detectDevices Nothing True ]
                    )

                UpdateTaskStatus task ->
                    let
                        updateTask : TaskStatus -> TaskStatus -> ( TaskStatus, Bool )
                        updateTask t input =
                            if compareTasks t.task input.task then
                                ( t, True )

                            else
                                ( input, False )

                        updatedTasks : List ( TaskStatus, Bool )
                        updatedTasks =
                            List.map (updateTask task) clientState.tasks

                        taskUpdated : Bool
                        taskUpdated =
                            List.any Tuple.second updatedTasks

                        newTasks : List TaskStatus
                        newTasks =
                            if taskUpdated then
                                List.map Tuple.first updatedTasks

                            else
                                { task | global = not task.finished } :: List.map (\t -> { t | global = not t.finished }) clientState.tasks
                    in
                    ( { serverConfig = serverConfig
                      , clientConfig = clientConfig
                      , clientState = { clientState | tasks = newTasks }
                      }
                    , False
                    , []
                    )

                ToggleLangPicker ->
                    ( { serverConfig = serverConfig
                      , clientConfig = clientConfig
                      , clientState =
                            { clientState
                                | popupType =
                                    Utils.tern (clientState.popupType == LangPicker) NoPopup LangPicker
                            }
                      }
                    , False
                    , []
                    )

                ToggleWebSocketInfo ->
                    ( { serverConfig = serverConfig
                      , clientConfig = clientConfig
                      , clientState =
                            { clientState
                                | popupType =
                                    Utils.tern (clientState.popupType == WebSocketInfo) NoPopup WebSocketInfo
                            }
                      }
                    , False
                    , []
                    )

                ToggleTaskPanel ->
                    let
                        showTaskPanel : Bool
                        showTaskPanel =
                            not clientState.showTaskPanel

                        focusCmd : List (Cmd Msg)
                        focusCmd =
                            if showTaskPanel then
                                [ Dom.focus "task-panel" |> Task.attempt FocusResult
                                , addBlurHandlerPort "task-panel"
                                ]

                            else
                                []
                    in
                    ( { serverConfig = serverConfig
                      , clientConfig = clientConfig
                      , clientState = { clientState | showTaskPanel = showTaskPanel }
                      }
                    , False
                    , focusCmd
                    )

                FocusResult _ ->
                    -- case result of
                    --     Err (Dom.NotFound id) ->
                    --         -- unable to find dom 'id'
                    --     Ok () ->
                    --         -- successfully focus the dom
                    ( { serverConfig = serverConfig
                      , clientConfig = clientConfig
                      , clientState = clientState
                      }
                    , False
                    , []
                    )

                DisableTaskPanel ->
                    ( { serverConfig = serverConfig
                      , clientConfig = clientConfig
                      , clientState = { clientState | showTaskPanel = False }
                      }
                    , False
                    , []
                    )

                AbortTask task ->
                    let
                        tracker : String
                        tracker =
                            case task of
                                UploadRecord taskId _ _ _ ->
                                    "task-track-" ++ String.fromInt taskId

                                UploadTrack taskId capsuleId ->
                                    let
                                        realTaskId : TaskId
                                        realTaskId =
                                            List.filterMap
                                                (\t ->
                                                    if compareTasks t.task task then
                                                        case t.task of
                                                            UploadTrack id _ ->
                                                                Just id

                                                            _ ->
                                                                Nothing

                                                    else
                                                        Nothing
                                                )
                                                clientState.tasks
                                                |> List.head
                                                |> Maybe.withDefault 0
                                    in
                                    "task-track-" ++ String.fromInt realTaskId

                                AddSlide taskId _ ->
                                    "task-track-" ++ String.fromInt taskId

                                AddGos taskId _ ->
                                    "task-track-" ++ String.fromInt taskId

                                ReplaceSlide taskId _ ->
                                    "task-track-" ++ String.fromInt taskId

                                ExportCapsule taskId _ ->
                                    "task-track-" ++ String.fromInt taskId

                                ImportCapsule taskId ->
                                    "task-track-" ++ String.fromInt taskId

                                _ ->
                                    ""

                        abortCmd : Cmd msg
                        abortCmd =
                            case task of
                                UploadRecord _ _ _ _ ->
                                    abortTaskPort tracker

                                UploadTrack _ _ ->
                                    Http.cancel tracker

                                AddSlide _ _ ->
                                    Http.cancel tracker

                                AddGos _ _ ->
                                    Http.cancel tracker

                                ReplaceSlide _ _ ->
                                    Http.cancel tracker

                                ExportCapsule _ _ ->
                                    abortTaskPort tracker

                                ImportCapsule _ ->
                                    abortTaskPort tracker

                                _ ->
                                    Cmd.none

                        newTaskStatus : TaskStatus
                        newTaskStatus =
                            { task = task
                            , progress = Just 1.0
                            , finished = True
                            , aborted = True
                            , global = True
                            }

                        newTasks : List TaskStatus
                        newTasks =
                            List.map
                                (\t ->
                                    if compareTasks t.task task then
                                        newTaskStatus

                                    else
                                        t
                                )
                                clientState.tasks
                    in
                    ( { serverConfig = serverConfig
                      , clientConfig = clientConfig
                      , clientState = { clientState | tasks = newTasks }
                      }
                    , False
                    , [ abortCmd ]
                    )

                RemoveTask task ->
                    let
                        newTasks : List TaskStatus
                        newTasks =
                            List.filter (\t -> not (compareTasks t.task task)) clientState.tasks
                    in
                    ( { serverConfig = serverConfig
                      , clientConfig = clientConfig
                      , clientState = { clientState | tasks = newTasks }
                      }
                    , False
                    , []
                    )

                ScrollToGos scrollVal elementId ->
                    ( { serverConfig = serverConfig
                      , clientConfig = clientConfig
                      , clientState = clientState
                      }
                    , False
                    , [ scrollIntoViewPort ( scrollVal, elementId ) ]
                    )

                WebSocketStatus b ->
                    ( { serverConfig = serverConfig
                      , clientConfig = clientConfig
                      , clientState = { clientState | webSocketStatus = b }
                      }
                    , False
                    , []
                    )

        saveCmd : List (Cmd Msg)
        saveCmd =
            if saveRequired then
                [ saveStorage newConfig.clientConfig ]

            else
                []

        cmd : Cmd Msg
        cmd =
            Cmd.batch <| saveCmd ++ extraCmd
    in
    ( newConfig, cmd )


{-| The subscriptions for the config.
-}
subs : Config -> Sub Msg
subs config =
    Sub.batch
        (Time.every 500 Time
            :: webSocketStatus WebSocketStatus
            :: Device.detectDevicesResponse
                (\x ->
                    case Decode.decodeValue Device.decodeDevicesAndPreferredDevice x of
                        Ok ( devices, preferredDevice ) ->
                            DetectDevicesResponse devices preferredDevice

                        _ ->
                            Noop
                )
            :: taskProgress
                (\x ->
                    case Decode.decodeValue decodeTaskStatus x of
                        Ok task ->
                            UpdateTaskStatus task

                        _ ->
                            Noop
                )
            :: panelBlur
                (\x ->
                    case Decode.decodeValue Decode.string x of
                        Ok "task-panel" ->
                            DisableTaskPanel

                        _ ->
                            Noop
                )
            :: (config.clientState.tasks
                    |> List.filterMap
                        (\x ->
                            case x.task of
                                UploadRecord taskId _ _ _ ->
                                    Just ( taskId, x.task )

                                UploadTrack taskId _ ->
                                    Just ( taskId, x.task )

                                AddSlide taskId _ ->
                                    Just ( taskId, x.task )

                                AddGos taskId _ ->
                                    Just ( taskId, x.task )

                                ReplaceSlide taskId _ ->
                                    Just ( taskId, x.task )

                                _ ->
                                    Nothing
                        )
                    |> List.map
                        (\( taskId, task ) ->
                            Http.track ("task-track-" ++ String.fromInt taskId)
                                (\progress ->
                                    case progress of
                                        Http.Sending { sent, size } ->
                                            let
                                                progressValue : Float
                                                progressValue =
                                                    if size == 0 then
                                                        0

                                                    else
                                                        toFloat sent / toFloat size

                                                finished : Bool
                                                finished =
                                                    progressValue == 1
                                            in
                                            UpdateTaskStatus
                                                { task = task
                                                , finished = finished
                                                , progress = Just progressValue
                                                , aborted = False
                                                , global = True
                                                }

                                        _ ->
                                            Noop
                                )
                        )
               )
        )


{-| Increment task id.
-}
incrementTaskId : Config -> Config
incrementTaskId config =
    let
        clientState : ClientState
        clientState =
            config.clientState
    in
    { config
        | clientState =
            { clientState
                | taskId = config.clientState.taskId + 1
            }
    }


{-| Port that sends the client config to javascript for saving in localstorage.
-}
saveStorage : ClientConfig -> Cmd msg
saveStorage clientConfig =
    saveStoragePort (encodeClientConfig clientConfig)


{-| Port that sends the client config to javascript for saving in localstorage.
-}
port saveStoragePort : Encode.Value -> Cmd msg


{-| Subscription that received progress on tasks.
-}
port taskProgress : (Encode.Value -> msg) -> Sub msg


{-| Add blur handler to the panel.
-}
port addBlurHandlerPort : String -> Cmd msg


{-| Blured panel.
-}
port panelBlur : (Encode.Value -> msg) -> Sub msg


{-| Remove a task.
-}
port abortTaskPort : String -> Cmd msg


{-| Scroll to a gos.
-}
port scrollIntoViewPort : ( Float, String ) -> Cmd msg


{-| A change in the status of web socket.
-}
port webSocketStatus : (Bool -> msg) -> Sub msg
