module Ui.Elements exposing (primary, primaryIcon, secondary, secondaryIcon, link, Action(..), navigationElement, icon, title, animatedEl, spin, spinner)

{-| This module contains helpers to easily make buttons.

@docs primary, primaryIcon, secondary, secondaryIcon, link, Action, navigationElement, icon, title, animatedEl, spin, spinner

-}

import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Material.Icons.Types exposing (Coloring(..), Icon)
import Route exposing (Route)
import Simple.Animation as Animation exposing (Animation)
import Simple.Animation.Animated as Animated
import Simple.Animation.Property as P
import Svg exposing (Svg, g, svg)
import Svg.Attributes exposing (..)
import Ui.Colors as Colors
import Ui.Utils as Ui


{-| The different actions a button can have.

It can be an url, which means clicking the button will navigate to the url, or it can be a message that the button will
trigger.

-}
type Action msg
    = Route Route
    | Msg msg
    | None


{-| Creates a primary button, with colored background and white text.
-}
primary : List (Element.Attribute msg) -> { label : String, action : Action msg } -> Element msg
primary attr { label, action } =
    navigationElement action (addPrimaryAttr attr) (Element.el [ Ui.cx, Font.bold ] (Element.text label))


{-| The attributes of a primary button.
-}
addPrimaryAttr : List (Element.Attribute msg) -> List (Element.Attribute msg)
addPrimaryAttr attr =
    Border.rounded 100
        :: Background.color Colors.green1
        :: Font.color Colors.greyBackground
        :: Ui.p 12
        :: attr


{-| Creates a primary button with an icon.
-}
primaryIcon : List (Element.Attribute msg) -> { icon : Icon msg, tooltip : String, action : Action msg } -> Element msg
primaryIcon attr params =
    navigationElement params.action (Element.htmlAttribute (Html.Attributes.title params.tooltip) :: addPrimaryIconAttr attr) (icon 22 params.icon)


{-| The attributes of a primary button.
-}
addPrimaryIconAttr : List (Element.Attribute msg) -> List (Element.Attribute msg)
addPrimaryIconAttr attr =
    Border.rounded 5
        :: Ui.p 2
        :: Background.color Colors.green1
        :: Font.color Colors.greyBackground
        :: attr


{-| Creates a secondary button, with colored background and white text.
-}
secondary : List (Element.Attribute msg) -> { label : String, action : Action msg } -> Element msg
secondary attr { label, action } =
    --navigationElement action (addSecondaryAttr attr) label
    Element.el attr (navigationElement action (addSecondaryAttr []) (Element.text label))


{-| The attributes of a secondary button.
-}
addSecondaryAttr : List (Element.Attribute msg) -> List (Element.Attribute msg)
addSecondaryAttr attr =
    Border.rounded 100
        :: Background.color Colors.white
        :: Border.color Colors.greyBorder
        :: Ui.b 1
        :: Font.color Colors.greyFont
        :: Ui.p 12
        :: Font.bold
        :: attr


{-| Creates a secondary button with an icon.
-}
secondaryIcon : List (Element.Attribute msg) -> { icon : Icon msg, tooltip : String, action : Action msg } -> Element msg
secondaryIcon attr params =
    navigationElement params.action (Element.htmlAttribute (Html.Attributes.title params.tooltip) :: addSecondaryIconAttr attr) (icon 22 params.icon)


{-| The attributes of a secondary button.
-}
addSecondaryIconAttr : List (Element.Attribute msg) -> List (Element.Attribute msg)
addSecondaryIconAttr attr =
    Border.rounded 5
        :: Ui.b 1
        :: Border.color Colors.greyBorder
        :: Font.color Colors.green1
        :: Ui.p 2
        :: Font.bold
        :: attr


{-| Creates a link, colored and changing color at hover.
-}
link : List (Element.Attribute msg) -> { label : String, action : Action msg } -> Element msg
link attr { label, action } =
    navigationElement action (addLinkAttr attr) (Element.text label)


{-| The attributes of a link.
-}
addLinkAttr : List (Element.Attribute msg) -> List (Element.Attribute msg)
addLinkAttr attr =
    Font.color Colors.green1 :: Element.mouseOver [ Font.color Colors.greyFont ] :: attr


{-| An utility functions to create buttons or link depending on the action.
-}
navigationElement : Action msg -> List (Element.Attribute msg) -> Element msg -> Element msg
navigationElement action attr label =
    case action of
        Route route ->
            Element.link attr { url = Route.toUrl route, label = label }

        Msg msg ->
            Input.button attr { onPress = Just msg, label = label }

        None ->
            Element.el attr label


{-| Transforms an icon into an elm-ui element.
-}
icon : Int -> Icon msg -> Element msg
icon size material =
    Element.html (material size Inherit)


{-| Creates a title.
-}
title : String -> Element msg
title content =
    Element.el [ Font.bold, Font.size 20 ] (Element.text content)


{-| Helper to create icons.
-}
makeIcon : List (Svg.Attribute msg) -> List (Svg msg) -> Icon msg
makeIcon attributes nodes size _ =
    let
        sizeAsString =
            String.fromInt size
    in
    svg
        (attributes ++ [ height sizeAsString, width sizeAsString ])
        [ g
            [ fill "currentColor"
            ]
            nodes
        ]


animatedUi =
    Animated.ui
        { behindContent = Element.behindContent
        , htmlAttribute = Element.htmlAttribute
        , html = Element.html
        }


{-| Creates a spinner.
-}
spinner : Icon msg
spinner =
    makeIcon
        [ viewBox "0 0 24 24" ]
        [ Svg.path [ d "M0 0h24v24H0z", fill "none" ] []
        , Svg.path [ d "M2 12A 10 10 10 1 1 12 22", fill "none", stroke "currentColor", strokeWidth "2" ] []
        ]


{-| Makes an animated Element.el.
-}
animatedEl : Animation -> List (Element.Attribute msg) -> Element msg -> Element msg
animatedEl =
    animatedUi Element.el


{-| An animation to make an element spin.
-}
spin : Animation
spin =
    Animation.fromTo
        { duration = 1000, options = [ Animation.loop, Animation.linear ] }
        [ P.rotate 0 ]
        [ P.rotate 360 ]
