module Route exposing (Route(..), toUrl, compareTab, fromUrl, push)

{-| This module contains the type definition of the routes of the app, and the utility functions to manipulate routes.

@docs Route, toUrl, compareTab, fromUrl, push

-}

import Browser.Navigation
import Url


{-| This type represents the different routes of our application.
-}
type Route
    = Home
    | Preparation String
    | Acquisition String Int
    | Production String Int
    | Publication String
    | Options String
    | Profile
    | NotFound
    | Custom String


{-| Converts the route to the string representing the URL of the route. The NotFound route will redirect to Home.
-}
toUrl : Route -> String
toUrl route =
    case route of
        Home ->
            "/"

        Preparation s ->
            "/capsule/preparation/" ++ s

        Acquisition s i ->
            "/capsule/acquisition/" ++ s ++ "/" ++ String.fromInt (i + 1)

        Production s i ->
            "/capsule/production/" ++ s ++ "/" ++ String.fromInt (i + 1)

        Publication s ->
            "/capsule/publication/" ++ s

        Options s ->
            "/capsule/options/" ++ s

        Profile ->
            "/profile"

        NotFound ->
            "/"

        Custom url ->
            url


{-| Tries to convert a URL to the corresponding route. Returns NotFound if the route wasn't found.
-}
fromUrl : Url.Url -> Route
fromUrl url =
    let
        tmp =
            String.split "/" url.path |> List.drop 1

        rev =
            List.reverse tmp

        -- this allows for trailing slash
        split =
            case List.head rev of
                Just x ->
                    if x == "" then
                        List.drop 1 rev |> List.reverse

                    else
                        List.reverse rev

                _ ->
                    tmp
    in
    case split of
        [] ->
            Home

        "capsule" :: "preparation" :: id :: [] ->
            Preparation id

        "capsule" :: "acquisition" :: id :: gos :: [] ->
            String.toInt gos
                |> Maybe.map (\gosId -> Acquisition id (gosId - 1))
                |> Maybe.withDefault NotFound

        "capsule" :: "production" :: id :: gos :: [] ->
            String.toInt gos
                |> Maybe.map (\gosId -> Production id (gosId - 1))
                |> Maybe.withDefault NotFound

        "capsule" :: "publication" :: id :: [] ->
            Publication id

        "capsule" :: "options" :: id :: [] ->
            Options id

        "profile" :: [] ->
            Profile

        _ ->
            NotFound


{-| Checks if the tab of the routes are the same.
-}
compareTab : Route -> Route -> Bool
compareTab r1 r2 =
    case ( r1, r2 ) of
        ( Home, Home ) ->
            True

        ( Preparation _, Preparation _ ) ->
            True

        ( Acquisition _ _, Acquisition _ _ ) ->
            True

        ( Production _ _, Production _ _ ) ->
            True

        ( Publication _, Publication _ ) ->
            True

        ( Options _, Options _ ) ->
            True

        ( Profile, Profile ) ->
            True

        _ ->
            False


{-| Go to the corresponding page.
-}
push : Maybe Browser.Navigation.Key -> Route -> Cmd msg
push key route =
    case key of
        Just k ->
            Browser.Navigation.pushUrl k (toUrl route)

        _ ->
            Cmd.none
