module Ui.Elements exposing
    ( primary, primaryGeneric, primaryIcon, secondary, secondaryGeneric, secondaryIcon, link, Action(..), navigationElement, icon, title, animatedEl, spin
    , spinner, spinningSpinner, popup
    , addLinkAttr, errorModal, longText, successModal
    )

{-| This module contains helpers to easily make buttons.

@docs primary, primaryGeneric, primaryIcon, secondary, secondaryGeneric, secondaryIcon, link, Action, navigationElement, icon, title, animatedEl, spin
@docs spinner, spinningSpinner, popup
@docs errorModaln successModal

-}

import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Material.Icons.Types exposing (Coloring(..), Icon)
import Route exposing (Route)
import Simple.Animation as Animation exposing (Animation)
import Simple.Animation.Animated as Animated
import Simple.Animation.Property as P
import Simple.Transition as Transition
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
    | NewTab String
    | Download String
    | Msg msg
    | None


{-| Creates a primary button with a generic element.
-}
primaryGeneric : List (Element.Attribute msg) -> List (Element.Attribute msg) -> { label : Element msg, action : Action msg } -> Element msg
primaryGeneric outerAttr innerAttr { label, action } =
    let
        outer =
            outerAttr
                ++ [ Background.color Colors.green2
                   , Border.color Colors.greyBorder
                   , Ui.b 1
                   ]
                ++ (if action == None then
                        [ Background.color <| Colors.alpha 0.1 ]

                    else
                        []
                   )

        inner =
            innerAttr
                ++ [ Font.center
                   , Ui.wf
                   , Ui.hf
                   , Element.mouseOver <| [ Background.color <| Colors.alpha 0.1 ]
                   , Transition.properties
                        [ Transition.backgroundColor 200 []
                        ]
                        |> Element.htmlAttribute
                   ]
                ++ (if action == None then
                        [ Background.color <| Colors.alpha 0.1 ]

                    else
                        []
                   )
    in
    navigationElement action outer (Element.el inner label)


{-| Creates a primary button, with colored background and white text.
-}
primary : List (Element.Attribute msg) -> { label : Element msg, action : Action msg } -> Element msg
primary attr { label, action } =
    let
        outerAttr : List (Element.Attribute msg)
        outerAttr =
            Border.rounded 100 :: attr

        innerAttr : List (Element.Attribute msg)
        innerAttr =
            [ Border.rounded 100, Ui.p 12, Font.bold, Font.color Colors.white ]
    in
    primaryGeneric outerAttr innerAttr { label = label, action = action }


{-| Creates a primary button with an icon.
-}
primaryIcon : List (Element.Attribute msg) -> { icon : Icon msg, tooltip : String, action : Action msg } -> Element msg
primaryIcon attr params =
    let
        outerAttr : List (Element.Attribute msg)
        outerAttr =
            Border.rounded 5 :: Font.color Colors.white :: Ui.tooltip params.tooltip :: attr

        innerAttr : List (Element.Attribute msg)
        innerAttr =
            [ Border.rounded 5, Ui.p 2 ]
    in
    primaryGeneric outerAttr innerAttr { label = icon 22 params.icon, action = params.action }


{-| Creates a secondary button with a generic element.
-}
secondaryGeneric : List (Element.Attribute msg) -> List (Element.Attribute msg) -> { label : Element msg, action : Action msg } -> Element msg
secondaryGeneric outerAttr innerAttr { label, action } =
    let
        outer =
            outerAttr
                ++ [ Background.color Colors.white
                   , Border.color Colors.greyBorder
                   , Ui.b 1
                   ]

        inner =
            innerAttr
                ++ [ Font.center
                   , Ui.wf
                   , Ui.hf
                   , Element.mouseOver <| [ Background.color <| Colors.alpha 0.1 ]
                   , Transition.properties
                        [ Transition.backgroundColor 200 []
                        ]
                        |> Element.htmlAttribute
                   ]
                ++ (if action == None then
                        [ Background.color <| Colors.alpha 0.1 ]

                    else
                        []
                   )
    in
    navigationElement action outer (Element.el inner label)


{-| Creates a primary button, with colored background and white text.
-}
secondary : List (Element.Attribute msg) -> { label : Element msg, action : Action msg } -> Element msg
secondary attr { label, action } =
    let
        outerAttr : List (Element.Attribute msg)
        outerAttr =
            Border.rounded 100 :: Font.color Colors.black :: attr

        innerAttr : List (Element.Attribute msg)
        innerAttr =
            [ Border.rounded 100, Ui.p 12, Font.bold ]
    in
    secondaryGeneric outerAttr innerAttr { label = label, action = action }


{-| Creates a secondary button with an icon.
-}
secondaryIcon : List (Element.Attribute msg) -> { icon : Icon msg, tooltip : String, action : Action msg } -> Element msg
secondaryIcon attr params =
    let
        outerAttr : List (Element.Attribute msg)
        outerAttr =
            Border.rounded 5 :: Font.color Colors.green2 :: Ui.tooltip params.tooltip :: attr

        innerAttr : List (Element.Attribute msg)
        innerAttr =
            [ Ui.p 2 ]
    in
    secondaryGeneric outerAttr innerAttr { label = icon 22 params.icon, action = params.action }


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
    let
        newAttr : List (Element.Attribute msg)
        newAttr =
            Element.focused [] :: attr
    in
    case action of
        Route route ->
            Element.link newAttr { url = Route.toUrl route, label = label }

        NewTab url ->
            Element.newTabLink newAttr { url = url, label = label }

        Download url ->
            Element.download newAttr { url = url, label = label }

        Msg msg ->
            Input.button newAttr { onPress = Just msg, label = label }

        None ->
            Element.el
                (newAttr
                    ++ [ Element.htmlAttribute (Html.Attributes.style "cursor" "not-allowed")
                       , Font.color Colors.greyFontDisabled
                       ]
                )
                label


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


{-| Shortcut for Animated.ui
-}
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


{-| A spinning spinner.
-}
spinningSpinner : List (Element.Attribute msg) -> Int -> Element msg
spinningSpinner attr size =
    animatedEl spin attr (icon size spinner)


{-| A popup.
-}
popup : Int -> String -> Element msg -> Element msg
popup size titleText content =
    Element.row [ Ui.zIndex 1, Ui.wf, Ui.hf, Background.color (Element.rgba255 0 0 0 0.5), Element.scrollbars ]
        [ Element.el [ Ui.wfp 1 ] Element.none
        , Element.column [ Ui.hf, Ui.wfp size, Element.scrollbars ]
            [ Element.el [ Ui.hfp 1 ] Element.none
            , Element.column
                [ Ui.wf
                , Ui.hfp size
                , Background.color Colors.green2
                , Ui.r 10
                , Ui.b 1
                , Border.color <| Colors.alphaColor 0.8 Colors.greyFont
                , Border.shadow
                    { offset = ( 0.0, 0.0 )
                    , size = 3.0
                    , blur = 3.0
                    , color = Colors.alpha 0.1
                    }
                , Element.scrollbars
                ]
                [ Element.el [ Ui.p 10, Ui.cx, Font.color Colors.white, Font.bold ] (Element.text titleText)
                , Element.el
                    [ Ui.wf
                    , Ui.hf
                    , Background.color Colors.greyBackground
                    , Ui.p 10
                    , Ui.r 10
                    , Element.scrollbars
                    , Border.shadow
                        { offset = ( 0.0, 0.0 )
                        , size = 3.0
                        , blur = 3.0
                        , color = Colors.alpha 0.1
                        }
                    ]
                    content
                ]
            , Element.el [ Ui.hfp 1 ] Element.none
            ]
        , Element.el [ Ui.wfp 1 ] Element.none
        ]


{-| Helper to create an error modal.
-}
errorModal : List (Element.Attribute msg) -> Element msg -> Element msg
errorModal attr input =
    Element.el
        (Border.color Colors.red
            :: Font.color Colors.red
            :: Background.color Colors.redLight
            :: Ui.b 1
            :: Ui.p 10
            :: Ui.r 5
            :: attr
        )
        input


{-| Helper to create a success modal.
-}
successModal : List (Element.Attribute msg) -> Element msg -> Element msg
successModal attr input =
    Element.el
        (Border.color Colors.green2
            :: Font.color Colors.green2
            :: Background.color Colors.greenLight
            :: Ui.b 1
            :: Ui.p 10
            :: Ui.r 5
            :: attr
        )
        input


{-| Displays a long text that can have ellipsis if too long, in which case the full text will be visible from its title
(tooltip).
-}
longText : List (Element.Attribute msg) -> String -> Element msg
longText attr text =
    Html.div
        [ Html.Attributes.style "overflow" "hidden"
        , Html.Attributes.style "text-overflow" "ellipsis"
        , Html.Attributes.class "might-overflow"
        ]
        [ Html.text text ]
        |> Element.html
        |> Element.el
            (Element.htmlAttribute (Html.Attributes.style "overflow" "hidden")
                :: Element.htmlAttribute (Html.Attributes.class "wf")
                :: attr
            )
