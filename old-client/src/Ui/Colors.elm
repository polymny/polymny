module Ui.Colors exposing (..)

import Element
import SolidColor exposing (SolidColor)


toUi : SolidColor -> Element.Color
toUi color =
    let
        ( r, g, b ) =
            SolidColor.toRGB color
    in
    Element.rgb255 (floor r) (floor g) (floor b)


navbar : Element.Color
navbar =
    SolidColor.fromRGB ( 72, 199, 116 ) |> toUi


navbarOver : Element.Color
navbarOver =
    SolidColor.fromRGB ( 58, 187, 103 ) |> toUi


white : Element.Color
white =
    SolidColor.fromHSL ( 0, 0, 100 ) |> toUi


black : Element.Color
black =
    SolidColor.fromHSL ( 0, 0, 4 ) |> toUi


light : Element.Color
light =
    SolidColor.fromHSL ( 0, 0, 96 ) |> toUi


dark : Element.Color
dark =
    SolidColor.fromHSL ( 0, 0, 21 ) |> toUi


primary : Element.Color
primary =
    SolidColor.fromHSL ( 171, 100, 41 ) |> toUi


link : Element.Color
link =
    SolidColor.fromHSL ( 217, 71, 53 ) |> toUi


info : Element.Color
info =
    SolidColor.fromHSL ( 204, 86, 53 ) |> toUi


success : Element.Color
success =
    SolidColor.fromHSL ( 141, 71, 48 ) |> toUi


warning : Element.Color
warning =
    SolidColor.fromHSL ( 48, 100, 67 ) |> toUi


danger : Element.Color
danger =
    SolidColor.fromHSL ( 348, 100, 61 ) |> toUi


blackBis : Element.Color
blackBis =
    SolidColor.fromHSL ( 0, 0, 7 ) |> toUi


blackTer : Element.Color
blackTer =
    SolidColor.fromHSL ( 0, 0, 14 ) |> toUi


greyDarker : Element.Color
greyDarker =
    SolidColor.fromHSL ( 0, 0, 21 ) |> toUi


greyDark : Element.Color
greyDark =
    SolidColor.fromHSL ( 0, 0, 29 ) |> toUi


grey : Element.Color
grey =
    SolidColor.fromHSL ( 0, 0, 48 ) |> toUi


greyLight : Element.Color
greyLight =
    SolidColor.fromHSL ( 0, 0, 71 ) |> toUi


greyLighter : Element.Color
greyLighter =
    SolidColor.fromHSL ( 0, 0, 86 ) |> toUi


whiteTer : Element.Color
whiteTer =
    SolidColor.fromHSL ( 0, 0, 96 ) |> toUi


whiteBis : Element.Color
whiteBis =
    SolidColor.fromHSL ( 0, 0, 98 ) |> toUi


primaryLight : Element.Color
primaryLight =
    SolidColor.fromHSL ( 171, 100, 96 ) |> toUi


linkLight : Element.Color
linkLight =
    SolidColor.fromHSL ( 219, 70, 96 ) |> toUi


infoLight : Element.Color
infoLight =
    SolidColor.fromHSL ( 206, 70, 96 ) |> toUi


successLight : Element.Color
successLight =
    SolidColor.fromHSL ( 142, 52, 96 ) |> toUi


warningLight : Element.Color
warningLight =
    SolidColor.fromHSL ( 48, 100, 96 ) |> toUi


dangerLight : Element.Color
dangerLight =
    SolidColor.fromHSL ( 347, 90, 96 ) |> toUi


primaryDark : Element.Color
primaryDark =
    SolidColor.fromHSL ( 171, 100, 29 ) |> toUi


linkDark : Element.Color
linkDark =
    SolidColor.fromHSL ( 217, 71, 45 ) |> toUi


infoDark : Element.Color
infoDark =
    SolidColor.fromHSL ( 204, 71, 39 ) |> toUi


successDark : Element.Color
successDark =
    SolidColor.fromHSL ( 141, 53, 31 ) |> toUi


warningDark : Element.Color
warningDark =
    SolidColor.fromHSL ( 48, 100, 29 ) |> toUi


dangerDark : Element.Color
dangerDark =
    SolidColor.fromHSL ( 348, 86, 43 ) |> toUi


darkTransparent : Element.Color
darkTransparent =
    Element.rgba255 0 0 0 0.8
