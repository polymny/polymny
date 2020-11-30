module Ui.Ui exposing (..)

import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Html.Events
import Json.Decode as Decode
import Ui.Colors as Colors
import Ui.Icons as Icons


linkAttributes : List (Element.Attribute msg)
linkAttributes =
    [ Font.color Colors.link
    , Element.mouseOver [ Font.color Colors.dark ]
    ]


borderBottom : Int -> Element.Attribute msg
borderBottom size =
    Border.widthEach { bottom = size, top = 0, left = 0, right = 0 }


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


onEscape : msg -> Element.Attribute msg
onEscape msg =
    Element.htmlAttribute
        (Html.Events.on "keyup"
            (Decode.field "key" Decode.string
                |> Decode.andThen
                    (\key ->
                        if key == "Escape" then
                            Decode.succeed msg

                        else
                            Decode.fail "Not the enter key"
                    )
            )
        )


onEnterEscape : msg -> msg -> Element.Attribute msg
onEnterEscape msgEnter msgEscape =
    Element.htmlAttribute
        (Html.Events.on "keyup"
            (Decode.field "key" Decode.string
                |> Decode.andThen
                    (\key ->
                        if key == "Escape" then
                            Decode.succeed msgEscape

                        else if key == "Enter" then
                            Decode.succeed msgEnter

                        else
                            Decode.fail "Not the right key"
                    )
            )
        )


buttonAttributes : List (Element.Attribute msg)
buttonAttributes =
    [ Element.centerX
    , Element.padding 10
    , Border.rounded 50
    , Font.bold
    ]


primaryButton : Maybe msg -> String -> Element msg
primaryButton msg text =
    Input.button
        [ Border.rounded 50
        , Background.color Colors.navbar
        , Font.color Colors.white
        , Font.bold
        , Element.padding 10
        , Element.mouseOver
            [ Background.color Colors.success
            ]
        ]
        { label = Element.text text
        , onPress = msg
        }


simpleButton : Maybe msg -> String -> Element msg
simpleButton msg text =
    Input.button
        [ Border.rounded 50
        , Background.color Colors.white
        , Font.color Colors.dark
        , Element.padding 10
        , Border.width 1
        , Border.color Colors.whiteTer
        , Font.bold
        , Element.mouseOver
            [ Background.color Colors.whiteBis
            , Font.color Colors.link
            ]
        ]
        { label = Element.text text
        , onPress = msg
        }


primaryButtonWithTooltip : Maybe msg -> String -> String -> Element msg
primaryButtonWithTooltip msg text tooltip =
    Input.button
        [ Border.rounded 50
        , Background.color Colors.navbar
        , Font.color Colors.white
        , Font.bold
        , Element.padding 10
        , Element.htmlAttribute (Html.Attributes.title tooltip)
        , Element.mouseOver
            [ Background.color Colors.success
            ]
        ]
        { label = Element.text text
        , onPress = msg
        }


linkButton : Maybe msg -> String -> Element msg
linkButton msg text =
    Input.button
        linkAttributes
        { label = Element.text text
        , onPress = msg
        }


topBarButton : Maybe msg -> String -> Element msg
topBarButton msg text =
    -- TODO
    Input.button
        [ Border.rounded 50
        , Background.color Colors.white
        , Font.color Colors.dark
        , Element.padding 10
        , Border.width 1
        , Border.color Colors.whiteTer
        , Element.mouseOver
            [ Background.color Colors.whiteBis
            , Font.color Colors.link
            ]
        ]
        { label = Element.text text
        , onPress = msg
        }


blink : Element.Attribute msg
blink =
    Element.htmlAttribute (Html.Attributes.class "blink")


iconButton : Element msg -> Maybe msg -> String -> String -> Element msg
iconButton icon onPress content tooltip =
    let
        iconAttributes =
            [ Font.color Colors.navbar
            , Background.color Colors.light
            , Element.padding 5
            , Border.rounded 5
            , Element.htmlAttribute (Html.Attributes.title tooltip)
            ]

        contentElement =
            if content == "" then
                Element.none

            else
                Element.el [ Element.paddingEach { left = 5, right = 0, top = 0, bottom = 0 } ] (Element.text content)
    in
    Input.button iconAttributes
        { onPress = onPress
        , label = Element.row [] [ icon, contentElement ]
        }


downloadButton : String -> String -> Element msg
downloadButton url tooltip =
    let
        iconAttributes =
            [ Font.color Colors.success
            , Background.color Colors.light
            , Element.padding 5
            , Border.rounded 5
            , Element.htmlAttribute (Html.Attributes.title tooltip)
            ]
    in
    Element.download iconAttributes
        { url = url
        , label = Icons.download
        }


trashButton : Maybe msg -> String -> String -> Element msg
trashButton onPress content =
    iconButton Icons.trash onPress content


fontButton : Maybe msg -> String -> String -> Element msg
fontButton onPress content =
    iconButton Icons.font onPress content


addButton : Maybe msg -> String -> String -> Element msg
addButton onPress content =
    iconButton Icons.add onPress content


editButton : Maybe msg -> String -> String -> Element msg
editButton onPress content =
    iconButton Icons.edit onPress content


clearButton : Maybe msg -> String -> String -> Element msg
clearButton onPress content =
    iconButton Icons.clear onPress content


cancelButton : Maybe msg -> String -> String -> Element msg
cancelButton onPress content =
    iconButton Icons.cancel onPress content


cameraButton : Maybe msg -> String -> String -> Element msg
cameraButton onPress content =
    iconButton Icons.camera onPress content


imageButton : Maybe msg -> String -> String -> Element msg
imageButton onPress content =
    iconButton Icons.image onPress content


recordButton : Element msg -> Maybe msg -> String -> Element msg
recordButton icon onPress content =
    let
        iconAttributes =
            buttonAttributes
    in
    Input.button iconAttributes
        { onPress = onPress
        , label = Element.row [] [ icon, Element.text content ]
        }


startRecordButton : Maybe msg -> String -> Element msg
startRecordButton onPress content =
    recordButton Icons.startRecord onPress content


stopRecordButton : Maybe msg -> String -> Element msg
stopRecordButton onPress content =
    recordButton Icons.stopRecord onPress content


movieButton : Maybe msg -> String -> String -> Element msg
movieButton onPress content =
    iconButton Icons.movie onPress content


openLockButton : Maybe msg -> String -> String -> Element msg
openLockButton onPress content =
    iconButton Icons.openLock onPress content


closeLockButton : Maybe msg -> String -> String -> Element msg
closeLockButton onPress content =
    iconButton Icons.closeLock onPress content


menuPointButton : Maybe msg -> String -> String -> Element msg
menuPointButton onPress content =
    iconButton Icons.menuPoint onPress content


penButton : Maybe msg -> String -> String -> Element msg
penButton onPress content =
    iconButton Icons.pen onPress content


chainButton : Maybe msg -> String -> String -> Element msg
chainButton onPress content =
    iconButton Icons.chain onPress content


arrowCircleRightButton : Maybe msg -> String -> String -> Element msg
arrowCircleRightButton onPress content =
    iconButton Icons.arrowCircleRight onPress content


timesButton : Maybe msg -> String -> String -> Element msg
timesButton onPress content =
    iconButton Icons.times onPress content


homeButton : Maybe msg -> String -> Element msg
homeButton onPress content =
    let
        icon =
            Element.image [ Element.width (Element.px 40) ]
                { src = "/dist/logo.png"
                , description = " Polymny home page"
                }
    in
    Input.button
        [ Font.color Colors.white
        ]
        { onPress = onPress
        , label = Element.row [] [ icon, Element.text content ]
        }


primaryButtonDisabled : String -> Element msg
primaryButtonDisabled content =
    Input.button
        (buttonAttributes
            ++ [ Background.color Colors.grey
               , Font.color Colors.greyDark
               ]
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
    Element.paragraph
        (Background.color Colors.dangerLight
            :: Font.color Colors.dangerDark
            :: modalAttributes
        )
        [ Element.text text ]


successModal : String -> Element msg
successModal text =
    Element.paragraph
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
        , Font.color Colors.primary
        ]
        Icons.spinner


messageWithSpinner : String -> Element msg
messageWithSpinner content =
    Element.column
        (buttonAttributes
            ++ [ Border.color Colors.primary
               , Border.width 1
               , Element.centerX
               ]
        )
        [ spinner
        , Element.el [] <| Element.text content
        ]


mainViewAttributes1 : List (Element.Attribute msg)
mainViewAttributes1 =
    [ Element.alignTop
    , Element.padding 10
    , Element.width Element.fill
    ]


mainViewAttributes2 : List (Element.Attribute msg)
mainViewAttributes2 =
    [ Element.alignTop
    , Element.padding 10
    , Element.width Element.fill
    ]


centerElementWithSize : Int -> Element msg -> Element msg
centerElementWithSize ratio element =
    Element.column
        [ Element.width Element.fill, Element.height Element.fill, Background.color (Element.rgba255 0 0 0 0.8) ]
        [ Element.el [ Element.width Element.fill, Element.height Element.fill ] Element.none
        , Element.el [ Element.width Element.fill, Element.height (Element.fillPortion ratio) ]
            (Element.row [ Element.width Element.fill, Element.height Element.fill ]
                [ Element.el [ Element.width Element.fill, Element.height Element.fill ] Element.none
                , Element.el [ Element.width (Element.fillPortion ratio), Element.height Element.fill ] element
                , Element.el [ Element.width Element.fill, Element.height Element.fill ] Element.none
                ]
            )
        , Element.el [ Element.width Element.fill, Element.height Element.fill ] Element.none
        ]


centerElement : Element msg -> Element msg
centerElement element =
    centerElementWithSize 1 element


popupWithSize : Int -> String -> Element msg -> Element msg
popupWithSize ratio title content =
    centerElementWithSize ratio
        (Element.column [ Element.height Element.fill, Element.width Element.fill ]
            [ Element.el [ Element.width Element.fill, Background.color Colors.navbar ]
                (Element.el
                    [ Element.centerX, Font.color Colors.white, Element.padding 10, Font.bold ]
                    (Element.text title)
                )
            , Element.el [ Element.width Element.fill, Element.height Element.fill, Background.color Colors.light ] content
            ]
        )


popup : String -> Element msg -> Element msg
popup title content =
    popupWithSize 1 title content
