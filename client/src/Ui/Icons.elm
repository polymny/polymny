module Ui.Icons exposing
    ( add
    , buttonFromIcon
    , camera
    , cancel
    , clear
    , closeLock
    , edit
    , font
    , image
    , menuPoint
    , movie
    , openLock
    , spinner
    , startRecord
    , stopRecord
    , trash
    )

import Element exposing (Element)
import FontAwesome
import Html
import Html.Attributes


buttonFromIcon : FontAwesome.Icon -> Element msg
buttonFromIcon i =
    Element.html
        (Html.div
            []
            [ FontAwesome.iconWithOptions
                i
                FontAwesome.Solid
                []
                --[ FontAwesome.Size (FontAwesome.Mult 2) ]
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


font : Element msg
font =
    buttonFromIcon FontAwesome.font


image : Element msg
image =
    buttonFromIcon FontAwesome.image


spinner : Element msg
spinner =
    Element.html
        (Html.div
            []
            [ FontAwesome.iconWithOptions
                FontAwesome.spinner
                FontAwesome.Solid
                [ FontAwesome.Animation FontAwesome.Spin, FontAwesome.Size FontAwesome.Large ]
                []
            ]
        )


stopRecord : Element msg
stopRecord =
    Element.html
        (Html.div
            [ Html.Attributes.style "padding" "10px" ]
            [ FontAwesome.iconWithOptions
                FontAwesome.camera
                FontAwesome.Solid
                [ FontAwesome.Animation FontAwesome.Pulse, FontAwesome.Size FontAwesome.Large ]
                []
            ]
        )


startRecord : Element msg
startRecord =
    Element.html
        (Html.div
            [ Html.Attributes.style "padding" "10px" ]
            [ FontAwesome.iconWithOptions
                FontAwesome.camera
                FontAwesome.Solid
                [ FontAwesome.Size FontAwesome.Large ]
                []
            ]
        )


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
