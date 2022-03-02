module Ui.Utils exposing
    ( wf, wfp, wpx, hf, hfp, hpx
    , pl, pr, pt, pb, py, px, p
    , bl, br, bt, bb, by, bx, b
    , cx, cy
    , shrink
    )

{-| This module contains shortcuts to very used elm-ui values, as well as some other utility functions.


# Width and height aliases

@docs wf, wfp, wpx, hf, hfp, hpx


# Padding aliases

@docs pl, pr, pt, pb, py, px, p


# Border aliases

@docs bl, br, bt, bb, by, bx, b


# Centering aliases

@docs cx, cy


# Text utilities

@docs shrink

-}

import Element
import Element.Border as Border
import Material.Icons.Types exposing (Icon)


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
