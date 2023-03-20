module Ui.Colors exposing
    ( green1, green2, green3, yellow, blue, red, orange, orangeLight, greenLight, white, black, alpha, alphaColor, transparent, grey, greyBackground, greyFont, greyFontDisabled, greyBorder, tableBackground, colorToString
    , redLight
    )

{-| This module contains all the color definitions that will be used in the app.

@docs green1, green2, green3, yellow, blue, red, redLigth, orange, orangeLight, greenLight, white, black, alpha, alphaColor, transparent, grey, greyBackground, greyFont, greyFontDisabled, greyBorder, tableBackground, colorToString

-}

import Element
import Json.Decode exposing (int)


{-| The dark green color from Polymny logo.
-}
green1 : Element.Color
green1 =
    Element.rgb255 38 150 60


{-| The medium green color from Polymny logo.
-}
green2 : Element.Color
green2 =
    Element.rgb255 127 204 40


{-| The bright green color from Polymny logo.
-}
green3 : Element.Color
green3 =
    Element.rgb255 202 227 16


{-| The yellow color from Polymny logo.
-}
yellow : Element.Color
yellow =
    Element.rgb255 253 210 40


{-| Pure blue.
-}
blue : Element.Color
blue =
    Element.rgb255 0 0 255


{-| Pure red.
-}
red : Element.Color
red =
    Element.rgb255 255 0 0


{-| A lightened red.
-}
redLight : Element.Color
redLight =
    Element.rgb255 255 204 204


{-| An orange color.
-}
orange : Element.Color
orange =
    Element.rgb255 255 165 0


{-| A lightened orange.
-}
orangeLight : Element.Color
orangeLight =
    Element.rgb255 255 237 204


{-| A lightened green 2.
-}
greenLight : Element.Color
greenLight =
    Element.rgb255 201 245 204


{-| A pure white.
-}
white : Element.Color
white =
    Element.rgb255 255 255 255


{-| A pure black.
-}
black : Element.Color
black =
    Element.rgb255 0 0 0


{-| A pure transparent.
-}
transparent : Element.Color
transparent =
    Element.rgba255 0 0 0 0


{-| A transparent black color.
-}
alpha : Float -> Element.Color
alpha value =
    Element.rgba 0 0 0 value


{-| Changes the alpha on a color.
-}
alphaColor : Float -> Element.Color -> Element.Color
alphaColor value color =
    color |> Element.toRgb |> (\x -> { x | alpha = value }) |> Element.fromRgb


{-| This function gives shades of grey.

The parameter givs pure white with 0 as parameter, and pure black with 9 or more.

-}
grey : Int -> Element.Color
grey shade =
    case shade of
        0 ->
            Element.rgb255 0 0 0

        1 ->
            Element.rgb255 18 18 18

        2 ->
            Element.rgb255 36 36 36

        3 ->
            Element.rgb255 54 54 54

        4 ->
            Element.rgb255 74 74 74

        5 ->
            Element.rgb255 181 181 181

        6 ->
            Element.rgb255 219 219 219

        7 ->
            Element.rgb255 245 245 245

        8 ->
            Element.rgb255 250 250 250

        _ ->
            Element.rgb255 255 255 255


{-| This color is the color used for backgrounds to avoid them being too bright.
-}
greyBackground : Element.Color
greyBackground =
    grey 7


{-| This color is the color used for fonts to avoid them being too dark.
-}
greyFont : Element.Color
greyFont =
    grey 2


{-| This color can be used for the border of elements.
-}
greyBorder : Element.Color
greyBorder =
    grey 5


{-| This color can be used for disabled text.
-}
greyFontDisabled : Element.Color
greyFontDisabled =
    grey 5


{-| This color is the background of the dark lines of tables.
-}
tableBackground : Element.Color
tableBackground =
    Element.rgb 228 233 230


{-| Convers an element color to a css string.
-}
colorToString : Element.Color -> String
colorToString color =
    let
        rgb =
            Element.toRgb color

        r =
            floor (255 * rgb.red) |> String.fromInt

        g =
            floor (255 * rgb.green) |> String.fromInt

        b =
            floor (255 * rgb.blue) |> String.fromInt
    in
    "rgb(" ++ r ++ "," ++ g ++ "," ++ b ++ ")"
