module App.Utils exposing (init, pageFromRoute)

{-| This module contains some util functions that should really be in App/Types.elm but that can't be there because elm
doesn't allow circular module imports...

@docs init, pageFromRoute

-}

import App.Types as App
import Browser.Navigation
import Config exposing (Config)
import Data.User as Data exposing (User)
import Home.Types as Home
import Json.Decode as Decode
import NewCapsule.Types as NewCapsule
import Preparation.Types as Preparation
import Route exposing (Route)
import Url exposing (Url)


{-| Initializes the model for the application
-}
init : Decode.Value -> Url -> Browser.Navigation.Key -> ( Result App.Error App.Model, Cmd App.Msg )
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

        route =
            Route.fromUrl url

        model =
            case ( serverConfig, clientConfig, user ) of
                ( Ok s, Ok c, Ok u ) ->
                    Ok
                        { config = { serverConfig = s, clientConfig = c, clientState = clientState }
                        , user = u
                        , page = pageFromRoute { serverConfig = s, clientConfig = c, clientState = clientState } u route
                        }

                ( Err s, _, _ ) ->
                    Err (App.DecodeError s)

                ( _, Err c, _ ) ->
                    Err (App.DecodeError c)

                ( _, _, Err u ) ->
                    Err (App.DecodeError u)
    in
    ( model, Cmd.none )


{-| Finds a page from the route and the context.
-}
pageFromRoute : Config -> User -> Route -> App.Page
pageFromRoute config user route =
    case route of
        Route.Home ->
            App.Home

        Route.Preparation id ->
            Data.getCapsuleById id user
                |> Maybe.map Preparation.init
                |> Maybe.map App.Preparation
                |> Maybe.withDefault App.Home

        _ ->
            App.Home
