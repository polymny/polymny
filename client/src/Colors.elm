module Colors exposing
    ( black
    , brandeisBlue
    , brightGreen
    , danger
    , dangerDark
    , dangerLight
    , grey
    , link
    , menthol
    , primary
    , primaryDark
    , primaryLight
    , purpleHeart
    , purplePlum
    , success
    , successDark
    , successLight
    , vividCerulean
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


blackColor : Color
blackColor =
    Color.fromRGB ( 0, 0, 0 )


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


black : Element.Color
black =
    colorToUi blackColor


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



-- Try palette : https://www.schemecolor.com/bright-blue-green-and-purple.php


brandeisBlueColor : Color
brandeisBlueColor =
    Color.fromRGB ( 0, 99, 255 )


brandeisBlue : Element.Color
brandeisBlue =
    colorToUi brandeisBlueColor


vividCeruleanColor : Color
vividCeruleanColor =
    Color.fromRGB ( 0, 164, 255 )


vividCerulean : Element.Color
vividCerulean =
    colorToUi vividCeruleanColor


mentholColor : Color
mentholColor =
    Color.fromRGB ( 176, 255, 151 )


menthol : Element.Color
menthol =
    colorToUi mentholColor


brightGreenColor : Color
brightGreenColor =
    Color.fromRGB ( 99, 252, 1 )


brightGreen : Element.Color
brightGreen =
    colorToUi brightGreenColor


purpleHeartColor : Color
purpleHeartColor =
    Color.fromRGB ( 104, 53, 155 )


purpleHeart : Element.Color
purpleHeart =
    colorToUi purpleHeartColor


purplePlumColor : Color
purplePlumColor =
    Color.fromRGB ( 153, 79, 179 )


purplePlum : Element.Color
purplePlum =
    colorToUi purplePlumColor
