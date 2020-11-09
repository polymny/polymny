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


videoTuto : Element Core.Msg
videoTuto =
    videoPlayerView "Débuter avec polymny" "https://video.polymny.studio/?v=b4a86be5-eb21-4681-8716-b96458e60cfe/"


videoTuto2 : Element Core.Msg
videoTuto2 =
    videoPlayerView "Débutey" "https://video.polymny.studio/?v=b4a86be5-eb21-4681-8716-b96458e60cfe/"


videoBonjour : Element Core.Msg
videoBonjour =
    Element.column [ Element.centerX, Element.spacing 15 ]
        [ Element.paragraph [ Element.centerX, Font.center, Font.bold, Font.size 48 ] [ Element.text "Vidéos produites avec polymny: courts extraits" ]
        , Element.el [ Element.centerX, Element.padding 15 ] <|
            Element.html
                (Html.iframe
                    [ Html.Attributes.style "posistion" "absolute"
                    , Html.Attributes.style "width" "800px"
                    , Html.Attributes.style "height" "450px"
                    , Html.Attributes.attribute "allowfullscreen" "true"
                    , Html.Attributes.attribute "border" "0px"
                    , Html.Attributes.src "https://video.polymny.studio/?v=fc259220-b0c0-40aa-a1a3-2a7759745b4c/"
                    ]
                    []
                )
        ]
