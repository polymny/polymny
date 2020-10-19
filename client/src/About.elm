module About exposing (view)

import Core.Types as Core
import Element exposing (Element)
import Element.Font as Font
import Ui.Ui as Ui


viewLogo : Int -> String -> Element Core.Msg
viewLogo size url =
    Element.image [ Element.centerX, Element.width (Element.px size) ] { src = url, description = "One desc" }


view : Element Core.Msg
view =
    Element.column [ Element.centerX, Element.padding 10 ]
        [ viewLogo 200 "/dist/polymny.png"
        , Element.textColumn
            [ Element.spacing 10, Element.padding 10 ]
            [ Element.paragraph [ Font.center, Font.italic ]
                [ Element.text "Polymny is a web based tool for easy production of educational videos."
                ]
            , Element.paragraph [ Font.center, Font.italic ]
                [ Element.text
                    "You just need some slides in PDF and a web browser!"
                ]
            , Element.paragraph [ Font.center ]
                [ Element.text "Polymny studio is proudly written in "
                , Element.link
                    []
                    { url = "https://www.rust-lang.org/"
                    , label = Element.el [ Font.bold ] <| Element.text "Rust"
                    }
                , Element.text " and "
                , Element.link
                    []
                    { url = "https://elm-lang.org/"
                    , label = Element.el [ Font.bold ] <| Element.text "Elm"
                    }
                ]
            , Element.paragraph [ Font.center ] [ Element.text "by T. Forgione, N. Bertrand, A. Carlier and V. Charvillat" ]
            ]
        , Element.el [ Element.alignRight ] (Ui.primaryButton (Just Core.AboutClosed) "Fermer")
        ]
