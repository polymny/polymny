module Ui.StaticAssets exposing
    ( videoBonjour
    , videoTuto
    )

import Core.Types as Core
import Element exposing (Element)
import Element.Font as Font
import Html
import Html.Attributes


videoTuto : Element Core.Msg
videoTuto =
    Element.column [ Element.centerX, Element.spacing 10 ]
        [ Element.el [ Element.centerX, Font.center, Font.bold, Font.size 18 ] <| Element.text "Tutoriel vidéo: utilisation de Polymny (Réalisé avec polymny!)"
        , Element.el [] <|
            Element.html
                (Html.iframe
                    [ Html.Attributes.style "posistion" "absolute"
                    , Html.Attributes.style "width" "800px"
                    , Html.Attributes.style "height" "450px"
                    , Html.Attributes.attribute "allowfullscreen" "true"
                    , Html.Attributes.attribute "border" "0px"
                    , Html.Attributes.src "https://video.polymny.studio/?v=3d608a84-a457-4016-a7d1-de1d4da800ad/"
                    ]
                    []
                )
        ]


videoBonjour : Element Core.Msg
videoBonjour =
    Element.column [ Element.centerX, Element.spacing 15 ]
        [ Element.paragraph [ Element.centerX, Font.center, Font.medium, Font.size 48 ] [ Element.text "Vidéos produites avec polymny: courts extraits" ]
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
