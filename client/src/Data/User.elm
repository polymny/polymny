module Data.User exposing (User, decodeUser, isPremium, addCapsule, deleteCapsule, updateUser, sortProjects, getCapsuleById, Project, toggleProject, compareCapsule, compareProject)

{-| This module contains all the data related to the user.

@docs User, decodeUser, isPremium, addCapsule, deleteCapsule, updateUser, sortProjects, getCapsuleById, Project, toggleProject, compareCapsule, compareProject

-}

import Data.Capsule as Data exposing (Capsule)
import Data.Types as Data
import Json.Decode as Decode exposing (Decoder)
import List.Extra


{-| This type represents capsules that go together.

It does not mean anything per se, a project is just a string in a capsule, but capsules that have the same string belong
together.

-}
type alias Project =
    { name : String
    , capsules : List Data.Capsule
    , folded : Bool
    }


{-| This type is the mapping of the JSON received by the server.

It needs to be modified and sorted before use.

-}
type alias PrivateUser =
    { username : String
    , email : String
    , plan : Data.Plan
    , capsules : List Capsule
    , quota: Int
    }


{-| JSON decoder for PrivateUser.
-}
decodePrivateUser : Decoder PrivateUser
decodePrivateUser =
    Decode.map5 PrivateUser
        (Decode.field "username" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.field "plan" Data.decodePlan)
        (Decode.field "capsules" (Decode.list Data.decodeCapsule))
        (Decode.field "disk_quota" Decode.int)



--(Decode.field "notifications" (Decode.list decodeNotification))


{-| This type represents a user with all the info we have on them.
-}
type alias User =
    { username : String
    , email : String
    , plan : Data.Plan
    , projects : List Project
    , quota: Int
    }


{-| Returns true if the user have access to premium functionnalities.
-}
isPremium : User -> Bool
isPremium user =
    case user.plan of
        Data.PremiumLvl1 ->
            True

        Data.Admin ->
            True

        _ ->
            False


{-| JSON decoder for user.
-}
decodeUser : Data.SortBy -> Decoder User
decodeUser sortBy =
    decodePrivateUser
        |> Decode.map
            (\user ->
                { username = user.username
                , email = user.email
                , plan = user.plan
                , projects = capsulesToProjects user.capsules |> sortProjects sortBy
                , quota = user.quota
                }
            )


{-| Utility function to compare capsules based on a sort by.
-}
compareCapsule : Data.SortBy -> Capsule -> Capsule -> Order
compareCapsule { key, ascending } aInput bInput =
    let
        ( a, b ) =
            if ascending then
                ( aInput, bInput )

            else
                ( bInput, aInput )
    in
    case key of
        Data.Name ->
            compare a.name b.name

        Data.LastModified ->
            compare a.lastModified b.lastModified


{-| Utility function to compare projects based on a sort by.
-}
compareProject : Data.SortBy -> Project -> Project -> Order
compareProject { key, ascending } aInput bInput =
    let
        ( a, b ) =
            if ascending then
                ( aInput, bInput )

            else
                ( bInput, aInput )
    in
    case key of
        Data.Name ->
            compare a.name b.name

        Data.LastModified ->
            compare
                (a.capsules |> List.head |> Maybe.map .lastModified |> Maybe.withDefault 0)
                (b.capsules |> List.head |> Maybe.map .lastModified |> Maybe.withDefault 0)


{-| Utility function to group capsules in projects.
-}
capsulesToProjects : List Capsule -> List Project
capsulesToProjects capsules =
    let
        organizedCapsules : List ( Capsule, List Capsule )
        organizedCapsules =
            List.Extra.gatherWith (\x y -> x.project == y.project) capsules

        capsulesToProject : ( Capsule, List Capsule ) -> Project
        capsulesToProject ( h, t ) =
            { name = h.project
            , capsules = h :: t
            , folded = True
            }
    in
    List.map capsulesToProject organizedCapsules


{-| Sort the projects and the capsules based on a sort by.
-}
sortProjects : Data.SortBy -> List Project -> List Project
sortProjects sortBy projects =
    projects
        |> List.map (\p -> { p | capsules = List.sortWith (compareCapsule sortBy) p.capsules })
        |> List.sortWith (compareProject sortBy)


{-| Toggles a project.
-}
toggleProject : Project -> User -> User
toggleProject project user =
    let
        mapper : Project -> Project
        mapper p =
            if project.name == p.name then
                { p | folded = not p.folded }

            else
                p
    in
    { user | projects = List.map mapper user.projects }


{-| Function to easily fetch a capsule from its id.
-}
getCapsuleById : String -> User -> Maybe Capsule
getCapsuleById id user =
    getCapsuleByIdAux id user.projects


{-| Auxilary function to help fetch a capsule from its id.
-}
getCapsuleByIdAux : String -> List Project -> Maybe Capsule
getCapsuleByIdAux id projects =
    case projects of
        [] ->
            Nothing

        h :: t ->
            case h.capsules of
                [] ->
                    getCapsuleByIdAux id t

                h2 :: t2 ->
                    if h2.id == id then
                        Just h2

                    else
                        getCapsuleByIdAux id ({ h | capsules = t2 } :: t)


{-| Adds a capsule in a user.
-}
addCapsule : Capsule -> User -> User
addCapsule capsule user =
    { user | projects = addCapsuleAux capsule False [] user.projects }


addCapsuleAux : Capsule -> Bool -> List Project -> List Project -> List Project
addCapsuleAux capsule finished acc input =
    case input of
        [] ->
            if finished then
                acc

            else
                { name = capsule.project, capsules = [ capsule ], folded = False } :: acc

        h :: t ->
            if finished then
                addCapsuleAux capsule True (h :: acc) t

            else if h.name == capsule.project then
                addCapsuleAux capsule True ({ h | capsules = capsule :: h.capsules } :: acc) t

            else
                addCapsuleAux capsule False (h :: acc) t


{-| Deletes a capsule in a user.
-}
deleteCapsule : Capsule -> User -> User
deleteCapsule capsule user =
    let
        projectMapper : Project -> Project
        projectMapper project =
            { project | capsules = List.filter (\c -> c.id /= capsule.id) project.capsules }
    in
    { user
        | projects =
            List.map projectMapper user.projects
                |> List.filter (\x -> not <| List.isEmpty x.capsules)
    }


{-| Updates a capsule in a user.
-}
updateUser : Capsule -> User -> User
updateUser capsule user =
    let
        capsuleMapper : Capsule -> Capsule
        capsuleMapper c =
            if c.id == capsule.id then
                capsule

            else
                c

        projectMapper : Project -> Project
        projectMapper project =
            { project | capsules = List.map capsuleMapper project.capsules }
    in
    { user | projects = List.map projectMapper user.projects }
