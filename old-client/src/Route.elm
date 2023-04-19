module Route exposing (..)

import Browser.Navigation as Nav
import Url


type AdminRoute
    = Dashboard
    | Users Int
    | User Int
    | Capsules Int


type Route
    = Home
    | Preparation String (Maybe Int)
    | Acquisition String Int
    | Production String Int
    | Publication String
    | CapsuleSettings String
    | Settings
    | Admin AdminRoute
    | NotFound
    | Custom String


sameTab : Route -> Route -> Bool
sameTab route1 route2 =
    case ( route1, route2 ) of
        ( Preparation _ _, Preparation _ _ ) ->
            True

        ( Acquisition _ _, Acquisition _ _ ) ->
            True

        ( Production _ _, Production _ _ ) ->
            True

        ( Publication _, Publication _ ) ->
            True

        ( CapsuleSettings _, CapsuleSettings _ ) ->
            True

        ( Admin Dashboard, Admin Dashboard ) ->
            True

        ( Admin (Users _), Admin (Users _) ) ->
            True

        ( Admin (User _), Admin (User _) ) ->
            True

        ( Admin (Capsules _), Admin (Capsules _) ) ->
            True

        _ ->
            False


goToGos : Int -> Route -> Route
goToGos gos route =
    case route of
        Preparation id _ ->
            Preparation id (Just gos)

        Acquisition id _ ->
            Acquisition id gos

        Production id _ ->
            Production id gos

        x ->
            x


pushUrl : Nav.Key -> Route -> Cmd msg
pushUrl key route =
    Nav.pushUrl key (toUrl route)


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (toUrl route)


toUrl : Route -> String
toUrl route =
    case route of
        Home ->
            "/o/"

        Preparation c Nothing ->
            "/o/capsule/preparation/" ++ c ++ "/"

        Preparation c (Just id) ->
            "/o/capsule/preparation/" ++ c ++ "/#gos-" ++ String.fromInt (2 * id + 1)

        Acquisition c id ->
            "/o/capsule/acquisition/" ++ c ++ "/" ++ String.fromInt (id + 1) ++ "/"

        Production c id ->
            "/o/capsule/production/" ++ c ++ "/" ++ String.fromInt (id + 1) ++ "/"

        Publication id ->
            "/o/capsule/publication/" ++ id ++ "/"

        CapsuleSettings id ->
            "/o/capsule/settings/" ++ id ++ "/"

        Settings ->
            "/o/settings/"

        Admin (User id) ->
            "/o/admin/user/" ++ String.fromInt id ++ "/"

        Admin Dashboard ->
            "/o/admin/"

        Admin (Users pagination) ->
            "/o/admin/users/" ++ String.fromInt pagination ++ "/"

        Admin (Capsules pagination) ->
            "/o/admin/capsules/" ++ String.fromInt pagination ++ "/"

        NotFound ->
            "/o/"

        Custom s ->
            s


fromUrl : Url.Url -> Route
fromUrl u =
    let
        tmp =
            String.split "/" u.path |> List.drop 1

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
        "o" :: "capsule" :: "preparation" :: id :: [] ->
            Preparation id Nothing

        "o" :: "capsule" :: "preparation" :: id :: gosId :: [] ->
            case ( String.left 1 gosId, String.toInt (String.dropLeft 1 gosId) ) of
                ( "#", Just g ) ->
                    Preparation id (Just ((g - 1) // 2))

                _ ->
                    Preparation id Nothing

        "o" :: "capsule" :: "acquisition" :: id :: gosId :: [] ->
            case String.toInt gosId of
                Just g ->
                    Acquisition id (g - 1)

                _ ->
                    NotFound

        "o" :: "capsule" :: "production" :: id :: gosId :: [] ->
            case String.toInt gosId of
                Just g ->
                    Production id (g - 1)

                Nothing ->
                    NotFound

        "o" :: "capsule" :: "publication" :: id :: [] ->
            Publication id

        "o" :: "capsule" :: "settings" :: id :: [] ->
            CapsuleSettings id

        "o" :: "settings" :: [] ->
            Settings

        "o" :: "admin" :: [] ->
            Admin Dashboard

        "o" :: "admin" :: "user" :: id :: [] ->
            case String.toInt id of
                Just i ->
                    Admin (User i)

                Nothing ->
                    NotFound

        "o" :: "admin" :: "users" :: id :: [] ->
            case String.toInt id of
                Just i ->
                    Admin (Users i)

                Nothing ->
                    Admin (Users 0)

        "o" :: "admin" :: "users" :: [] ->
            Admin (Users 0)

        "o" :: "admin" :: "capsules" :: id :: [] ->
            case String.toInt id of
                Just i ->
                    Admin (Capsules i)

                Nothing ->
                    Admin (Capsules 0)

        "o" :: "admin" :: "capsules" :: [] ->
            Admin (Capsules 0)

        [ "o" ] ->
            Home

        _ ->
            NotFound
