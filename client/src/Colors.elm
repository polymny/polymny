module Colors exposing (..)

import Color exposing (Color)
import Element exposing (Element)


colorToUi : Color -> Element.Color
colorToUi color =
    let
        ( r, g, b ) =
            Color.toRGB color
    in
    Element.rgb255 (floor r) (floor g) (floor b)


greyValue =
    175


greyColor =
    Color.fromRGB ( greyValue, greyValue, greyValue )


whiteColor =
    Color.fromRGB ( 255, 255, 255 )


primaryColor =
    Color.fromRGB ( 50, 115, 220 )


successColor =
    Color.fromRGB ( 40, 167, 69 )


warningColor =
    Color.fromRGB ( 255, 221, 87 )


dangerColor =
    Color.fromRGB ( 241, 70, 104 )


lightParameter =
    30


primaryLightColor =
    Color.addLightness lightParameter primaryColor


successLightColor =
    Color.addLightness lightParameter successColor


warningLightColor =
    Color.addLightness lightParameter warningColor


dangerLightColor =
    Color.addLightness lightParameter dangerColor


darkParameter =
    -30


primaryDarkColor =
    Color.addLightness darkParameter primaryColor


successDarkColor =
    Color.addLightness darkParameter successColor


warningDarkColor =
    Color.addLightness darkParameter warningColor


dangerDarkColor =
    Color.addLightness darkParameter dangerColor


grey =
    colorToUi greyColor


white =
    colorToUi whiteColor


primary =
    colorToUi primaryColor


success =
    colorToUi successColor


warning =
    colorToUi warningColor


danger =
    colorToUi dangerColor


primaryLight =
    colorToUi primaryLightColor


successLight =
    colorToUi successLightColor


warningLight =
    colorToUi warningLightColor


dangerLight =
    colorToUi dangerLightColor


primaryDark =
    colorToUi primaryDarkColor


successDark =
    colorToUi successDarkColor


warningDark =
    colorToUi warningDarkColor


dangerDark =
    colorToUi dangerDarkColor
