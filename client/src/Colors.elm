module Colors exposing
    ( danger
    , dangerDark
    , dangerLight
    , grey
    , link
    , primary
    , primaryDark
    , primaryLight
    , success
    , successDark
    , successLight
    , warning
    , warningDark
    , warningLight
    , white
    )

import Color exposing (Color)
import Element


colorToUi : Color -> Element.Color
colorToUi color =
    let
        ( r, g, b ) =
            Color.toRGB color
    in
    Element.rgb255 (floor r) (floor g) (floor b)


greyValue : Float
greyValue =
    175


greyColor : Color
greyColor =
    Color.fromRGB ( greyValue, greyValue, greyValue )


whiteColor : Color
whiteColor =
    Color.fromRGB ( 255, 255, 255 )


primaryColor : Color
primaryColor =
    Color.fromRGB ( 50, 115, 220 )


successColor : Color
successColor =
    Color.fromRGB ( 40, 167, 69 )


warningColor : Color
warningColor =
    Color.fromRGB ( 255, 221, 87 )


dangerColor : Color
dangerColor =
    Color.fromRGB ( 241, 70, 104 )


lightParameter : Float
lightParameter =
    30


primaryLightColor : Color
primaryLightColor =
    Color.addLightness lightParameter primaryColor


successLightColor : Color
successLightColor =
    Color.addLightness lightParameter successColor


warningLightColor : Color
warningLightColor =
    Color.addLightness lightParameter warningColor


dangerLightColor : Color
dangerLightColor =
    Color.addLightness lightParameter dangerColor


darkParameter : Float
darkParameter =
    -30


primaryDarkColor : Color
primaryDarkColor =
    Color.addLightness darkParameter primaryColor


successDarkColor : Color
successDarkColor =
    Color.addLightness darkParameter successColor


warningDarkColor : Color
warningDarkColor =
    Color.addLightness darkParameter warningColor


dangerDarkColor : Color
dangerDarkColor =
    Color.addLightness darkParameter dangerColor


grey : Element.Color
grey =
    colorToUi greyColor


white : Element.Color
white =
    colorToUi whiteColor


primary : Element.Color
primary =
    colorToUi primaryColor


success : Element.Color
success =
    colorToUi successColor


warning : Element.Color
warning =
    colorToUi warningColor


danger : Element.Color
danger =
    colorToUi dangerColor


primaryLight : Element.Color
primaryLight =
    colorToUi primaryLightColor


successLight : Element.Color
successLight =
    colorToUi successLightColor


warningLight : Element.Color
warningLight =
    colorToUi warningLightColor


dangerLight : Element.Color
dangerLight =
    colorToUi dangerLightColor


primaryDark : Element.Color
primaryDark =
    colorToUi primaryDarkColor


successDark : Element.Color
successDark =
    colorToUi successDarkColor


warningDark : Element.Color
warningDark =
    colorToUi warningDarkColor


dangerDark : Element.Color
dangerDark =
    colorToUi dangerDarkColor


link : Element.Color
link =
    Element.rgb255 0 0 255
