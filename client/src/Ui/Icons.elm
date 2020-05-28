module Ui.Icons exposing
    ( add
    , cancel
    , clear
    , edit
    , trash
    )

import Element exposing (Element)
import FontAwesome
import Html


trash : Element msg
trash =
    Element.html
        (Html.div
            []
            [ FontAwesome.iconWithOptions
                FontAwesome.trash
                FontAwesome.Solid
                [ FontAwesome.Size (FontAwesome.Mult 2) ]
                []
            ]
        )


edit : Element msg
edit =
    Element.html
        (Html.div
            []
            [ FontAwesome.iconWithOptions
                FontAwesome.edit
                FontAwesome.Solid
                [ FontAwesome.Size (FontAwesome.Mult 1) ]
                []
            ]
        )


clear : Element msg
clear =
    Element.html
        (Html.div
            []
            [ FontAwesome.iconWithOptions
                FontAwesome.eraser
                FontAwesome.Solid
                [ FontAwesome.Size (FontAwesome.Mult 1) ]
                []
            ]
        )


add : Element msg
add =
    Element.html
        (Html.div
            []
            [ FontAwesome.iconWithOptions
                FontAwesome.plus
                FontAwesome.Solid
                [ FontAwesome.Size (FontAwesome.Mult 1) ]
                []
            ]
        )


cancel : Element msg
cancel =
    Element.html
        (Html.div
            []
            [ FontAwesome.iconWithOptions
                FontAwesome.windowClose
                FontAwesome.Regular
                [ FontAwesome.Size (FontAwesome.Mult 1) ]
                []
            ]
        )
