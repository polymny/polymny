module Ui.Graphics exposing (logo, logoBlue, logoRed)

{-| This module contains all the graphics elements of the polymny UI.

@docs logo, logoBlue, logoRed

-}

import Element exposing (Element)
import Ui.Utils as Ui


{-| Helper to easily create logos.
-}
mkLogo : Int -> String -> Element msg
mkLogo size path =
    Element.el [ Ui.p 5 ]
        (Element.image [ Ui.hpx size, Ui.wpx size ]
            { src = "/dist/" ++ path
            , description = "The logo of Polymny Studio"
            }
        )


{-| The logo of the polymny application.
-}
logo : Int -> Element msg
logo size =
    mkLogo size "logo.webp"


{-| The blue version of the logo of Polymny.
-}
logoBlue : Int -> Element msg
logoBlue size =
    mkLogo size "logo-blue.webp"


{-| The red version of the logo of Polymny.
-}
logoRed : Int -> Element msg
logoRed size =
    mkLogo size "logo-red.webp"
