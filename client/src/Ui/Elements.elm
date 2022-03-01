module Ui.Elements exposing (primary, secondary, link, Action(..))

{-| This module contains helpers to easily make buttons.

@docs primary, secondary, link, Action

-}

import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Route exposing (Route)
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
    navigationElement action (addPrimaryAttr attr) label


{-| The attributes of a primary button.
-}
addPrimaryAttr : List (Element.Attribute msg) -> List (Element.Attribute msg)
addPrimaryAttr attr =
    Border.rounded 100
        :: Background.color Colors.green1
        :: Font.color Colors.greyBackground
        :: attr


{-| Creates a secondary button, with colored background and white text.
-}
secondary : List (Element.Attribute msg) -> { label : String, action : Action msg } -> Element msg
secondary attr { label, action } =
    --navigationElement action (addSecondaryAttr attr) label
    Element.el attr (navigationElement action (addSecondaryAttr []) label)


{-| The attributes of a secondary button.
-}
addSecondaryAttr : List (Element.Attribute msg) -> List (Element.Attribute msg)
addSecondaryAttr attr =
    Border.rounded 100
        :: Background.color Colors.greyBackground
        :: Font.color Colors.greyFont
        :: Ui.p 12
        :: Font.bold
        :: attr


{-| Creates a link, colored and changing color at hover.
-}
link : List (Element.Attribute msg) -> { label : String, action : Action msg } -> Element msg
link attr { label, action } =
    navigationElement action (addLinkAttr attr) label


{-| The attributes of a link.
-}
addLinkAttr : List (Element.Attribute msg) -> List (Element.Attribute msg)
addLinkAttr attr =
    Font.color Colors.green1 :: Element.mouseOver [ Font.color Colors.greyFont ] :: attr


{-| An utility functions to create buttons or link depending on the action.
-}
navigationElement : Action msg -> List (Element.Attribute msg) -> String -> Element msg
navigationElement action attr label =
    case action of
        Route route ->
            Element.link attr { url = Route.toUrl route, label = Element.text label }

        Msg msg ->
            Input.button attr { onPress = Just msg, label = Element.text label }

        None ->
            Element.el attr (Element.text label)
