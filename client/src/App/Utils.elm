module App.Utils exposing (init, pageFromRoute)

{-| This module contains some util functions that should really be in App/Types.elm but that can't be there because elm
doesn't allow circular module imports...

@docs init, pageFromRoute

-}

import Acquisition.Types as Acquisition
import App.Types as App
import Browser.Navigation
import Config exposing (Config)
import Data.User as Data exposing (User)
import Home.Types as Home
import Json.Decode as Decode
import NewCapsule.Types as NewCapsule
import Preparation.Types as Preparation
import Production.Types as Production
import Publication.Types as Publication
import Route exposing (Route)
import Settings.Types as Settings
import Unlogged.Types as Unlogged
import Url exposing (Url)


{-| Initializes the model for the application
-}
init : Decode.Value -> Url -> Browser.Navigation.Key -> ( App.MaybeModel, Cmd App.MaybeMsg )
init flags url key =
    let
        serverConfig =
            Decode.decodeValue (Decode.field "global" (Decode.field "serverConfig" Config.decodeServerConfig)) flags

        clientConfig =
            Decode.decodeValue (Decode.field "global" (Decode.field "clientConfig" Config.decodeClientConfig)) flags

        clientState =
            Config.initClientState (Just key) (clientConfig |> Result.toMaybe |> Maybe.andThen .lang)

        sortBy =
            clientConfig |> Result.map .sortBy |> Result.withDefault Config.defaultClientConfig.sortBy

        user =
            Decode.decodeValue (Decode.field "user" (Decode.nullable (Data.decodeUser sortBy))) flags

        route =
            Route.fromUrl url

        ( model, cmd ) =
            case ( serverConfig, clientConfig, user ) of
                ( Ok s, Ok c, Ok (Just u) ) ->
                    let
                        ( page, cm ) =
                            pageFromRoute { serverConfig = s, clientConfig = c, clientState = clientState } u route
                    in
                    ( App.Logged
                        { config = { serverConfig = s, clientConfig = c, clientState = clientState }
                        , user = u
                        , page = page
                        }
                    , Cmd.map App.LoggedMsg cm
                    )

                ( Ok s, Ok c, Ok Nothing ) ->
                    ( App.Unlogged <| Unlogged.init { serverConfig = s, clientConfig = c, clientState = clientState } (Just url)
                    , Cmd.none
                    )

                ( Err s, _, _ ) ->
                    ( App.Error (App.DecodeError s), Cmd.none )

                ( _, Err c, _ ) ->
                    ( App.Error (App.DecodeError c), Cmd.none )

                ( _, _, Err u ) ->
                    ( App.Error (App.DecodeError u), Cmd.none )
    in
    ( model, cmd )


{-| Finds a page from the route and the context.
-}
pageFromRoute : Config -> User -> Route -> ( App.Page, Cmd App.Msg )
pageFromRoute config user route =
    case route of
        Route.Home ->
            ( App.Home, Cmd.none )

        Route.Preparation id ->
            ( Data.getCapsuleById id user
                |> Maybe.map Preparation.init
                |> Maybe.map App.Preparation
                |> Maybe.withDefault App.Home
            , Cmd.none
            )

        Route.Acquisition id gos ->
            Data.getCapsuleById id user
                |> Maybe.andThen (Acquisition.init gos)
                |> Maybe.map (\( a, b ) -> ( App.Acquisition a, Cmd.map App.AcquisitionMsg b ))
                |> Maybe.withDefault ( App.Home, Cmd.none )

        Route.Production id gos ->
            Data.getCapsuleById id user
                |> Maybe.andThen (Production.init gos)
                |> Maybe.map (\( a, b ) -> ( App.Production a, Cmd.map App.ProductionMsg b ))
                |> Maybe.withDefault ( App.Home, Cmd.none )

        Route.Publication id ->
            ( Data.getCapsuleById id user
                |> Maybe.map Publication.init
                |> Maybe.map App.Publication
                |> Maybe.withDefault App.Home
            , Cmd.none
            )

        Route.Settings ->
            ( App.Settings Settings.init, Cmd.none )

        _ ->
            ( App.Home, Cmd.none )
