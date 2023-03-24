module Ui.Utils exposing
    ( ar, al, at, ab
    , wf, wfp, wpx, hf, hfp, hpx
    , s, pl, pr, pt, pb, py, px, p
    , bl, br, bt, bb, by, bx, b
    , rbl, rbr, rtl, rtr, rl, rr, rb, rt, r
    , cx, cy
    , shrink, paragraph
    , id, class, sortAttributes, tooltip, zIndex
    )

{-| This module contains shortcuts to very used elm-ui values, as well as some other utility functions.


# Align aliases

@docs ar, al, at, ab


# Width and height aliases

@docs wf, wfp, wpx, hf, hfp, hpx


# Spacing and padding aliases

@docs s, pl, pr, pt, pb, py, px, p


# Border aliases

@docs bl, br, bt, bb, by, bx, b


# Rounded corners aliases

@docs rbl, rbr, rtl, rtr, rl, rr, rb, rt, r


# Centering aliases

@docs cx, cy


# Text utilities

@docs shrink, paragraph


# HTML utilities

@docs id, class, sortAttributes, tooltip, zIndex

-}

import Element exposing (Element)
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Ui.Colors as Colors


{-| An alias for align right.
-}
ar : Element.Attribute msg
ar =
    Element.alignRight


{-| An alias for align left.
-}
al : Element.Attribute msg
al =
    Element.alignLeft


{-| An alias for align top.
-}
at : Element.Attribute msg
at =
    Element.alignTop


{-| An alias for align bottom.
-}
ab : Element.Attribute msg
ab =
    Element.alignBottom


{-| An alias for `Element.width Element.fill`.
-}
wf : Element.Attribute msg
wf =
    Element.width Element.fill


{-| An alias for `Element.width (Element.fillPortion x)`.
-}
wfp : Int -> Element.Attribute msg
wfp x =
    Element.width (Element.fillPortion x)


{-| An alias for `Element.width (Element.px x)`
-}
wpx : Int -> Element.Attribute msg
wpx x =
    Element.width (Element.px x)


{-| An alias for `Element.height Element.fill`.
-}
hf : Element.Attribute msg
hf =
    Element.height Element.fill


{-| An alias for `Element.height (Element.fillPortion x)`.
-}
hfp : Int -> Element.Attribute msg
hfp x =
    Element.height (Element.fillPortion x)


{-| An alias for `Element.height (Element.px x)`.
-}
hpx : Int -> Element.Attribute msg
hpx x =
    Element.height (Element.px x)


{-| An alias for Element.spacing.
-}
s : Int -> Element.Attribute msg
s x =
    Element.spacing x


{-| An alias to have padding only on the left.
-}
pl : Int -> Element.Attribute msg
pl x =
    Element.paddingEach { left = x, right = 0, top = 0, bottom = 0 }


{-| An alias to have padding only on the right.
-}
pr : Int -> Element.Attribute msg
pr x =
    Element.paddingEach { left = 0, right = x, top = 0, bottom = 0 }


{-| An alias to have padding only on the top.
-}
pt : Int -> Element.Attribute msg
pt x =
    Element.paddingEach { left = 0, right = 0, top = x, bottom = 0 }


{-| An alias to have padding only on the bottom.
-}
pb : Int -> Element.Attribute msg
pb x =
    Element.paddingEach { left = 0, right = 0, top = 0, bottom = x }


{-| An alias to have padding only on the top and bottom.
-}
py : Int -> Element.Attribute msg
py x =
    Element.paddingEach { left = 0, right = 0, top = x, bottom = x }


{-| An alias to have padding only on the left and right.
-}
px : Int -> Element.Attribute msg
px x =
    Element.paddingEach { left = x, right = x, top = 0, bottom = 0 }


{-| An alias to have padding everywhere.
-}
p : Int -> Element.Attribute msg
p x =
    Element.paddingEach { left = x, right = x, top = x, bottom = x }


{-| An alias to have border only on the left.
-}
bl : Int -> Element.Attribute msg
bl x =
    Border.widthEach { left = x, right = 0, top = 0, bottom = 0 }


{-| An alias to have border only on the right.
-}
br : Int -> Element.Attribute msg
br x =
    Border.widthEach { left = 0, right = x, top = 0, bottom = 0 }


{-| An alias to have border only on the top.
-}
bt : Int -> Element.Attribute msg
bt x =
    Border.widthEach { left = 0, right = 0, top = x, bottom = 0 }


{-| An alias to have border only on the bottom.
-}
bb : Int -> Element.Attribute msg
bb x =
    Border.widthEach { left = 0, right = 0, top = 0, bottom = x }


{-| An alias to have border only on the top and bottom.
-}
by : Int -> Element.Attribute msg
by x =
    Border.widthEach { left = 0, right = 0, top = x, bottom = x }


{-| An alias to have border only on the left and right.
-}
bx : Int -> Element.Attribute msg
bx x =
    Border.widthEach { left = x, right = x, top = 0, bottom = 0 }


{-| An alias to have border everywhere.
-}
b : Int -> Element.Attribute msg
b x =
    Border.widthEach { left = x, right = x, top = x, bottom = x }


{-| An alias to have rounded corners only on the bottom left.
-}
rbl : Int -> Element.Attribute msg
rbl x =
    Border.roundEach { bottomLeft = x, bottomRight = 0, topLeft = 0, topRight = 0 }


{-| An alias to have rounded corners only on the bottom right.
-}
rbr : Int -> Element.Attribute msg
rbr x =
    Border.roundEach { bottomLeft = 0, bottomRight = x, topLeft = 0, topRight = 0 }


{-| An alias to have rounded corners only on the top left.
-}
rtl : Int -> Element.Attribute msg
rtl x =
    Border.roundEach { bottomLeft = 0, bottomRight = 0, topLeft = x, topRight = 0 }


{-| An alias to have rounded corners only on the top right.
-}
rtr : Int -> Element.Attribute msg
rtr x =
    Border.roundEach { bottomLeft = 0, bottomRight = 0, topLeft = 0, topRight = x }


{-| An alias to have rounded corners only on the left.
-}
rl : Int -> Element.Attribute msg
rl x =
    Border.roundEach { bottomLeft = x, bottomRight = 0, topLeft = x, topRight = 0 }


{-| An alias to have rounded corners only on the right.
-}
rr : Int -> Element.Attribute msg
rr x =
    Border.roundEach { bottomLeft = 0, bottomRight = x, topLeft = 0, topRight = x }


{-| An alias to have rounded corners only on the top.
-}
rt : Int -> Element.Attribute msg
rt x =
    Border.roundEach { bottomLeft = 0, bottomRight = 0, topLeft = x, topRight = x }


{-| An alias to have rounded corners only on the bottom.
-}
rb : Int -> Element.Attribute msg
rb x =
    Border.roundEach { bottomLeft = x, bottomRight = x, topLeft = 0, topRight = 0 }


{-| An alias to have rounded corners everywhere.
-}
r : Int -> Element.Attribute msg
r x =
    Border.rounded x


{-| An alias for `Element.centerX`
-}
cx : Element.Attribute msg
cx =
    Element.centerX


{-| An alias for `Element.centerY`
-}
cy : Element.Attribute msg
cy =
    Element.centerY


{-| Shrinks a text to a certain max number of characters.
-}
shrink : Int -> String -> String
shrink length string =
    if String.length string > length then
        string |> String.slice 0 length |> String.trim |> (\x -> x ++ " ...")

    else
        string


{-| Helper to create a paragraph with a single text.
-}
paragraph : List (Element.Attribute msg) -> String -> Element msg
paragraph attr text =
    Element.paragraph attr [ Element.text text ]


{-| An alias for an HTML id.
-}
id : String -> Element.Attribute msg
id name =
    Element.htmlAttribute (Html.Attributes.id name)


{-| An alias for an HTML class.
-}
class : String -> Element.Attribute msg
class name =
    Element.htmlAttribute (Html.Attributes.class name)


{-| Sort attributes to inner, outer and font.
-}
sortAttributes : List (Element.Attribute msg) -> ( List (Element.Attribute msg), List (Element.Attribute msg), List (Element.Attribute msg) )
sortAttributes attributes =
    let
        innerAttributes : List (Element.Attribute msg)
        innerAttributes =
            [ p 12
            , p 2
            , Border.rounded 5
            , Border.rounded 100
            ]

        outerAttributes : List (Element.Attribute msg)
        outerAttributes =
            [ Border.rounded 5
            , Border.rounded 100
            , wf
            ]

        fontAttributes : List (Element.Attribute msg)
        fontAttributes =
            [ Font.color Colors.green2
            , Font.color Colors.white
            , Font.bold
            ]
    in
    ( List.filter (\x -> List.member x innerAttributes) attributes
    , List.filter (\x -> List.member x outerAttributes) attributes
    , List.filter (\x -> List.member x fontAttributes) attributes
    )


{-| A helper to create a tooltip.
-}
tooltip : String -> Element.Attribute msg
tooltip text =
    Element.htmlAttribute (Html.Attributes.title text)


{-| A helper to add a z-index.
-}
zIndex : Int -> Element.Attribute msg
zIndex index =
    Element.htmlAttribute (Html.Attributes.style "z-index" (String.fromInt index))
