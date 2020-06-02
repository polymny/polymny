module Log exposing (debug)


debug : String -> a -> a
debug message value =
    Debug.log message value



-- Release version
-- debug : String -> a -> a
-- debug message value =
--     value
