module Ui exposing (..)

import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input


greyColor =
    175


whiteColor =
    Element.rgb255 255 255 255


borderColor =
    Element.rgb255 greyColor greyColor greyColor


primaryColor =
    Element.rgb255 50 115 220


successColor =
    Element.rgb255 72 199 116


warningColor =
    Element.rgb255 255 221 87


dangerColor =
    Element.rgb255 241 70 104


buttonAttributes : List (Element.Attribute msg)
buttonAttributes =
    [ Element.centerX
    , Element.padding 10
    , Border.rounded 5
    , Border.width 1
    , Border.color borderColor
    ]


simpleButton : Maybe msg -> String -> Element msg
simpleButton onPress content =
    Input.button
        (Background.color whiteColor :: buttonAttributes)
        { onPress = onPress
        , label = Element.text content
        }


successButton : Maybe msg -> String -> Element msg
successButton onPress content =
    Input.button
        (Background.color successColor
            :: Font.color whiteColor
            :: buttonAttributes
        )
        { onPress = onPress
        , label = Element.text content
        }


primaryButton : Maybe msg -> String -> Element msg
primaryButton onPress content =
    Input.button
        (Background.color primaryColor
            :: Font.color whiteColor
            :: buttonAttributes
        )
        { onPress = onPress
        , label = Element.text content
        }
