module TimeUtils exposing (timeToString)

import Lang exposing (Lang)
import Time


monthToString : Lang -> Time.Month -> String
monthToString lang month =
    case lang of
        Lang.FrFr ->
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

        _ ->
            case month of
                Time.Jan ->
                    "January"

                Time.Feb ->
                    "February"

                Time.Mar ->
                    "March"

                Time.Apr ->
                    "April"

                Time.May ->
                    "May"

                Time.Jun ->
                    "June"

                Time.Jul ->
                    "July"

                Time.Aug ->
                    "August"

                Time.Sep ->
                    "September"

                Time.Oct ->
                    "October"

                Time.Nov ->
                    "November"

                Time.Dec ->
                    "December"


dateToString : Lang -> Time.Zone -> Int -> String
dateToString l z t =
    let
        time =
            Time.millisToPosix (1000 * t)

        year =
            String.fromInt (Time.toYear z time)

        month =
            monthToString l (Time.toMonth z time)

        day =
            String.fromInt (Time.toDay z time)
    in
    case l of
        Lang.FrFr ->
            day ++ " " ++ month ++ " " ++ year

        _ ->
            month ++ " " ++ day ++ ", " ++ year


timeToString : Lang -> Time.Zone -> Int -> String
timeToString l z t =
    let
        time =
            Time.millisToPosix (1000 * t)

        date =
            dateToString l z t

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
