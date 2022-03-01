module Ui.Navbar exposing (navbar)

{-| This module contains the definition for the nav bar of the polymny app.

@docs navbar

-}

import Config exposing (Config)
import Data.User exposing (User)
import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Lang
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Graphics as Ui
import Ui.Utils as Ui


{-| This function creates the navbar of the application.
-}
navbar : Maybe Config -> Maybe User -> Element msg
navbar config user =
    let
        lang =
            Maybe.map .clientState config |> Maybe.map .lang |> Maybe.withDefault Lang.default
    in
    Element.row
        [ Background.color Colors.green1, Ui.wf, Font.color Colors.greyBackground ]
        [ Ui.logo
        , Element.row [ Font.size 20, Element.alignRight, Element.spacing 10 ]
            [ Maybe.map .username user |> Maybe.map Element.text |> Maybe.withDefault Element.none
            , Ui.secondary [ Ui.pr 10 ] { action = Ui.None, label = Strings.loginLogout lang }
            ]
        ]
