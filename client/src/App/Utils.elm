module App.Utils exposing
    ( init, pageFromRoute
    , capsuleAndGos, capsuleIdFromPage, gosIdFromPage, routeFromPage
    )

{-| This module contains some util functions that should really be in App/Types.elm but that can't be there because elm
doesn't allow circular module imports...

@docs init, pageFromRoute, capsuleFromPage, updatePage

-}

import Acquisition.Types as Acquisition
import App.Types as App
import Browser.Navigation
import Config exposing (Config)
import Data.Capsule as Data
import Data.Types as Data
import Data.User as Data exposing (User)
import Home.Types as Home
import Json.Decode as Decode
import List exposing (product)
import Options.Types as Options
import Preparation.Types as Preparation
import Production.Types as Production
import Profile.Types as Profile
import Publication.Types as Publication
import Route exposing (Route)
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

                        tasks : List Config.TaskStatus
                        tasks =
                            u.projects
                                |> List.map .capsules
                                |> List.concat
                                |> List.filterMap
                                    (\x ->
                                        let
                                            -- Returns Nothing if there is no task running on the capsule, or a function
                                            -- that creates the task from its id.
                                            returnValue : Maybe (Config.TaskId -> Config.Task)
                                            returnValue =
                                                case ( x.produced, x.published ) of
                                                    ( Data.Running _, _ ) ->
                                                        Just (\a -> Config.Production a x.id)

                                                    ( _, Data.Running _ ) ->
                                                        Just (\a -> Config.Publication a x.id)

                                                    _ ->
                                                        Nothing
                                        in
                                        returnValue
                                    )
                                |> List.indexedMap
                                    (\i makeTaskFromId ->
                                        { task = makeTaskFromId i
                                        , progress = Nothing
                                        , finished = False
                                        , aborted = False
                                        , global = True
                                        }
                                    )
                    in
                    ( App.Logged
                        { config =
                            { serverConfig = s
                            , clientConfig = c
                            , clientState =
                                { clientState
                                    | taskId = tasks |> List.length
                                    , tasks = tasks
                                }
                            }
                        , user = u
                        , page = page
                        }
                    , Cmd.map App.LoggedMsg cm
                    )

                ( Ok s, Ok c, Ok Nothing ) ->
                    ( App.Unlogged <| Unlogged.init clientState.lang s.root (Just url)
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


{-| Extracts the capsule id the page.
-}
capsuleIdFromPage : App.Page -> Maybe String
capsuleIdFromPage page =
    case page of
        App.Preparation m ->
            Just m.capsule

        App.Acquisition m ->
            Just m.capsule

        App.Production m ->
            Just m.capsule

        App.Publication m ->
            Just m.capsule

        App.Options m ->
            Just m.capsule

        _ ->
            Nothing


{-| Extracts the gos id from the page, if its meaningful.
-}
gosIdFromPage : App.Page -> Maybe Int
gosIdFromPage page =
    case page of
        App.Acquisition m ->
            Just m.gos

        App.Production m ->
            Just m.gos

        _ ->
            Nothing


{-| Extracts the capsule and the gos from a user and a page.
-}
capsuleAndGos : Data.User -> App.Page -> ( Maybe Data.Capsule, Maybe Data.Gos )
capsuleAndGos user page =
    let
        maybeCapsule : Maybe Data.Capsule
        maybeCapsule =
            capsuleIdFromPage page
                |> Maybe.andThen (\x -> Data.getCapsuleById x user)

        gosFromCapsule : Data.Capsule -> Maybe Data.Gos
        gosFromCapsule capsule =
            gosIdFromPage page
                |> Maybe.andThen (\x -> List.drop x capsule.structure |> List.head)

        maybeGos : Maybe Data.Gos
        maybeGos =
            Maybe.andThen gosFromCapsule maybeCapsule
    in
    ( maybeCapsule, maybeGos )


{-| Finds a page from the route and the context.
-}
pageFromRoute : Config -> User -> Route -> ( App.Page, Cmd App.Msg )
pageFromRoute _ user route =
    case route of
        Route.Home ->
            ( App.Home Home.init, Cmd.none )

        Route.Preparation id ->
            ( Data.getCapsuleById id user
                |> Maybe.map Preparation.init
                |> Maybe.map App.Preparation
                |> Maybe.withDefault (App.Home Home.init)
            , Cmd.none
            )

        Route.Acquisition id gos ->
            Data.getCapsuleById id user
                |> Maybe.andThen (Acquisition.init gos)
                |> Maybe.map (\( a, b ) -> ( App.Acquisition a, Cmd.map App.AcquisitionMsg b ))
                |> Maybe.withDefault ( App.Home Home.init, Cmd.none )

        Route.Production id gos ->
            Data.getCapsuleById id user
                |> Maybe.andThen (Production.init gos)
                |> Maybe.map (\( a, b ) -> ( App.Production a, Cmd.map App.ProductionMsg b ))
                |> Maybe.withDefault ( App.Home Home.init, Cmd.none )

        Route.Publication id ->
            ( Data.getCapsuleById id user
                |> Maybe.map Publication.init
                |> Maybe.map App.Publication
                |> Maybe.withDefault (App.Home Home.init)
            , Cmd.none
            )

        Route.Options id ->
            ( Data.getCapsuleById id user
                |> Maybe.map Options.init
                |> Maybe.map App.Options
                |> Maybe.withDefault (App.Home Home.init)
            , Cmd.none
            )

        Route.Profile ->
            ( App.Profile Profile.init, Cmd.none )

        _ ->
            ( App.Home Home.init, Cmd.none )


{-| Converts the page to a route.
-}
routeFromPage : App.Page -> Route
routeFromPage page =
    case page of
        App.Home _ ->
            Route.Home

        App.NewCapsule _ ->
            Route.Home

        App.Preparation m ->
            Route.Preparation m.capsule

        App.Acquisition m ->
            Route.Acquisition m.capsule m.gos

        App.Production m ->
            Route.Production m.capsule m.gos

        App.Publication m ->
            Route.Publication m.capsule

        App.Options m ->
            Route.Options m.capsule

        App.Profile _ ->
            Route.Profile
