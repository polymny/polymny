module Ui.Graphics exposing (logo, logoBlue, logoRed)

{-| This module contains all the graphics elements of the polymny UI.

@docs logo, logoBlue, logoRed

-}

import Element exposing (Element)
import Ui.Utils as Ui


{-| Helper to easily create logos.
-}
mkLogo : String -> Element msg
mkLogo path =
    Element.el [ Ui.p 5 ]
        (Element.image [ Ui.hpx 46, Ui.wpx 46 ]
            { src = "/dist/" ++ path
            , description = "The logo of Polymny Studio"
            }
        )


{-| The logo of the polymny application.
-}
logo : Element msg
logo =
    mkLogo "logo.webp"


{-| The blue version of the logo of Polymny.
-}
logoBlue : Element msg
logoBlue =
    mkLogo "logo-blue.webp"


{-| The red version of the logo of Polymny.
-}
logoRed : Element msg
logoRed =
    mkLogo "logo-red.webp"
