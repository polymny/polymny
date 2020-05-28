module Ui.Attributes exposing
    ( capsuleInfoViewAttributes
    , designAttributes
    , designGosAttributes
    , designGosTitleAttributes
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
    [ Element.padding 10
    , Element.spacing 10
    , Element.width Element.fill
    , Border.rounded 5
    , Border.width 2
    ]


fullModelAttributes : List (Element.Attribute msg)
fullModelAttributes =
    [ Font.size 15
    , Background.color Colors.white
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
        :: Element.centerX
        :: Border.rounded 5
        :: Border.width 2
        :: Background.color Colors.white
        :: designAttributes


designGosTitleAttributes : List (Element.Attribute msg)
designGosTitleAttributes =
    [ Element.padding 10
    , Border.color Colors.artIrises
    , Border.rounded 5
    , Border.width 2
    , Element.centerX
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
    , Element.width
        (Element.shrink
            |> Element.minimum 440
            |> Element.maximum 430
        )
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
