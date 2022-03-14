module Route exposing (Route(..), toUrl, fromUrl, fromPage, push)

{-| This module contains the type definition of the routes of the app, and the utility functions to manipulate routes.

@docs Route, toUrl, fromUrl, fromPage, push

-}

import App.Types as App
import Browser.Navigation
import Url


{-| This type represents the different routes of our application.
-}
type Route
    = Home
    | Preparation String
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

        _ ->
            NotFound


{-| Extracts the route corresponding to a specific page.
-}
fromPage : App.Page -> Route
fromPage page =
    case page of
        App.Home ->
            Home

        App.NewCapsule _ ->
            Home

        App.Preparation m ->
            Preparation m.capsule.id


{-| Go to the corresponding page.
-}
push : Browser.Navigation.Key -> Route -> Cmd msg
push key route =
    Browser.Navigation.pushUrl key (toUrl route)
