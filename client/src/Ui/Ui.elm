module Ui.Ui exposing
    ( addButton
    , cameraButton
    , cancelButton
    , clearButton
    , closeLockButton
    , editButton
    , errorModal
    , homeButton
    , linkButton
    , menuPointButton
    , menuTabAttributes
    , messageWithSpinner
    , movieButton
    , onEnter
    , openLockButton
    , primaryButton
    , primaryButtonDisabled
    , simpleButton
    , simpleButtonDisabled
    , spinner
    , successButton
    , successModal
    , tabButton
    , tabButtonActive
    , textButton
    , topBarButton
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
    , Font.color Colors.artEvening
    ]


textButton : Maybe msg -> String -> Element msg
textButton onPress content =
    Input.button
        [ Font.color Colors.white
        , Element.centerX
        , Element.padding 10
        , Background.color Colors.artStarryNight
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


topBarButton : Maybe msg -> String -> Element msg
topBarButton onPress content =
    let
        attr =
            buttonAttributes
                ++ [ Background.color Colors.primary
                   , Font.color Colors.artSunFlowers
                   , Border.color Colors.artSunFlowers
                   , Border.rounded 5
                   , Border.width 1
                   ]
    in
    Input.button
        attr
        { onPress = onPress
        , label = Element.text content
        }


simpleButton : Maybe msg -> String -> Element msg
simpleButton onPress content =
    let
        attr =
            buttonAttributes
                ++ [ Background.color Colors.primary
                   , Font.color Colors.white
                   , Border.color Colors.artEvening
                   , Border.rounded 5
                   , Border.width 1
                   ]
    in
    Input.button
        attr
        { onPress = onPress
        , label = Element.text content
        }


simpleButtonDisabled : String -> Element msg
simpleButtonDisabled content =
    Input.button
        [ Background.color Colors.white
        , Font.color Colors.grey
        ]
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
        (Background.color Colors.artStarryNight
            :: Font.color Colors.artIrises
            :: buttonAttributes
        )
        { onPress = onPress
        , label = Element.row [] [ Icons.edit, Element.text content ]
        }


iconButton : Element msg -> Maybe msg -> String -> Element msg
iconButton icon onPress content =
    let
        iconAttributes =
            [ Element.centerX
            , Element.padding 10
            , Font.color Colors.primary
            , Background.color Colors.white
            , Border.color Colors.primary
            , Border.rounded 5
            , Border.width 1
            ]
    in
    Input.button iconAttributes
        { onPress = onPress
        , label = Element.row [] [ icon, Element.text content ]
        }


trashButton : Maybe msg -> String -> Element msg
trashButton onPress content =
    iconButton Icons.trash onPress content


addButton : Maybe msg -> String -> Element msg
addButton onPress content =
    iconButton Icons.add onPress content


clearButton : Maybe msg -> String -> Element msg
clearButton onPress content =
    iconButton Icons.clear onPress content


cancelButton : Maybe msg -> String -> Element msg
cancelButton onPress content =
    iconButton Icons.cancel onPress content


cameraButton : Maybe msg -> String -> Element msg
cameraButton onPress content =
    iconButton Icons.camera onPress content


movieButton : Maybe msg -> String -> Element msg
movieButton onPress content =
    iconButton Icons.movie onPress content


openLockButton : Maybe msg -> String -> Element msg
openLockButton onPress content =
    iconButton Icons.openLock onPress content


closeLockButton : Maybe msg -> String -> Element msg
closeLockButton onPress content =
    iconButton Icons.closeLock onPress content


menuPointButton : Maybe msg -> String -> Element msg
menuPointButton onPress content =
    iconButton Icons.menuPoint onPress content


homeButton : Maybe msg -> String -> Element msg
homeButton onPress content =
    let
        icon =
            Element.image [ Element.width (Element.px 60) ]
                { src = "/logo.png"
                , description = " Polymny home page"
                }
    in
    Input.button
        [ Background.color Colors.primary
        , Font.color Colors.white
        ]
        { onPress = onPress
        , label = Element.row [] [ icon, Element.text content ]
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


menuTabAttributes : List (Element.Attribute msg)
menuTabAttributes =
    [ Element.padding 10
    , Element.width Element.fill
    ]


tabButtonAttributes : List (Element.Attribute msg)
tabButtonAttributes =
    [ Element.spacing 5
    , Element.padding 10
    ]


tabButton : Maybe msg -> String -> Element msg
tabButton onPress content =
    Input.button
        tabButtonAttributes
        { onPress = onPress
        , label = Element.text content
        }


tabButtonActive : String -> Element msg
tabButtonActive content =
    Input.button
        (Font.bold :: tabButtonAttributes)
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


spinner : Element msg
spinner =
    Element.el
        [ Element.padding 10
        , Element.centerX
        , Font.color Colors.artIrises
        ]
        Icons.spinner


messageWithSpinner : String -> Element msg
messageWithSpinner content =
    Element.column
        (buttonAttributes
            ++ [ Border.color Colors.artIrises
               , Border.width 1
               , Element.centerX
               ]
        )
        [ spinner
        , Element.el [] <| Element.text content
        ]
