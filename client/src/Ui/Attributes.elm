module Ui.Attributes exposing
    ( attributesHomeTitle
    , boxAttributes
    , capsuleInfoViewAttributes
    , designAttributes
    , designGosAttributes
    , designGosTitleAttributes
    , fontMono
    , fontRoboto
    , fullModelAttributes
    , genericDesignSlideViewAttributes
    , uploadViewAttributes
    )

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
    , fontOpenSans
    ]


attributesHomeTitle : List (Element.Attribute msg)
attributesHomeTitle =
    [ Element.centerX
    , Element.padding 20
    , Font.size 60
    , Font.bold
    ]


capsuleInfoViewAttributes : List (Element.Attribute msg)
capsuleInfoViewAttributes =
    Element.centerX
        :: Element.alignTop
        :: Element.spacing 10
        :: Font.color Colors.artEvening
        :: Element.width Element.shrink
        :: designAttributes


designGosAttributes : List (Element.Attribute msg)
designGosAttributes =
    Element.spacing 9
        :: Element.width Element.fill
        :: Element.alignTop
        :: designAttributes


designGosTitleAttributes : List (Element.Attribute msg)
designGosTitleAttributes =
    [ Element.padding 10
    , Border.color Colors.artIrises
    , Border.rounded 5
    , Border.width 2
    , Font.size 20
    ]


genericDesignSlideViewAttributes : List (Element.Attribute msg)
genericDesignSlideViewAttributes =
    [ Background.color Colors.white
    , Element.spacing 5
    , Element.padding 5
    , Border.rounded 5
    , Border.dashed
    , Border.width 3
    ]


uploadViewAttributes : List (Element.Attribute msg)
uploadViewAttributes =
    [ Element.alignLeft
    , Element.width Element.fill
    , Element.spacing 10
    , Element.padding 10
    , Border.rounded 5
    , Border.width 1
    , Border.color Colors.artIrises
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


boxAttributes : List (Element.Attribute msg)
boxAttributes =
    [ Background.color Colors.whiteDark
    , Element.width
        Element.fill
    , Element.padding 10
    , Border.color Colors.whiteDarker
    , Border.rounded 5
    , Border.width 1
    ]
