module TimeUtils exposing (..)

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


timeToString : Int -> String
timeToString t =
    let
        time =
            Time.millisToPosix (1000 * t)

        year =
            String.fromInt (Time.toYear Time.utc time)

        month =
            monthToString (Time.toMonth Time.utc time)

        day =
            String.fromInt (Time.toDay Time.utc time)
    in
    month ++ " " ++ day ++ " " ++ year
