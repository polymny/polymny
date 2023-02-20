module Lang exposing
    ( Lang(..), langs, fromString, toString, toLocal, flag
    , default, question, dots
    , warning
    )

{-| This module holds the lang type and the different strings represented in the different languages.


# Type definition

@docs Lang, langs, fromString, toString, toLocal, flag


# Utils functions

@docs default, other, question, dots

-}


{-| This type enumerates all languages supported by Polymny.

Each variant represents a locale.

-}
type Lang
    = FrFr
    | EnUs


{-| A list containing all available langs.
-}
langs : List Lang
langs =
    [ EnUs, FrFr ]


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


{-| This functions returns the local name of the lang.
-}
toLocal : Lang -> String
toLocal lang =
    case lang of
        FrFr ->
            "Français"

        EnUs ->
            "English"


{-| Returns the UTF-8 emoji for a flag representing the lang.
-}
flag : Lang -> String
flag lang =
    case lang of
        FrFr ->
            "🇫🇷"

        EnUs ->
            "🇺🇸"


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


{-| Adds an interrogation mark to a string.
-}
question : (Lang -> String) -> Lang -> String
question string lang =
    case lang of
        FrFr ->
            string lang ++ " ?"

        _ ->
            string lang ++ "?"


{-| Adds three dots at the end of a string.
-}
dots : (Lang -> String) -> Lang -> String
dots string lang =
    case lang of
        _ ->
            string lang ++ "..."


{-| Adds warning emoji at the beginning and end of a string.
-}
warning : (Lang -> String) -> Lang -> String
warning string lang =
    "⚠️ " ++ string lang ++ " ⚠️"
