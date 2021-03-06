module Ui.Attributes exposing (..)

import Element
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Ui.Colors as Colors


designAttributes : List (Element.Attribute msg)
designAttributes =
    [ Element.width Element.fill
    ]


fullModelAttributes : List (Element.Attribute msg)
fullModelAttributes =
    [ Font.size 15
    , Font.color Colors.dark
    , fontCantarell
    ]


attributesHomeTitle : List (Element.Attribute msg)
attributesHomeTitle =
    [ Element.centerX
    , Element.padding 20
    , Font.size 60
    , Font.bold
    ]


designGosAttributes : List (Element.Attribute msg)
designGosAttributes =
    Element.spacing 9
        :: Element.width Element.fill
        :: Element.alignTop
        :: designAttributes


genericDesignSlideViewAttributes : List (Element.Attribute msg)
genericDesignSlideViewAttributes =
    [ Background.color Colors.white
    , Element.spacing 5
    , Element.padding 5
    , Border.rounded 5
    , Border.dashed
    , Border.width 3
    ]


fontRoboto : Element.Attribute msg
fontRoboto =
    Font.family
        [ Font.external
            { name = "Roboto"
            , url = "https://fonts.googleapis.com/css?family=Roboto"
            }
        , Font.sansSerif
        ]


fontAnton : Element.Attribute msg
fontAnton =
    Font.family
        [ Font.external
            { name = "Anton"
            , url = "https://fonts.googleapis.com/css2?family=Anton&display=swap"
            }
        , Font.sansSerif
        ]


fontCantarell : Element.Attribute msg
fontCantarell =
    Font.family
        [ Font.typeface "Cantarell"
        , Font.sansSerif
        ]


fontOpenSans : Element.Attribute msg
fontOpenSans =
    Font.family
        [ Font.typeface "Open Sans"
        , Font.sansSerif
        ]


fontMono : Element.Attribute msg
fontMono =
    Font.family
        [ Font.external
            { name = "Roboto mono"
            , url = "https://fonts.googleapis.com/css2?family=Roboto+Mono:wght@100;300&display=swap"
            }
        , Font.monospace
        ]
