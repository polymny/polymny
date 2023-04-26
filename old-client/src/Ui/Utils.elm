module Ui.Utils exposing (..)

import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import FontAwesome
import Html
import Html.Attributes
import Html.Events
import Json.Decode as Decode
import Lang exposing (Lang)
import Popup exposing (Popup)
import Route exposing (Route)
import Ui.Colors as Colors


wf : Element.Attribute msg
wf =
    Element.width Element.fill


wfp : Int -> Element.Attribute msg
wfp portion =
    Element.width (Element.fillPortion portion)


hf : Element.Attribute msg
hf =
    Element.height Element.fill


hfp : Int -> Element.Attribute msg
hfp portion =
    Element.height (Element.fillPortion portion)


id : String -> Element.Attribute msg
id input =
    Element.htmlAttribute (Html.Attributes.id input)


p : Element msg -> Element msg
p element =
    Element.paragraph [] [ element ]


blink : Element.Attribute msg
blink =
    Element.htmlAttribute (Html.Attributes.class "blink")


disabled : List (Element.Attribute msg)
disabled =
    [ Font.color Colors.grey, Element.htmlAttribute (Html.Attributes.disabled True) ]


labelAttr : List (Element.Attribute msg)
labelAttr =
    [ Font.size 15 ]


formTitle : List (Element.Attribute msg)
formTitle =
    [ Font.size 22, Font.bold ]


pageTitle : List (Element.Attribute msg)
pageTitle =
    [ Font.size 42, Font.bold ]


progressBar : Float -> Element msg
progressBar value =
    let
        percentage =
            toFloat (Basics.floor (value * 10000)) / 100

        floor =
            Basics.floor percentage

        progressText =
            Element.el [ wf, hf ]
                (Element.el [ Font.color Colors.black, Element.centerX, Element.centerY ]
                    (Element.text (String.fromFloat percentage ++ " %"))
                )
    in
    Element.el [ wf, Element.height (Element.px 30) ]
        (Element.row [ wf, hf, Element.paddingXY 30 0, Element.inFront progressText ]
            [ Element.el [ hf, wfp floor, Background.color Colors.navbar ] Element.none
            , Element.el [ hf, wfp (100 - floor), Background.color Colors.grey ] Element.none
            ]
        )


horizontalDelimiter : Element msg
horizontalDelimiter =
    Element.el
        [ wf
        , Element.height (Element.px 0)
        , Border.widthEach { left = 0, right = 0, top = 1, bottom = 0 }
        , Border.color Colors.greyLighter
        ]
        Element.none


borderBottom : Int -> Element.Attribute msg
borderBottom size =
    Border.widthEach { bottom = size, top = 0, right = 0, left = 0 }


hidden : Element.Attribute msg
hidden =
    Element.htmlAttribute (Html.Attributes.style "visibility" "hidden")


link : List (Element.Attribute msg) -> { route : Route, label : Element msg } -> Element msg
link attr { route, label } =
    Element.link
        (Font.color Colors.link :: Element.mouseOver [ Font.color Colors.black ] :: attr)
        { url = Route.toUrl route, label = label }


linkButton : List (Element.Attribute msg) -> { onPress : Maybe msg, label : Element msg } -> Element msg
linkButton attr { onPress, label } =
    Input.button
        (Font.color Colors.link :: Element.mouseOver [ Font.color Colors.black ] :: attr)
        { onPress = onPress, label = label }


newTabLink : List (Element.Attribute msg) -> { route : Route, label : Element msg } -> Element msg
newTabLink attr { route, label } =
    Element.newTabLink
        (Font.color Colors.link :: Element.mouseOver [ Font.color Colors.black ] :: attr)
        { url = Route.toUrl route, label = label }


button : List (Element.Attribute msg) -> { onPress : Maybe msg, label : Element msg } -> Element msg
button attr { onPress, label } =
    Input.button attr { onPress = onPress, label = label }


error : Element msg -> Element msg
error message =
    Element.el
        [ wf
        , Border.rounded 10
        , Border.color Colors.dangerDark
        , Border.width 1
        , Element.padding 10
        , Background.color Colors.dangerLight
        , Font.color Colors.dangerDark
        ]
        message


success : Element msg -> Element msg
success message =
    Element.el
        [ wf
        , Border.rounded 10
        , Border.color Colors.successDark
        , Border.width 1
        , Element.padding 10
        , Background.color Colors.successLight
        , Font.color Colors.successDark
        ]
        message


primaryButton : { onPress : Maybe msg, label : Element msg } -> Element msg
primaryButton data =
    Input.button
        [ Background.color Colors.navbar
        , Font.color Colors.white
        , Font.bold
        , Element.padding 12
        , Border.rounded 50
        ]
        data


dangerButton : { onPress : Maybe msg, label : Element msg } -> Element msg
dangerButton data =
    Input.button
        [ Background.color Colors.danger
        , Font.color Colors.white
        , Font.bold
        , Element.padding 12
        , Border.rounded 50
        ]
        data


primaryLink : { route : Route, label : Element msg } -> Element msg
primaryLink data =
    Element.link
        [ Background.color Colors.navbar
        , Font.color Colors.white
        , Font.bold
        , Element.padding 12
        , Border.rounded 50
        ]
        { url = Route.toUrl data.route, label = data.label }


spinner : Element msg
spinner =
    Element.html
        (Html.div
            []
            [ FontAwesome.iconWithOptions
                FontAwesome.spinner
                FontAwesome.Solid
                [ FontAwesome.Animation FontAwesome.Spin, FontAwesome.Size FontAwesome.Large ]
                []
            ]
        )


simpleButton : { onPress : Maybe msg, label : Element msg } -> Element msg
simpleButton data =
    Input.button
        [ Background.color Colors.white
        , Font.color Colors.greyDarker
        , Font.bold
        , Element.padding 12
        , Border.rounded 50
        , Border.width 1
        , Border.color Colors.greyLighter
        , Element.mouseOver [ Font.color Colors.link ]
        ]
        data


type alias IconInfo a msg =
    { a | onPress : Maybe msg, icon : FontAwesome.Icon, text : Maybe String, tooltip : Maybe String }


iconButton : List (Element.Attribute msg) -> IconInfo a msg -> Element msg
iconButton attr { onPress, icon, tooltip } =
    Input.button []
        { onPress = onPress
        , label =
            Html.div [] [ FontAwesome.iconWithOptions icon FontAwesome.Solid [] [] ]
                |> Element.html
                |> Element.el
                    (case tooltip of
                        Just s ->
                            Element.htmlAttribute (Html.Attributes.title s)
                                :: attr

                        _ ->
                            attr
                    )
        }


type alias IconInfoLink a =
    { a | route : Route, icon : FontAwesome.Icon, text : Maybe String, tooltip : Maybe String }


iconLink : List (Element.Attribute msg) -> IconInfoLink a -> Element msg
iconLink attr { route, icon, text, tooltip } =
    Element.link []
        { url = Route.toUrl route
        , label =
            Html.div [] [ FontAwesome.iconWithOptions icon FontAwesome.Solid [] [] ]
                |> Element.html
                |> Element.el
                    (case tooltip of
                        Just s ->
                            Element.htmlAttribute (Html.Attributes.title s)
                                :: attr

                        _ ->
                            attr
                    )
        }


newTabIconLink : List (Element.Attribute msg) -> IconInfoLink a -> Element msg
newTabIconLink attr { route, icon, text, tooltip } =
    Element.newTabLink []
        { url = Route.toUrl route
        , label =
            Html.div [] [ FontAwesome.iconWithOptions icon FontAwesome.Solid [] [] ]
                |> Element.html
                |> Element.el
                    (case tooltip of
                        Just s ->
                            Element.htmlAttribute (Html.Attributes.title s)
                                :: attr

                        _ ->
                            attr
                    )
        }


downloadIconLink : List (Element.Attribute msg) -> IconInfoLink a -> Element msg
downloadIconLink attr { route, icon, text, tooltip } =
    Element.download []
        { url = Route.toUrl route
        , label =
            Html.div [] [ FontAwesome.iconWithOptions icon FontAwesome.Solid [] [] ]
                |> Element.html
                |> Element.el
                    (case tooltip of
                        Just s ->
                            Element.htmlAttribute (Html.Attributes.title s)
                                :: attr

                        _ ->
                            attr
                    )
        }


popup : Lang -> Popup msg -> Element msg
popup lang po =
    sizedPopup 1 lang po


sizedPopup : Int -> Lang -> Popup msg -> Element msg
sizedPopup size lang po =
    Element.row
        [ wf, hf, Background.color Colors.darkTransparent ]
        [ Element.el [ wf, hf ] Element.none
        , Element.column [ wf, hf ]
            [ Element.el [ wf, hf ] Element.none
            , Element.column [ wf, hf ]
                [ Element.el [ wf, Font.color Colors.white, Element.padding 10, Background.color Colors.navbar ]
                    (Element.el [ Element.centerX, Font.bold ] (Element.text po.title))
                , Element.el [ wf, hf, Background.color Colors.whiteBis ]
                    (Element.el
                        [ Element.centerX, Element.centerY, Font.center ]
                        (Element.paragraph [] [ Element.text po.message ])
                    )
                , Element.el
                    [ wf
                    , Element.padding 10
                    , Element.alignBottom
                    , Background.color Colors.whiteBis
                    ]
                    (Element.row [ Element.spacing 10, Element.alignRight ]
                        [ simpleButton { onPress = Just po.onCancel, label = Element.text (Lang.cancel lang) }
                        , primaryButton { onPress = Just po.onConfirm, label = Element.text (Lang.confirm lang) }
                        ]
                    )
                ]
            , Element.el [ hf ] Element.none
            ]
        , Element.el [ wf, hf ] Element.none
        ]


customSizedPopup : Int -> String -> Element msg -> Element msg
customSizedPopup size title content =
    Element.row
        [ wf, hf, Background.color Colors.darkTransparent ]
        [ Element.el [ wf, hf ] Element.none
        , Element.column [ wfp size, hf ]
            [ Element.el [ wf, hf ] Element.none
            , Element.column [ wf, hfp size ]
                [ Element.el [ wf, Font.color Colors.white, Element.padding 10, Background.color Colors.navbar ]
                    (Element.el [ Element.centerX, Font.bold ] (Element.text title))
                , content
                ]
            , Element.el [ hf ] Element.none
            ]
        , Element.el [ wf, hf ] Element.none
        ]


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


shrink : Int -> String -> String
shrink length string =
    if String.length string > length then
        string |> String.slice 0 length |> String.trim |> (\x -> x ++ " ...")

    else
        string


floatToString : Float -> String
floatToString float =
    let
        x =
            float * 100

        y =
            floor x

        z =
            toFloat y / 100
    in
    String.fromFloat z


diskSpace : Lang -> Float -> Float -> Element msg
diskSpace lang used max =
    Element.column [ Element.centerX, Element.spacing 10, Font.size 15 ]
        [ Element.el [ hf ] Element.none
        , Element.el [ hf, Element.centerX ] <| Element.text <| Lang.driveSpace lang
        , diskSpaceProgressBar (used / max)
        , Element.el [ hf, Element.centerX ] <|
            Element.text <|
                Lang.spaceUsed lang (floatToString used) (floatToString max)
        ]


diskSpaceProgressBar : Float -> Element msg
diskSpaceProgressBar value =
    let
        percentage =
            toFloat (Basics.floor (value * 10000)) / 100

        floor =
            Basics.floor percentage
    in
    Element.el [ wf, Element.height (Element.px 5) ]
        (Element.row [ wf, hf, Element.paddingXY 5 0 ]
            [ Element.el [ hf, wfp floor, Background.color Colors.navbar ] Element.none
            , Element.el [ hf, wfp (100 - floor), Background.color Colors.grey ] Element.none
            ]
        )
