module Utils exposing (Confirmation(..), andMap, get, headAndTail, tern, regroup, regroupFixed, checkEmail, passwordStrength, passwordStrengthElement, minPasswordStrength)

{-| This module contains useful functions.

@docs Confirmation, andMap, get, headAndTail, tern, regroup, regroupFixed, checkEmail, passwordStrength, passwordStrengthElement, minPasswordStrength

-}

import Element exposing (Element)
import Element.Background as Background
import Json.Decode as Decode exposing (Decoder)
import Ui.Colors as Colors
import Ui.Utils as Ui


{-| Type for things that require user confirmation.
-}
type Confirmation
    = Request
    | Confirm
    | Cancel


{-| This function allows to chain Decode.map and avoid being limited by the max map value in Decode.mapX.
-}
andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Decode.map2 (|>)


{-| Get item in list by index.
-}
get : Int -> List a -> Maybe a
get index list =
    if index < 0 then
        Nothing

    else
        List.drop index list |> List.head


{-| Deconstructs a list.
-}
headAndTail : List a -> Maybe ( a, List a )
headAndTail input =
    case input of
        h :: t ->
            Just ( h, t )

        _ ->
            Nothing


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


{-| Checks whether an email address has a correct syntax.
-}
checkEmail : String -> Bool
checkEmail email =
    let
        splitAt =
            String.split "@" email

        host =
            List.drop 1 splitAt |> List.head |> Maybe.map (String.split "." >> List.length)
    in
    case ( ( String.endsWith "." email, List.length splitAt == 2 ), ( not (String.contains " " email), host ) ) of
        ( ( False, True ), ( True, Just x ) ) ->
            x > 1

        _ ->
            False


{-| Returns the strength of the password. A strength less than 5 is refused, and less than 6 gives a warning.
-}
passwordStrength : String -> Int
passwordStrength password =
    let
        specialChars =
            "[!@#$%^&*()_+-=[]{};':\"|,.<>\\/?]" |> String.toList

        passwordLength =
            String.length password

        lengthStrength =
            if passwordLength > 9 then
                3

            else if passwordLength > 7 then
                2

            else
                1

        boolToInt : Bool -> Int
        boolToInt bool =
            if bool then
                1

            else
                0

        hasLowerCase =
            boolToInt <| String.any Char.isLower password

        hasUpperCase =
            boolToInt <| String.any Char.isUpper password

        hasDigit =
            boolToInt <| String.any Char.isDigit password

        hasSpecial =
            boolToInt <| String.any (\x -> List.member x specialChars) password
    in
    if passwordLength == 0 then
        0

    else if passwordLength < 6 then
        1

    else
        lengthStrength + hasLowerCase + hasUpperCase + hasDigit + hasSpecial


{-| Minimum allowed password strength.
-}
minPasswordStrength : Int
minPasswordStrength =
    5


{-| Progress bar that shows the strength of the password.
-}
passwordStrengthElement : String -> Element msg
passwordStrengthElement password =
    let
        strength =
            passwordStrength password

        color =
            if strength < 5 then
                Colors.red

            else if strength < 6 then
                Colors.orange

            else
                Colors.green2

        firstAttr =
            if strength == 7 then
                Ui.r 10

            else
                Ui.rl 10

        secondAttr =
            if strength == 0 then
                Ui.r 10

            else
                Ui.rr 10
    in
    Element.row [ Ui.wf, Ui.hpx 10 ]
        [ Element.el [ firstAttr, Ui.hf, Background.color color, Ui.wfp strength ] Element.none
        , Element.el [ secondAttr, Ui.hf, Background.color Colors.greyBorder, Ui.wfp (7 - strength) ] Element.none
        ]
