module Ui.StaticAssets exposing
    ( videoBonjour
    , videoPlayerView
    )

import Core.Types as Core
import Element exposing (Element)
import Element.Font as Font
import Html
import Html.Attributes


videoLabelAttributes : List (Element.Attribute msg)
videoLabelAttributes =
    [ Element.centerX
    , Font.center
    , Font.medium
    , Font.size 32
    ]


videoPlayerView : String -> String -> Element Core.Msg
videoPlayerView label url =
    Element.column [ Element.centerX ]
        [ Element.el videoLabelAttributes <| Element.paragraph [ Element.centerX ] [ Element.text label ]
        , Element.el [ Element.centerX ] <|
            Element.html
                (Html.iframe
                    [ Html.Attributes.style "posistion" "absolute"
                    , Html.Attributes.style "width" "800px"
                    , Html.Attributes.style "height" "450px"
                    , Html.Attributes.attribute "allowfullscreen" "true"
                    , Html.Attributes.attribute "border" "0px"
                    , Html.Attributes.src url
                    ]
                    []
                )
        ]


videoBonjour : Element Core.Msg
videoBonjour =
    Element.column [ Element.centerX, Element.spacing 15 ]
        [ Element.paragraph [ Element.centerX, Font.center, Font.bold, Font.size 40 ] [ Element.text "Vidéos pédagogiques (extraits)" ]
        , Element.el [ Element.centerX, Element.padding 15 ] <|
            Element.html
                (Html.iframe
                    [ Html.Attributes.style "posistion" "absolute"
                    , Html.Attributes.style "width" "800px"
                    , Html.Attributes.style "height" "450px"
                    , Html.Attributes.attribute "allowfullscreen" "true"
                    , Html.Attributes.attribute "border" "0px"
                    , Html.Attributes.src "https://video.polymny.studio/?v=757685ed-56d0-44b5-9fff-777f8a9e0909/"
                    ]
                    []
                )
        ]
