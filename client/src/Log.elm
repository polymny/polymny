module Log exposing (debug, debugSlides)

import Capsule.Types as Capsule


debug : String -> a -> a
debug message value =
    Debug.log message value



-- Release version
-- debug : String -> a -> a
-- debug message value =
--     value


debugSlides : String -> List Capsule.MaybeSlide -> List Capsule.MaybeSlide
debugSlides message slides =
    let
        _ =
            debug message
                (List.map
                    (\x ->
                        case x of
                            Capsule.GosId id ->
                                "GosId " ++ String.fromInt id

                            Capsule.JustSlide s ->
                                "JustSlide " ++ s.prompt
                    )
                    slides
                )
    in
    slides
