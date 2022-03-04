module Triplet exposing (first, second, third, mapFirst, mapSecond, mapThird)

{-| This module helps us deal with triplet.

Since Elm has the bad habit of using the module `Tuple` to manipulate what in fact is pairs, we have the triplet module,
to help us deal with non pair truples (which are triplets, because Elm doesn't want use to have tuples with more than 3
elements...

@docs first, second, third, mapFirst, mapSecond, mapThird

-}


{-| Extracts the first element of the triplet.
-}
first : ( a, b, c ) -> a
first ( a, _, _ ) =
    a


{-| Extracts the second element of the triplet.
-}
second : ( a, b, c ) -> b
second ( _, b, _ ) =
    b


{-| Extracts the third element of the triplet.
-}
third : ( a, b, c ) -> c
third ( _, _, c ) =
    c


{-| Maps a function on the first element of the triplet.
-}
mapFirst : (a -> d) -> ( a, b, c ) -> ( d, b, c )
mapFirst mapper ( a, b, c ) =
    ( mapper a, b, c )


{-| Maps a function on the second element of the triplet.
-}
mapSecond : (b -> d) -> ( a, b, c ) -> ( a, d, c )
mapSecond mapper ( a, b, c ) =
    ( a, mapper b, c )


{-| Maps a function on the third element of the triplet.
-}
mapThird : (c -> d) -> ( a, b, c ) -> ( a, b, d )
mapThird mapper ( a, b, c ) =
    ( a, b, mapper c )
