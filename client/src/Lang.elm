module Lang exposing
    ( Lang(..), fromString, toString
    , default, other, question
    )

{-| This module holds the lang type and the different strings represented in the different languages.


# Type definition

@docs Lang, fromString, toString


# Utils functions

@docs default, other, question

-}


{-| This type enumerates all languages supported by Polymny.

Each variant represents a locale.

-}
type Lang
    = FrFr
    | EnUs


{-| This function returns the string representation of the lang.

    toLang FrFr == "fr-FR"

-}
toString : Lang -> String
toString lang =
    case lang of
        FrFr ->
            "fr-FR"

        EnUs ->
            "en-US"


{-| This tries to guess the language from a string.

It's a best effort approach, so weird things can happen, but if it has no clue, it will return nothing.

    fromString "fr-Toto" == "fr-FR"

-}
fromString : String -> Maybe Lang
fromString string =
    if String.startsWith "fr-" string then
        Just FrFr

    else if String.startsWith "en-" string then
        Just EnUs

    else
        Nothing


{-| The lang that is set by default
-}
default : Lang
default =
    FrFr


{-| Returns the other lang.

Since we have only two langs supported, it makes it easy to swich lang.

-}
other : Lang -> Lang
other lang =
    case lang of
        FrFr ->
            EnUs

        EnUs ->
            FrFr


{-| Adds an interrogation mark to a string.
-}
question : (Lang -> String) -> Lang -> String
question string lang =
    case lang of
        FrFr ->
            string lang ++ " ?"

        _ ->
            string lang ++ "?"
