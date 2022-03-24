port module Config exposing
    ( Config, incrementRequest
    , ServerConfig, decodeServerConfig
    , ClientConfig, defaultClientConfig, encodeClientConfig, decodeClientConfig
    , ClientState, initClientState
    , Msg(..)
    , update
    , saveStorage
    )

{-| This module contains the core types for Polymny app.

It defines the [`Config`](#Config) type which contain a lot of information that can be useful and that will be available
at all times in the client.

@docs Config, incrementRequest


# Server configuration

@docs ServerConfig, decodeServerConfig


# Client configuration

@docs ClientConfig, defaultClientConfig, encodeClientConfig, decodeClientConfig


# Client state

@docs ClientState, initClientState


# Messages

@docs Msg


# Updates

@docs update


# Ports

@docs saveStorage

-}

import Browser.Navigation
import Data.Types as Data
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Lang exposing (Lang)
import Time


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

-}
type alias ServerConfig =
    { root : String
    , socketRoot : String
    , videoRoot : String
    , version : String
    , commit : Maybe String
    , home : Maybe String
    , registrationDisabled : Bool
    }


{-| JSON decoder for [`ServerConfig`](#ServerConfig).
-}
decodeServerConfig : Decoder ServerConfig
decodeServerConfig =
    Decode.map7 ServerConfig
        (Decode.field "root" Decode.string)
        (Decode.field "socketRoot" Decode.string)
        (Decode.field "videoRoot" Decode.string)
        (Decode.field "version" Decode.string)
        (Decode.maybe (Decode.field "commit" Decode.string))
        (Decode.maybe (Decode.field "home" Decode.string))
        (Decode.field "registrationDisabled" Decode.bool)


{-| This type holds the settings of the client.

This will be stored and retrieved from the local storage.

  - `lang` is the lang that has been set by the user. If it hasn't been set, we will use the browser or the default one.
  - `zoomLevel` represents the number of slides to put on the same line in the preparation tab.
  - `acquisitionInverted` at true means that the prompter should be on the bottom of the screen and the slide on the top
    during acquisition (useful for people who have their webcams below their screen).
  - `promptSize` is the size in pt of the text inside the prompter.
  - `sortBy` describes how the user wants to sort their capsules.

-}
type alias ClientConfig =
    { lang : Maybe Lang
    , zoomLevel : Int
    , promptSize : Int
    , sortBy : Data.SortBy
    }


{-| Default values for [`ClientConfig`](#ClientConfig).
-}
defaultClientConfig : ClientConfig
defaultClientConfig =
    { lang = Nothing
    , zoomLevel = 4
    , promptSize = 20
    , sortBy = { key = Data.LastModified, ascending = False }
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
    Decode.map4 ClientConfig
        (Decode.field "lang" Decode.string |> Decode.map Lang.fromString |> makeDefault defaultClientConfig.lang)
        (Decode.field "zoomLevel" Decode.int |> makeDefault defaultClientConfig.zoomLevel)
        (Decode.field "promptSize" Decode.int |> makeDefault defaultClientConfig.promptSize)
        (Decode.field "sortBy" Data.decodeSortBy |> makeDefault defaultClientConfig.sortBy)


{-| This type holds the client global state.

It is not in the client config since it cannot be persisted, and is recreated with each new client.

  - `zone` is the time zone of the users. It is required to display dates and times.
  - `key` is the [`Browser.Navigation.Key`](/packages/elm/browser/1.0.2/Browser-Navigation#Key). It contains the
    history, and allows us to change the URL or to do certain specific actions, like previous page or next page.
  - `lang` is the lang that will be used to display text. If the `lang` in the [`ClientConfig`](#ClientConfig) is set,
    this will mimic it, but otherwise, it will give a lang chosen either by requesting info from the browser or a
    default lang.
  - `lastRequest` is the number of the last request sent. It allows us to ignore responses to old requests.

-}
type alias ClientState =
    { zone : Time.Zone
    , key : Browser.Navigation.Key
    , lang : Lang
    , lastRequest : Int
    }


{-| Initializes a client state.
-}
initClientState : Browser.Navigation.Key -> Maybe Lang -> ClientState
initClientState key lang =
    { key = key
    , zone = Time.utc
    , lang = Maybe.withDefault Lang.default lang
    , lastRequest = 0
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


{-| This type contains all the messages that trigger a modification of the config.
-}
type Msg
    = ZoneChanged Time.Zone
    | LangChanged Lang
    | ZoomLevelChanged Int
    | PromptSizeChanged Int
    | SortByChanged Data.SortBy


{-| This functions updates the config.

It also sends a command to save the part of the config that requires saving.

-}
update : Msg -> Config -> ( Config, Cmd msg )
update msg { serverConfig, clientConfig, clientState } =
    let
        ( newConfig, saveRequired ) =
            case msg of
                ZoneChanged zone ->
                    ( { serverConfig = serverConfig
                      , clientConfig = clientConfig
                      , clientState = { clientState | zone = zone }
                      }
                    , False
                    )

                LangChanged lang ->
                    ( { serverConfig = serverConfig
                      , clientConfig = { clientConfig | lang = Just lang }
                      , clientState = { clientState | lang = lang }
                      }
                    , True
                    )

                ZoomLevelChanged zoomLevel ->
                    ( { serverConfig = serverConfig
                      , clientConfig = { clientConfig | zoomLevel = zoomLevel }
                      , clientState = clientState
                      }
                    , True
                    )

                PromptSizeChanged promptSize ->
                    ( { serverConfig = serverConfig
                      , clientConfig = { clientConfig | promptSize = promptSize }
                      , clientState = clientState
                      }
                    , True
                    )

                SortByChanged sortBy ->
                    ( { serverConfig = serverConfig
                      , clientConfig = { clientConfig | sortBy = sortBy }
                      , clientState = clientState
                      }
                    , True
                    )

        saveCmd =
            if saveRequired then
                saveStorage newConfig.clientConfig

            else
                Cmd.none
    in
    ( newConfig, saveCmd )


{-| Port that sends the client config to javascript for saving in localstorage.
-}
saveStorage : ClientConfig -> Cmd msg
saveStorage clientConfig =
    saveStoragePort (encodeClientConfig clientConfig)


{-| Port that sends the client config to javascript for saving in localstorage.
-}
port saveStoragePort : Encode.Value -> Cmd msg
