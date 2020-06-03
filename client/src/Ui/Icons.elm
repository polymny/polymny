module Ui.Icons exposing
    ( add
    , camera
    , cancel
    , clear
    , edit
    , movie
    , trash
    )

import Element exposing (Element)
import FontAwesome
import Html


buttonFromIcon : FontAwesome.Icon -> Element msg
buttonFromIcon icon =
    Element.html
        (Html.div
            []
            [ FontAwesome.iconWithOptions
                icon
                FontAwesome.Solid
                [ FontAwesome.Size (FontAwesome.Mult 2) ]
                []
            ]
        )


trash : Element msg
trash =
    buttonFromIcon FontAwesome.trash


edit : Element msg
edit =
    buttonFromIcon FontAwesome.edit


clear : Element msg
clear =
    buttonFromIcon FontAwesome.eraser


add : Element msg
add =
    buttonFromIcon FontAwesome.plus


cancel : Element msg
cancel =
    buttonFromIcon FontAwesome.windowClose


camera : Element msg
camera =
    buttonFromIcon FontAwesome.video


movie : Element msg
movie =
    buttonFromIcon FontAwesome.film
