module Ui.Ui exposing
    ( addButton
    , arrowCircleRightButton
    , blink
    , cameraButton
    , cancelButton
    , chainButton
    , clearButton
    , closeLockButton
    , editButton
    , errorModal
    , fontButton
    , homeButton
    , imageButton
    , linkButton
    , mainViewAttributes1
    , mainViewAttributes2
    , menuPointButton
    , menuTabAttributes
    , messageWithSpinner
    , movieButton
    , onEnter
    , onEnterEscape
    , onEscape
    , openLockButton
    , penButton
    , primaryButton
    , primaryButtonDisabled
    , simpleButton
    , simpleButtonDisabled
    , spinner
    , startRecordButton
    , stopRecordButton
    , successButton
    , successModal
    , tabButton
    , tabButtonActive
    , textButton
    , topBarButton
    , trashButton
    , videoTuto
    )

import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
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
    [ Font.color Colors.white
    , Element.centerX
    , Element.padding 10
    , Background.color Colors.primary
    , Border.color Colors.white
    , Border.rounded 5
    , Border.width 1
    , Font.color Colors.white
    ]


blink : Element.Attribute msg
blink =
    Element.htmlAttribute (Html.Attributes.class "blink")


textButton : Maybe msg -> String -> Element msg
textButton onPress content =
    Input.button buttonAttributes
        { onPress = onPress
        , label = Element.text content
        }


linkButton : Maybe msg -> String -> Element msg
linkButton onPress content =
    Input.button
        [ Font.color Colors.primary
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
                ++ [ Background.color Colors.artSunFlowers
                   , Font.color Colors.primary
                   , Font.medium
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
        (buttonAttributes
            ++ [ Background.color Colors.primary
               , Font.medium
               , Font.color Colors.artSunFlowers
               , Border.color Colors.artSunFlowers
               ]
        )
        { onPress = onPress
        , label = Element.text content
        }


primaryButton : Maybe msg -> String -> Element msg
primaryButton onPress content =
    Input.button
        buttonAttributes
        { onPress = onPress
        , label = Element.text content
        }


iconButton : Element msg -> Maybe msg -> String -> String -> Element msg
iconButton icon onPress content tooltip =
    let
        iconAttributes =
            [ Font.color Colors.primary
            , Background.color Colors.grey
            , Border.color Colors.primary
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
        [ Background.color Colors.primary
        , Font.color Colors.white
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
        , Font.color Colors.artSunFlowers
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


videoTuto : Element Core.Msg
videoTuto =
    Element.column [ Element.centerX, Element.spacing 10 ]
        [ Element.el [ Element.centerX, Font.center, Font.bold, Font.size 18 ] <| Element.text "Tutoriel vidéo: utilisation de Polymny (Réalisé avec polymny!)"
        , Element.el [] <|
            Element.html
                (Html.iframe
                    [ Html.Attributes.style "posistion" "absolute"
                    , Html.Attributes.style "width" "800px"
                    , Html.Attributes.style "height" "450px"
                    , Html.Attributes.attribute "allowfullscreen" "true"
                    , Html.Attributes.attribute "border" "0px"
                    , Html.Attributes.src "https://video.polymny.studio/?v=3d608a84-a457-4016-a7d1-de1d4da800ad/"
                    ]
                    []
                )
        ]
