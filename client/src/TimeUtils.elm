module TimeUtils exposing (timeToString)

import Time


monthToString : Time.Month -> String
monthToString month =
    case month of
        Time.Jan ->
            "Janvier"

        Time.Feb ->
            "Février"

        Time.Mar ->
            "Mars"

        Time.Apr ->
            "Avril"

        Time.May ->
            "Mai"

        Time.Jun ->
            "Juin"

        Time.Jul ->
            "Juillet"

        Time.Aug ->
            "Août"

        Time.Sep ->
            "Septembre"

        Time.Oct ->
            "Octobre"

        Time.Nov ->
            "Novembre"

        Time.Dec ->
            "Décembre"


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
    day ++ " " ++ month ++ " " ++ year


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
    date ++ " à " ++ hours ++ ":" ++ minutes ++ ":" ++ seconds
