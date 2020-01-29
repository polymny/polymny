module Ui exposing (..)

import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input


greyValue =
    175


greyColor =
    Element.rgb255 greyValue greyValue greyValue


whiteColor =
    Element.rgb255 255 255 255


borderColor =
    greyColor


primaryColor =
    Element.rgb255 50 115 220


successColor =
    Element.rgb255 40 167 69


warningColor =
    Element.rgb255 255 221 87


dangerColor =
    Element.rgb255 241 70 104


primaryLightColor =
    Element.rgb255 93 145 227


buttonAttributes : List (Element.Attribute msg)
buttonAttributes =
    [ Element.centerX
    , Element.padding 10
    , Border.rounded 5
    ]


textButton : Maybe msg -> String -> Element msg
textButton onPress content =
    Input.button
        [ Font.color whiteColor
        , Element.centerX
        , Element.padding 10
        ]
        { onPress = onPress
        , label = Element.text content
        }


simpleButton : Maybe msg -> String -> Element msg
simpleButton onPress content =
    Input.button
        (Background.color whiteColor :: buttonAttributes)
        { onPress = onPress
        , label = Element.text content
        }


simpleButtonDisabled : String -> Element msg
simpleButtonDisabled content =
    Input.button
        (Background.color whiteColor
            :: Font.color greyColor
            :: buttonAttributes
        )
        { onPress = Nothing
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


primaryButtonDisabled : String -> Element msg
primaryButtonDisabled content =
    Input.button
        (Background.color primaryLightColor
            :: Font.color greyColor
            :: buttonAttributes
        )
        { onPress = Nothing
        , label = Element.text content
        }
