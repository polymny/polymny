module Ui.Colors exposing
    ( artEvening
    , artIrises
    , artStarryNight
    , artSunFlowers
    , black
    , brandeisBlue
    , brightGreen
    , danger
    , dangerDark
    , dangerLight
    , grey
    , greyDark
    , greyLight
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
    , whiteDark
    , whiteDarker
    )

import Element
import SolidColor exposing (SolidColor)


colorToUi : SolidColor -> Element.Color
colorToUi color =
    let
        ( r, g, b ) =
            SolidColor.toRGB color
    in
    Element.rgb255 (floor r) (floor g) (floor b)


greyValue : Float
greyValue =
    175


greyColor : SolidColor
greyColor =
    SolidColor.fromRGB ( greyValue, greyValue, greyValue )


whiteColor : SolidColor
whiteColor =
    SolidColor.fromRGB ( 255, 255, 255 )


blackColor : SolidColor
blackColor =
    SolidColor.fromRGB ( 0, 0, 0 )


primaryColor : SolidColor
primaryColor =
    irisesColor


successColor : SolidColor
successColor =
    SolidColor.fromRGB ( 40, 167, 69 )


warningColor : SolidColor
warningColor =
    SolidColor.fromRGB ( 255, 221, 87 )


dangerColor : SolidColor
dangerColor =
    SolidColor.fromRGB ( 241, 70, 104 )


lightParameter : Float
lightParameter =
    30


primaryLightColor : SolidColor
primaryLightColor =
    SolidColor.addLightness lightParameter primaryColor


successLightColor : SolidColor
successLightColor =
    SolidColor.addLightness lightParameter successColor


warningLightColor : SolidColor
warningLightColor =
    SolidColor.addLightness lightParameter warningColor


dangerLightColor : SolidColor
dangerLightColor =
    SolidColor.addLightness lightParameter dangerColor


greyLightColor : SolidColor
greyLightColor =
    SolidColor.addLightness lightParameter greyColor


darkParameter : Float
darkParameter =
    -30


primaryDarkColor : SolidColor
primaryDarkColor =
    SolidColor.addLightness darkParameter primaryColor


successDarkColor : SolidColor
successDarkColor =
    SolidColor.addLightness darkParameter successColor


warningDarkColor : SolidColor
warningDarkColor =
    SolidColor.addLightness darkParameter warningColor


dangerDarkColor : SolidColor
dangerDarkColor =
    SolidColor.addLightness darkParameter dangerColor


greyDarkColor : SolidColor
greyDarkColor =
    SolidColor.addLightness darkParameter greyColor


whiteDarkColor : SolidColor
whiteDarkColor =
    SolidColor.fromRGB ( 250, 251, 252 )


whiteDarkerColor : SolidColor
whiteDarkerColor =
    SolidColor.fromRGB ( 234, 236, 239 )


grey : Element.Color
grey =
    colorToUi greyColor


greyLight : Element.Color
greyLight =
    colorToUi greyLightColor


greyDark : Element.Color
greyDark =
    colorToUi greyDarkColor


white : Element.Color
white =
    colorToUi whiteColor


whiteDark : Element.Color
whiteDark =
    colorToUi whiteDarkColor


whiteDarker : Element.Color
whiteDarker =
    colorToUi whiteDarkerColor


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


brandeisBlueColor : SolidColor
brandeisBlueColor =
    SolidColor.fromRGB ( 0, 99, 255 )


brandeisBlue : Element.Color
brandeisBlue =
    colorToUi brandeisBlueColor


vividCeruleanColor : SolidColor
vividCeruleanColor =
    SolidColor.fromRGB ( 0, 164, 255 )


vividCerulean : Element.Color
vividCerulean =
    colorToUi vividCeruleanColor


mentholColor : SolidColor
mentholColor =
    SolidColor.fromRGB ( 176, 255, 151 )


menthol : Element.Color
menthol =
    colorToUi mentholColor


brightGreenColor : SolidColor
brightGreenColor =
    SolidColor.fromRGB ( 99, 252, 1 )


brightGreen : Element.Color
brightGreen =
    colorToUi brightGreenColor


purpleHeartColor : SolidColor
purpleHeartColor =
    SolidColor.fromRGB ( 104, 53, 155 )


purpleHeart : Element.Color
purpleHeart =
    colorToUi purpleHeartColor


purplePlumColor : SolidColor
purplePlumColor =
    SolidColor.fromRGB ( 153, 79, 179 )


purplePlum : Element.Color
purplePlum =
    colorToUi purplePlumColor



-- Art history https://www.canva.com/learn/website-color-schemes/


sunFlowersColor : SolidColor
sunFlowersColor =
    SolidColor.fromRGB ( 255, 204, 0 )


artSunFlowers : Element.Color
artSunFlowers =
    colorToUi sunFlowersColor


starryNightColor : SolidColor
starryNightColor =
    SolidColor.fromRGB ( 3, 118, 180 )


artStarryNight : Element.Color
artStarryNight =
    colorToUi starryNightColor


irisesColor : SolidColor
irisesColor =
    SolidColor.fromRGB ( 0, 120, 72 )


artIrises : Element.Color
artIrises =
    colorToUi irisesColor


eveningColor : SolidColor
eveningColor =
    SolidColor.fromRGB ( 38, 34, 40 )


artEvening : Element.Color
artEvening =
    colorToUi eveningColor
