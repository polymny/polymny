module Utils exposing (andMap, tern, regroup, regroupFixed)

{-| This module contains useful functions.

@docs andMap, tern, regroup, regroupFixed

-}

import Json.Decode as Decode exposing (Decoder)


{-| This function allows to chain Decode.map and avoid being limited by the max map value in Decode.mapX.
-}
andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)


{-| A ternary for elm.
-}
tern : Bool -> a -> a -> a
tern test x y =
    if test then
        x

    else
        y


{-| Regroup elements of list inside lists of fixed size.
-}
regroup : Int -> List a -> List (List a)
regroup size input =
    regroupAux [] size input |> List.map List.reverse |> List.reverse


{-| Auxilary function to help write the regroup function.
-}
regroupAux : List (List a) -> Int -> List a -> List (List a)
regroupAux acc size input =
    case ( acc, input ) of
        ( _, [] ) ->
            acc

        ( [], h :: t ) ->
            regroupAux [ [ h ] ] size t

        ( h1 :: t1, h2 :: t2 ) ->
            if List.length h1 < size then
                regroupAux ((h2 :: h1) :: t1) size t2

            else
                regroupAux ([ h2 ] :: h1 :: t1) size t2


{-| Regroup elements of list inside lists of fixed size, but fill last one with nothings.
-}
regroupFixed : Int -> List a -> List (List (Maybe a))
regroupFixed size input =
    regroupFixedAux [] size input |> List.map List.reverse |> List.reverse


{-| Auxilary function to help write the regroup fixed function.
-}
regroupFixedAux : List (List (Maybe a)) -> Int -> List a -> List (List (Maybe a))
regroupFixedAux acc size input =
    case ( acc, input ) of
        ( [], [] ) ->
            []

        ( h :: t, [] ) ->
            if List.length h < size then
                regroupFixedAux ((Nothing :: h) :: t) size []

            else
                acc

        ( [], h :: t ) ->
            regroupFixedAux [ [ Just h ] ] size t

        ( h1 :: t1, h2 :: t2 ) ->
            if List.length h1 < size then
                regroupFixedAux ((Just h2 :: h1) :: t1) size t2

            else
                regroupFixedAux ([ Just h2 ] :: h1 :: t1) size t2
