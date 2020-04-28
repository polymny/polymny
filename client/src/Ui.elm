module Ui exposing
    ( designAttributes
    , designGosAttributes
    , designGosTitleAttributes
    , editButton
    , editIcon
    , errorModal
    , genericDesignSlideViewAttributes
    , linkButton
    , onEnter
    , primaryButton
    , primaryButtonDisabled
    , simpleButton
    , simpleButtonDisabled
    , successButton
    , successModal
    , textButton
    , trashIcon
    )

import Colors
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import FontAwesome
import Html
import Html.Events
import Json.Decode as Decode


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
        (Background.color Colors.primary
            :: Font.color Colors.white
            :: buttonAttributes
        )
        { onPress = onPress
        , label = Element.row [] [ editIcon, Element.text content ]
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



-- Icons


trashIcon : Element msg
trashIcon =
    Element.html
        (Html.div
            []
            [ FontAwesome.iconWithOptions
                FontAwesome.trash
                FontAwesome.Solid
                [ FontAwesome.Size (FontAwesome.Mult 2) ]
                []
            ]
        )


editIcon : Element msg
editIcon =
    Element.html
        (Html.div
            []
            [ FontAwesome.iconWithOptions
                FontAwesome.edit
                FontAwesome.Solid
                [ FontAwesome.Size (FontAwesome.Mult 1) ]
                []
            ]
        )



-- design Attributes


designAttributes : List (Element.Attribute msg)
designAttributes =
    [ Element.padding 10
    , Element.width Element.fill
    , Border.rounded 5
    , Border.width 4
    ]


designGosAttributes : List (Element.Attribute msg)
designGosAttributes =
    designAttributes
        ++ [ Element.spacing 10
           , Element.width Element.fill
           , Element.alignTop
           , Element.centerX
           , Border.rounded 5
           , Border.width 2
           , Background.color Colors.brightGreen
           ]


designGosTitleAttributes : List (Element.Attribute msg)
designGosTitleAttributes =
    [ Element.padding 10
    , Border.color Colors.brandeisBlue
    , Border.rounded 5
    , Border.width 2
    , Element.centerX
    , Font.size 20
    ]


genericDesignSlideViewAttributes : List (Element.Attribute msg)
genericDesignSlideViewAttributes =
    [ Background.color Colors.white
    , Element.spacing 5
    , Element.padding 5
    , Border.rounded 5
    , Border.dashed
    , Border.width 3
    , Element.width
        (Element.shrink
            |> Element.minimum 440
            |> Element.maximum 430
        )
    ]


scaled : Int -> Float
scaled =
    Element.modular 400 1.77
