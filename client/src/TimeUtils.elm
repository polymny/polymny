module TimeUtils exposing (formatDuration, formatTime, formatDate)

{-| This module provides functions to help deal with tough times.

@docs formatDuration, formatTime, formatDate

-}

import Lang exposing (Lang)
import Strings
import Time


{-| Helper to format month.
-}
formatMonth : Lang -> Time.Month -> String
formatMonth lang month =
    case month of
        Time.Jan ->
            Strings.dateMonthJanuary lang

        Time.Feb ->
            Strings.dateMonthFebruary lang

        Time.Mar ->
            Strings.dateMonthMarch lang

        Time.Apr ->
            Strings.dateMonthApril lang

        Time.May ->
            Strings.dateMonthMay lang

        Time.Jun ->
            Strings.dateMonthJune lang

        Time.Jul ->
            Strings.dateMonthJuly lang

        Time.Aug ->
            Strings.dateMonthAugust lang

        Time.Sep ->
            Strings.dateMonthSeptember lang

        Time.Oct ->
            Strings.dateMonthOctober lang

        Time.Nov ->
            Strings.dateMonthNovember lang

        Time.Dec ->
            Strings.dateMonthDecember lang


{-| Helper to format dates.
-}
formatDate : Lang -> Time.Zone -> Int -> String
formatDate l z t =
    let
        time =
            Time.millisToPosix (1000 * t)

        year =
            String.fromInt (Time.toYear z time)

        month =
            formatMonth l (Time.toMonth z time)

        day =
            String.fromInt (Time.toDay z time)
    in
    case l of
        Lang.FrFr ->
            day ++ " " ++ month ++ " " ++ year

        _ ->
            month ++ " " ++ day ++ ", " ++ year


{-| Help to formar times.
-}
formatTime : Lang -> Time.Zone -> Int -> String
formatTime l z t =
    let
        time =
            Time.millisToPosix (1000 * t)

        date =
            formatDate l z t

        hours =
            String.pad 2 '0' (String.fromInt (Time.toHour z time))

        minutes =
            String.pad 2 '0' (String.fromInt (Time.toMinute z time))

        seconds =
            String.pad 2 '0' (String.fromInt (Time.toSecond z time))
    in
    case l of
        Lang.FrFr ->
            date ++ " à " ++ hours ++ ":" ++ minutes ++ ":" ++ seconds

        _ ->
            date ++ " at " ++ hours ++ ":" ++ minutes ++ ":" ++ seconds


{-| Helper to pretty print a duration.
-}
formatDuration : Int -> String
formatDuration milliseconds =
    let
        seconds =
            milliseconds // 1000

        minutes =
            seconds // 60

        secs =
            modBy 60 seconds

        secsString =
            if secs < 10 then
                "0" ++ String.fromInt secs

            else
                String.fromInt secs

        minutesString =
            if minutes < 10 then
                "0" ++ String.fromInt minutes

            else
                String.fromInt minutes
    in
    minutesString ++ ":" ++ secsString
