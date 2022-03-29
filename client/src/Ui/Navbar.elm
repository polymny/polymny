module Ui.Navbar exposing (navbar, bottombar)

{-| This module contains the definition for the nav bar of the polymny app.

@docs navbar, bottombar

-}

import Config exposing (Config)
import Data.User exposing (User)
import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Lang
import Route
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
        [ Background.color Colors.green2, Ui.wf ]
        [ Ui.navigationElement (Ui.Route Route.Home) [] Ui.logo
        , Element.row [ Font.size 20, Element.alignRight, Element.spacing 10 ]
            [ Maybe.map .username user |> Maybe.map Element.text |> Maybe.withDefault Element.none
            , Ui.secondary [ Ui.pr 10 ] { action = Ui.None, label = Strings.loginLogout lang }
            ]
        ]


{-| This function creates the bottom bar of the application.
-}
bottombar : Maybe Config -> Element msg
bottombar config =
    Element.row
        [ Background.color (Colors.grey 3)
        , Font.color Colors.greyBackground
        , Ui.wf
        , Ui.s 20
        , Ui.p 15
        , Font.size 16
        , Font.bold
        ]
        [ Ui.link
            [ Element.mouseOver [ Font.color Colors.greyBackground ] ]
            { label = "contacter@polymny.studio"
            , action = Ui.Route (Route.Custom "mailto:contacter@polymny.studio")
            }
        , Ui.link [ Ui.ar, Element.mouseOver [ Font.color Colors.greyBackground ] ]
            { label = "License GNU Affero V3"
            , action = Ui.Route (Route.Custom "https://github.com/polymny/polymny/blob/master/LICENSE")
            }
        , Ui.link [ Ui.ar, Element.mouseOver [ Font.color Colors.greyBackground ] ]
            { label = "Conditions d'utilisation"
            , action = Ui.Route (Route.Custom "https://polymny.studio/cgu/")
            }
        , Ui.link [ Ui.ar, Element.mouseOver [ Font.color Colors.greyBackground ] ]
            { label = "Source"
            , action = Ui.Route (Route.Custom "https://github.com/polymny/polymny")
            }
        , Ui.link [ Ui.ar, Element.mouseOver [ Font.color Colors.greyBackground ] ]
            { label = "Langue"
            , action = Ui.None
            }
        , config
            |> Maybe.map .serverConfig
            |> Maybe.map .version
            |> Maybe.map (\x -> Element.text ("Version " ++ x))
            |> Maybe.withDefault Element.none
        , config
            |> Maybe.map .serverConfig
            |> Maybe.andThen .commit
            |> Maybe.map (\x -> Element.text ("Commit " ++ x))
            |> Maybe.withDefault Element.none
        ]
