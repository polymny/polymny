module Ui.Graphics exposing (logo)

{-| This module contains all the graphics elements of the polymny UI.

@docs logo

-}

import Element exposing (Element)
import Ui.Utils as Ui


{-| The logo of the polymny application.
-}
logo : Element msg
logo =
    Element.el [ Ui.p 5 ]
        (Element.image [ Ui.hpx 46, Ui.wpx 46 ]
            { src = "/dist/logo.webp"
            , description = "The logo of Polymny Studio"
            }
        )
