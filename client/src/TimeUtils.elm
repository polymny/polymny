module TimeUtils exposing (timeToString)

import Time


monthToString : Time.Month -> String
monthToString month =
    case month of
        Time.Jan ->
            "january"

        Time.Feb ->
            "february"

        Time.Mar ->
            "march"

        Time.Apr ->
            "april"

        Time.May ->
            "may"

        Time.Jun ->
            "june"

        Time.Jul ->
            "july"

        Time.Aug ->
            "august"

        Time.Sep ->
            "september"

        Time.Oct ->
            "october"

        Time.Nov ->
            "november"

        Time.Dec ->
            "december"


dateToString : Time.Zone -> Int -> String
dateToString z t =
    let
        time =
            Time.millisToPosix (1000 * t)

        year =
            String.fromInt (Time.toYear z time)

        month =
            monthToString (Time.toMonth z time)

        day =
            String.fromInt (Time.toDay z time)
    in
    month ++ " " ++ day ++ " " ++ year


timeToString : Time.Zone -> Int -> String
timeToString z t =
    let
        time =
            Time.millisToPosix (1000 * t)

        date =
            dateToString z t

        hours =
            String.pad 2 '0' (String.fromInt (Time.toHour z time))

        minutes =
            String.pad 2 '0' (String.fromInt (Time.toMinute z time))

        seconds =
            String.pad 2 '0' (String.fromInt (Time.toSecond z time))
    in
    date ++ " " ++ hours ++ ":" ++ minutes ++ ":" ++ seconds
