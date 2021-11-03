module Utils exposing (andMap, checkEmail, isJust, tern)

import Json.Decode as Decode exposing (Decoder)


tern : Bool -> a -> a -> a
tern b valThen valElse =
    if b then
        valThen

    else
        valElse


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)


checkEmail : String -> Bool
checkEmail email =
    let
        splitAt =
            String.split "@" email

        host =
            List.drop 1 splitAt |> List.head |> Maybe.map (String.split "." >> List.length)
    in
    case ( List.length splitAt == 2, not (String.contains " " email), host ) of
        ( True, True, Just x ) ->
            x > 1

        _ ->
            False


isJust : Maybe a -> Bool
isJust maybe =
    case maybe of
        Just _ ->
            True

        _ ->
            False
