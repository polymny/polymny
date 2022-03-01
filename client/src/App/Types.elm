module App.Types exposing
    ( Model, Page(..), init, Msg(..)
    , Error, errorToString
    )

{-| This module contains the model and messages of our application.


# The model

@docs Model, Page, init, Msg


# Error management

@docs Error, errorToString

-}

import Browser.Navigation
import Config exposing (Config)
import Data.User as Data exposing (User)
import Home.Types as Home
import Json.Decode as Decode
import Url exposing (Url)


{-| This type contains all the model of the application.
-}
type alias Model =
    { config : Config
    , page : Page
    , user : User
    }


{-| This type represents the different pages on which a user can be on the application.
-}
type Page
    = Home


{-| This type represents the errors that can occur when the page starts.
-}
type Error
    = DecodeError Decode.Error


{-| Convers the error to a string.
-}
errorToString : Error -> String
errorToString error =
    case error of
        DecodeError e ->
            "Error decoding JSON: " ++ Decode.errorToString e


{-| Initializes the model for the application
-}
init : Decode.Value -> Url -> Browser.Navigation.Key -> ( Result Error Model, Cmd Msg )
init flags url key =
    let
        serverConfig =
            Decode.decodeValue (Decode.field "global" (Decode.field "serverConfig" Config.decodeServerConfig)) flags

        clientConfig =
            Decode.decodeValue (Decode.field "global" (Decode.field "clientConfig" Config.decodeClientConfig)) flags

        clientState =
            Config.initClientState key (clientConfig |> Result.toMaybe |> Maybe.andThen .lang)

        sortBy =
            clientConfig |> Result.map .sortBy |> Result.withDefault Config.defaultClientConfig.sortBy

        user =
            Decode.decodeValue (Decode.field "user" (Data.decodeUser sortBy)) flags

        model =
            case ( serverConfig, clientConfig, user ) of
                ( Ok s, Ok c, Ok u ) ->
                    Ok { config = { serverConfig = s, clientConfig = c, clientState = clientState }, user = u, page = Home }

                ( Err s, _, _ ) ->
                    Err (DecodeError s)

                ( _, Err c, _ ) ->
                    Err (DecodeError c)

                ( _, _, Err u ) ->
                    Err (DecodeError u)
    in
    ( model, Cmd.none )


{-| This type represents the different messages that can be sent in the application.
-}
type Msg
    = Noop
    | HomeMsg Home.Msg
    | ConfigMsg Config.Msg
