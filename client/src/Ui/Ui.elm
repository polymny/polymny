module Ui.Ui exposing
    ( addButton
    , clearButton
    , editButton
    , errorModal
    , linkButton
    , onEnter
    , primaryButton
    , primaryButtonDisabled
    , simpleButton
    , simpleButtonDisabled
    , successButton
    , successModal
    , textButton
    , trashButton
    )

import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Events
import Json.Decode as Decode
import Ui.Colors as Colors
import Ui.Icons as Icons


onEnter : msg -> Element.Attribute msg
onEnter msg =
    Element.htmlAttribute
        (Html.Events.on "keyup"
            (Decode.field "key" Decode.string
                |> Decode.andThen
                    (\key ->
                        if key == "Enter" then
                            Decode.succeed msg

                        else
                            Decode.fail "Not the enter key"
                    )
            )
        )


buttonAttributes : List (Element.Attribute msg)
buttonAttributes =
    [ Element.centerX
    , Element.padding 10
    , Border.rounded 5
    , Background.color Colors.artStarryNight
    , Font.color Colors.artEvening
    ]


textButton : Maybe msg -> String -> Element msg
textButton onPress content =
    Input.button
        [ Font.color Colors.white
        , Element.centerX
        , Element.padding 10
        ]
        { onPress = onPress
        , label = Element.text content
        }


linkButton : Maybe msg -> String -> Element msg
linkButton onPress content =
    Input.button
        [ Font.color Colors.link
        , Font.underline
        ]
        { onPress = onPress
        , label = Element.text content
        }


simpleButton : Maybe msg -> String -> Element msg
simpleButton onPress content =
    Input.button
        (Background.color Colors.white :: Border.color Colors.grey :: Border.rounded 5 :: Border.width 1 :: buttonAttributes)
        { onPress = onPress
        , label = Element.text content
        }


simpleButtonDisabled : String -> Element msg
simpleButtonDisabled content =
    Input.button
        (Background.color Colors.white
            :: Font.color Colors.grey
            :: buttonAttributes
        )
        { onPress = Nothing
        , label = Element.text content
        }


successButton : Maybe msg -> String -> Element msg
successButton onPress content =
    Input.button
        (Background.color Colors.success
            :: Font.color Colors.white
            :: buttonAttributes
        )
        { onPress = onPress
        , label = Element.text content
        }


primaryButton : Maybe msg -> String -> Element msg
primaryButton onPress content =
    Input.button
        (Background.color Colors.primary
            :: Font.color Colors.white
            :: buttonAttributes
        )
        { onPress = onPress
        , label = Element.text content
        }


editButton : Maybe msg -> String -> Element msg
editButton onPress content =
    Input.button
        (Background.color Colors.artEvening
            :: Font.color Colors.artSunFlowers
            :: buttonAttributes
        )
        { onPress = onPress
        , label = Element.row [] [ Icons.edit, Element.text content ]
        }


trashButton : Maybe msg -> String -> Element msg
trashButton onPress content =
    Input.button
        (Background.color Colors.primary
            :: Font.color Colors.white
            :: buttonAttributes
        )
        { onPress = onPress
        , label = Element.row [] [ Icons.trash, Element.text content ]
        }


addButton : Maybe msg -> String -> Element msg
addButton onPress content =
    Input.button
        (Background.color Colors.primary
            :: Font.color Colors.white
            :: buttonAttributes
        )
        { onPress = onPress
        , label = Element.row [] [ Icons.add, Element.text content ]
        }


clearButton : Maybe msg -> String -> Element msg
clearButton onPress content =
    Input.button
        (Background.color Colors.primary
            :: Font.color Colors.white
            :: buttonAttributes
        )
        { onPress = onPress
        , label = Element.row [] [ Icons.clear, Element.text content ]
        }


primaryButtonDisabled : String -> Element msg
primaryButtonDisabled content =
    Input.button
        (Background.color Colors.primaryLight
            :: Font.color Colors.grey
            :: buttonAttributes
        )
        { onPress = Nothing
        , label = Element.text content
        }


modalAttributes : List (Element.Attribute msg)
modalAttributes =
    [ Element.padding 10
    , Element.width Element.fill
    , Border.rounded 5
    , Border.width 1
    , Border.color Colors.grey
    ]


errorModal : String -> Element msg
errorModal text =
    Element.row
        (Background.color Colors.dangerLight
            :: Font.color Colors.dangerDark
            :: modalAttributes
        )
        [ Element.text text ]


successModal : String -> Element msg
successModal text =
    Element.row
        (Background.color Colors.successLight
            :: Font.color Colors.successDark
            :: modalAttributes
        )
        [ Element.text text ]