module Data.Types exposing
    ( SortBy, encodeSortBy, decodeSortBy, SortKey(..), encodeSortKey, decodeSortKey
    , Plan(..), decodePlan
    , Role(..), encodeRole, roleFromString, decodeRole
    , TaskStatus(..), decodeTaskStatus
    , Privacy(..), encodePrivacy, decodePrivacy
    )

{-| This module contains the different types that are useful for users and capsules.


# Sorting capsules in users view

@docs SortBy, encodeSortBy, decodeSortBy, SortKey, encodeSortKey, decodeSortKey


# Plans

@docs Plan, decodePlan


# Users roles

@docs Role, encodeRole, roleFromString, decodeRole


# Task status

@docs TaskStatus, decodeTaskStatus


# Capsules privacy

@docs Privacy, encodePrivacy, decodePrivacy

-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


{-| This type indicates on which data the user wants to sort its capsules.
-}
type SortKey
    = Name
    | LastModified


{-| JSON encoder for sort key.
-}
encodeSortKey : SortKey -> Encode.Value
encodeSortKey key =
    case key of
        Name ->
            Encode.string "name"

        LastModified ->
            Encode.string "lastModified"


{-| JSON decoder for sort key.
-}
decodeSortKey : Decoder SortKey
decodeSortKey =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "name" ->
                        Decode.succeed Name

                    "lastModified" ->
                        Decode.succeed LastModified

                    _ ->
                        Decode.fail <| "Unknown sort key " ++ str
            )


{-| This type gives all the information on which the user want to sort its capsules, the key to perform the sort and
whether the order should be ascending or descending.
-}
type alias SortBy =
    { key : SortKey
    , ascending : Bool
    }


{-| JSON encoder for sort by.
-}
encodeSortBy : SortBy -> Encode.Value
encodeSortBy { key, ascending } =
    Encode.object
        [ ( "key", encodeSortKey key )
        , ( "ascending", Encode.bool ascending )
        ]


{-| JSON decoder for sort by.
-}
decodeSortBy : Decoder SortBy
decodeSortBy =
    Decode.map2 SortBy
        (Decode.field "key" decodeSortKey)
        (Decode.field "ascending" Decode.bool)


{-| This type represents the different plans on which a user can be.
-}
type Plan
    = Free
    | PremiumLvl1
    | Admin


{-| JSON decoder for plan.
-}
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


{-| This type represents the different roles a user can have for a capsule.
-}
type Role
    = Read
    | Write
    | Owner


{-| JSON encoder for role.
-}
encodeRole : Role -> String
encodeRole role =
    case role of
        Read ->
            "read"

        Write ->
            "write"

        Owner ->
            "owner"


{-| Decode a role from a string.
-}
roleFromString : String -> Maybe Role
roleFromString role =
    case role of
        "read" ->
            Just Read

        "write" ->
            Just Write

        "owner" ->
            Just Owner

        _ ->
            Nothing


{-| JSON decoder for role.
-}
decodeRole : Decoder Role
decodeRole =
    Decode.string
        |> Decode.andThen
            (\str ->
                case roleFromString str of
                    Just x ->
                        Decode.succeed x

                    _ ->
                        Decode.fail <| "Unknown role: " ++ str
            )


{-| This type represents the different states in which a server task can be.
-}
type TaskStatus
    = Idle
    | Running (Maybe Float)
    | Done


{-| JSON decoder for the task status.
-}
decodeTaskStatus : Decoder TaskStatus
decodeTaskStatus =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "idle" ->
                        Decode.succeed Idle

                    "running" ->
                        Decode.succeed (Running Nothing)

                    "done" ->
                        Decode.succeed Done

                    x ->
                        Decode.fail <| "Unknown task status: " ++ x
            )


{-| The different privacy types for a published capsule.
-}
type Privacy
    = Private
    | Unlisted
    | Public


{-| JSON encoder for privacy.
-}
encodePrivacy : Privacy -> Encode.Value
encodePrivacy privacy =
    Encode.string
        (case privacy of
            Private ->
                "private"

            Unlisted ->
                "unlisted"

            Public ->
                "public"
        )


{-| JSON decoder for privacy.
-}
decodePrivacy : Decoder Privacy
decodePrivacy =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "private" ->
                        Decode.succeed Private

                    "unlisted" ->
                        Decode.succeed Unlisted

                    "public" ->
                        Decode.succeed Public

                    x ->
                        Decode.fail <| "Unknown privacy: " ++ x
            )
