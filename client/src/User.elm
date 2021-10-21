module User exposing
    ( Notification
    , Plan(..)
    , Project
    , SortBy(..)
    , User
    , addCapsule
    , changeCapsule
    , changeCapsuleById
    , decode
    , decodeNotification
    , decodePlan
    , decodeSortBy
    , isPremium
    , makeProject
    , printPlan
    , removeCapsule
    , removeProject
    )

import Capsule exposing (Capsule)
import Json.Decode as Decode exposing (Decoder)
import List.Extra


type SortBy
    = Name
    | LastModified


decodeSortBy : Decoder ( SortBy, Bool )
decodeSortBy =
    Decode.map2 Tuple.pair
        (Decode.index 0
            (Decode.string
                |> Decode.andThen
                    (\str ->
                        case str of
                            "name" ->
                                Decode.succeed Name

                            "lastModified" ->
                                Decode.succeed LastModified

                            _ ->
                                Decode.fail <| "Unknown sort by " ++ str
                    )
            )
        )
        (Decode.index 1 Decode.bool)


type Plan
    = Free
    | PremiumLvl1
    | Admin


decodePlan : Decoder Plan
decodePlan =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "free" ->
                        Decode.succeed Free

                    "premium_lvl1" ->
                        Decode.succeed PremiumLvl1

                    "admin" ->
                        Decode.succeed Admin

                    _ ->
                        Decode.fail <| "Unkown plan: " ++ str
            )


isPremium : User -> Bool
isPremium user =
    user.plan == PremiumLvl1 || user.plan == Admin


type alias Notification =
    { id : Int
    , title : String
    , content : String
    , read : Bool
    }


decodeNotification : Decoder Notification
decodeNotification =
    Decode.map4 Notification
        (Decode.field "id" Decode.int)
        (Decode.field "title" Decode.string)
        (Decode.field "content" Decode.string)
        (Decode.field "read" Decode.bool)


type alias PrivateUser =
    { username : String
    , capsules : List Capsule
    , email : String
    , notifications : List Notification
    , plan : Plan
    , diskQuota : Int
    }


decodePrivate : Decoder PrivateUser
decodePrivate =
    Decode.map6 PrivateUser
        (Decode.field "username" Decode.string)
        (Decode.field "capsules" (Decode.list Capsule.decode))
        (Decode.field "email" Decode.string)
        (Decode.field "notifications" (Decode.list decodeNotification))
        (Decode.field "plan" decodePlan)
        (Decode.field "disk_quota" Decode.int)


type alias Project =
    { name : String
    , capsules : List Capsule
    , folded : Bool
    }


projects : ( SortBy, Bool ) -> PrivateUser -> List Project
projects ( sort, ascend ) user =
    let
        grouped =
            List.Extra.gatherWith
                (\x y -> x.project == y.project)
                user.capsules
    in
    List.map (makeProject ( sort, ascend )) grouped
        |> List.sortWith (compareProject ( sort, ascend ))


makeProject : ( SortBy, Bool ) -> ( Capsule, List Capsule ) -> Project
makeProject ( sort, ascend ) ( head, tail ) =
    { name = head.project
    , capsules = List.sortWith (compareCapsule ( sort, ascend )) (head :: tail)
    , folded = True
    }


compareCapsule : ( SortBy, Bool ) -> Capsule -> Capsule -> Order
compareCapsule ( sort, ascend ) aInput bInput =
    let
        ( a, b ) =
            if ascend then
                ( aInput, bInput )

            else
                ( bInput, aInput )
    in
    case sort of
        Name ->
            compare a.name b.name

        LastModified ->
            compare a.lastModified b.lastModified


compareProject : ( SortBy, Bool ) -> Project -> Project -> Order
compareProject ( sort, ascend ) aInput bInput =
    let
        ( a, b ) =
            if ascend then
                ( aInput, bInput )

            else
                ( bInput, aInput )
    in
    case sort of
        Name ->
            compare a.name b.name

        LastModified ->
            compare
                (a.capsules |> List.head |> Maybe.map .lastModified |> Maybe.withDefault 0)
                (b.capsules |> List.head |> Maybe.map .lastModified |> Maybe.withDefault 0)


type alias User =
    { username : String
    , projects : List Project
    , email : String
    , notifications : List Notification
    , plan : Plan
    , diskQuota : Int
    }


decode : ( SortBy, Bool ) -> Decoder User
decode sort =
    Decode.map (toUser sort) decodePrivate


toUser : ( SortBy, Bool ) -> PrivateUser -> User
toUser sort private =
    { username = private.username
    , projects = projects sort private
    , email = private.email
    , notifications = private.notifications
    , plan = private.plan
    , diskQuota = private.diskQuota
    }


removeCapsuleFromProject : String -> Project -> Project
removeCapsuleFromProject id project =
    { project | capsules = List.filter (\x -> x.id /= id) project.capsules }


removeCapsule : String -> User -> User
removeCapsule id user =
    { user | projects = List.map (removeCapsuleFromProject id) user.projects }


removeProjectIter : String -> Project -> Maybe Project
removeProjectIter name project =
    let
        capsules =
            List.filter (\x -> x.project /= name || x.role /= Capsule.Owner) project.capsules
    in
    case capsules of
        [] ->
            Nothing

        _ ->
            Just { project | capsules = capsules }


removeProject : String -> User -> User
removeProject name user =
    { user | projects = List.filterMap (removeProjectIter name) user.projects }


addCapsule : Capsule -> User -> User
addCapsule capsule user =
    { user | projects = addCapsuleAux capsule [] user.projects }


addCapsuleAux : Capsule -> List Project -> List Project -> List Project
addCapsuleAux capsule acc projectList =
    case projectList of
        h :: t ->
            if h.name == capsule.project then
                acc ++ ({ h | capsules = capsule :: h.capsules, folded = False } :: t)

            else
                addCapsuleAux capsule (h :: acc) t

        _ ->
            acc ++ [ { name = capsule.project, capsules = [ capsule ], folded = False } ]


changeCapsule : Capsule -> User -> User
changeCapsule capsule user =
    changeCapsuleById (\_ -> capsule) capsule.id user


changeCapsuleById : (Capsule -> Capsule) -> String -> User -> User
changeCapsuleById updater id user =
    { user | projects = changeCapsuleByIdAux updater id user.projects }


changeCapsuleByIdAux : (Capsule -> Capsule) -> String -> List Project -> List Project
changeCapsuleByIdAux updater id projs =
    List.map (\x -> { x | capsules = changeCapsuleByIdInProject updater id x.capsules }) projs


changeCapsuleByIdInProject : (Capsule -> Capsule) -> String -> List Capsule -> List Capsule
changeCapsuleByIdInProject updater id project =
    List.map
        (\x ->
            if id == x.id then
                updater x

            else
                x
        )
        project


printPlan : Plan -> String
printPlan plan =
    case plan of
        Free ->
            "Free"

        PremiumLvl1 ->
            "Premium level 1"

        Admin ->
            "Admin"
