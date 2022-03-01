module Utils exposing (andMap, tern)

{-| This module contains useful functions.

@docs andMap, tern

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
