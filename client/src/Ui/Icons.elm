module Ui.Icons exposing
    ( add
    , camera
    , cancel
    , clear
    , closeLock
    , edit
    , menuPoint
    , movie
    , openLock
    , trash
    )

import Element exposing (Element)
import Element.Background as Background
import FontAwesome
import Html
import Html.Attributes
import Ui.Colors as Colors


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


openLock : Element msg
openLock =
    buttonFromIcon FontAwesome.lockOpen


closeLock : Element msg
closeLock =
    buttonFromIcon FontAwesome.lock


menuPoint : Element msg
menuPoint =
    Element.el [] <|
        Element.html
            (Html.div
                []
                [ FontAwesome.iconWithOptions
                    FontAwesome.ellipsisVertical
                    FontAwesome.Solid
                    [ FontAwesome.Size (FontAwesome.Mult 2) ]
                    []
                ]
            )
