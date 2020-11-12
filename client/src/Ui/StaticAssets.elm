module Ui.StaticAssets exposing
    ( videoBonjour
    , videoPlayerView
    )

import Core.Types as Core
import Element exposing (Element)
import Element.Font as Font
import Html
import Html.Attributes


videoPlayerView : Element.Device -> String -> String -> Element Core.Msg
videoPlayerView device label url =
    let
        ( fontSize, widthPlayer, heightPlayer ) =
            case device.class of
                Element.Phone ->
                    ( 20, "300px", "160px" )

                _ ->
                    ( 40, "800px", "450px" )
    in
    Element.column [ Element.centerX ]
        [ Element.el
            [ Element.centerX
            , Font.center
            , Font.medium
            , Font.size fontSize
            ]
          <|
            Element.paragraph [ Element.centerX ] [ Element.text label ]
        , Element.el [ Element.centerX ] <|
            Element.html
                (Html.iframe
                    [ Html.Attributes.style "posistion" "absolute"
                    , Html.Attributes.style "width" widthPlayer
                    , Html.Attributes.style "height" heightPlayer
                    , Html.Attributes.attribute "allowfullscreen" "true"
                    , Html.Attributes.attribute "border" "0px"
                    , Html.Attributes.src url
                    ]
                    []
                )
        ]


videoBonjour : Element.Device -> Element Core.Msg
videoBonjour device =
    let
        ( fontSize, widthPlayer, heightPlayer ) =
            case device.class of
                Element.Phone ->
                    ( 20, "300px", "160px" )

                _ ->
                    ( 40, "800px", "450px" )
    in
    Element.column [ Element.centerX, Element.spacing 15 ]
        [ Element.paragraph [ Element.centerX, Font.center, Font.bold, Font.size fontSize ] [ Element.text "Vidéos pédagogiques (extraits)" ]
        , Element.el [ Element.centerX, Element.padding 15 ] <|
            Element.html
                (Html.iframe
                    [ Html.Attributes.style "posistion" "absolute"
                    , Html.Attributes.style "width" widthPlayer
                    , Html.Attributes.style "height" heightPlayer
                    , Html.Attributes.attribute "allowfullscreen" "true"
                    , Html.Attributes.attribute "border" "0px"
                    , Html.Attributes.src "https://video.polymny.studio/?v=757685ed-56d0-44b5-9fff-777f8a9e0909/"
                    ]
                    []
                )
        ]
