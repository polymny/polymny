module Production.Views exposing (..)

{-| Views for the production page.
-}

import App.Types as App
import Config exposing (Config)
import Data.Capsule as Data
import Data.User exposing (User)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Production.Types as Production
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Utils as Ui


{-| The full view of the page.
-}
view : Config -> User -> Production.Model -> ( Element App.Msg, Element App.Msg )
view config user model =
    case List.drop model.gos model.capsule.structure of
        h :: _ ->
            ( Element.row [ Ui.wf, Ui.hf, Ui.s 10, Ui.p 10 ]
                [ leftColumn config model h
                , rightColumn config model h
                ]
            , Element.none
            )

        _ ->
            ( Element.none, Element.none )


{-| The column with the controls of the production settings.
-}
leftColumn : Config -> Production.Model -> Data.Gos -> Element App.Msg
leftColumn config model gos =
    let
        --- HELPERS ---
        -- Shortcut for lang
        lang =
            config.clientState.lang

        -- Helper to create paragraphs
        paragraph : String -> Element msg
        paragraph input =
            Element.paragraph [] [ Element.text input ]

        -- Helper to create section titles
        title : Bool -> String -> Element App.Msg
        title disabled input =
            Element.text input
                |> Element.el (disableAttrIf disabled ++ [ Font.size 22, Font.bold ])

        -- Video width if pip
        width : Maybe Int
        width =
            case gos.webcamSettings of
                Data.Pip { size } ->
                    Just (Tuple.first size)

                _ ->
                    Nothing

        -- Video opacity
        opacity : Float
        opacity =
            case gos.webcamSettings of
                Data.Pip pip ->
                    pip.opacity

                Data.Fullscreen fullscreen ->
                    fullscreen.opacity

                _ ->
                    1

        -- True if the gos has a record that contains only audio
        audioOnly : Bool
        audioOnly =
            Maybe.map .size gos.record == Just Nothing

        -- Attributes to show things as disabled
        disableAttr : List (Element.Attribute App.Msg)
        disableAttr =
            [ Font.color Colors.greyFontDisabled ]

        -- Gives disable attributes if element is disabled
        disableAttrIf : Bool -> List (Element.Attribute App.Msg)
        disableAttrIf disabled =
            if disabled then
                disableAttr

            else
                []

        -- Gives disable attributes and remove msg if element is disabled
        disableIf :
            Bool
            -> (List (Element.Attribute App.Msg) -> { a | onChange : b -> App.Msg } -> Element App.Msg)
            -> List (Element.Attribute App.Msg)
            -> { a | onChange : b -> App.Msg }
            -> Element App.Msg
        disableIf disabled constructor attributes parameters =
            if disabled then
                constructor (disableAttr ++ attributes) { parameters | onChange = \_ -> App.Noop }

            else
                constructor attributes parameters

        --- UI ELEMENTS ---
        -- Whether the user wants to include the video inside the slides or not
        useVideo =
            (disableIf <| gos.record == Nothing || audioOnly)
                Input.checkbox
                []
                { checked = gos.record /= Nothing && gos.webcamSettings /= Data.Disabled
                , icon = Input.defaultCheckbox
                , label = Input.labelRight [] <| Element.text <| Strings.stepsProductionUseVideo lang
                , onChange = \_ -> App.Noop
                }

        -- Text that explains why the user can't use the video (if they can't)
        useVideoInfo =
            case Maybe.map .size gos.record of
                Nothing ->
                    paragraph <| Strings.stepsProductionCantUseVideoBecauseNoRecord lang ++ "."

                Just Nothing ->
                    paragraph <| Strings.stepsProductionCantUserVideoBecauseAudioOnly lang ++ "."

                _ ->
                    Element.none

        --  Title to introduce webcam size settings
        webcamSizeTitle =
            title (gos.record == Nothing || audioOnly) <| Strings.stepsProductionWebcamSize lang

        -- Element to control the webcam size
        webcamSizeText =
            (disableIf <| gos.record == Nothing || audioOnly)
                Input.text
                [ Element.htmlAttribute <| Html.Attributes.type_ "number" ]
                { label = Input.labelHidden <| Strings.stepsProductionCustom lang
                , onChange = \_ -> App.Noop
                , placeholder = Nothing
                , text = Maybe.map String.fromInt width |> Maybe.withDefault ""
                }

        -- Element to choose the webcam size among small, medium, large, fullscreen
        webcamSizeRadio =
            (disableIf <| gos.record == Nothing || audioOnly)
                Input.radio
                [ Ui.s 10 ]
                { label = Input.labelHidden <| Strings.stepsProductionWebcamSize lang
                , onChange = \_ -> App.Noop
                , options =
                    [ Input.option 200 <| Element.text <| Strings.stepsProductionSmall lang
                    , Input.option 400 <| Element.text <| Strings.stepsProductionMedium lang
                    , Input.option 800 <| Element.text <| Strings.stepsProductionLarge lang
                    , Input.option 0 <| Element.text <| Strings.stepsProductionFullscreen lang
                    , Input.option 0 <| Element.text <| Strings.stepsProductionCustom lang
                    ]
                , selected = width
                }

        -- Title to introduce webcam position settings
        webcamPositionTitle =
            title (gos.record == Nothing || audioOnly) <| Strings.stepsProductionWebcamPosition lang

        -- Element to choose the webcam position among the four corners
        webcamPositionRadio =
            (disableIf <| gos.record == Nothing || audioOnly)
                Input.radio
                [ Ui.s 10 ]
                { label = Input.labelHidden <| Strings.stepsProductionWebcamPosition lang
                , onChange = \_ -> App.Noop
                , options =
                    [ Input.option 0 <| Element.text <| Strings.stepsProductionTopLeft lang
                    , Input.option 0 <| Element.text <| Strings.stepsProductionTopRight lang
                    , Input.option 0 <| Element.text <| Strings.stepsProductionBottomLeft lang
                    , Input.option 0 <| Element.text <| Strings.stepsProductionBottomRight lang
                    ]
                , selected = Nothing
                }

        -- Title to introduce webcam opacity settings
        opacityTitle =
            title (gos.record == Nothing || audioOnly) <| Strings.stepsProductionOpacity lang

        -- Slider to control opacity
        opacitySlider =
            Element.row [ Ui.wf, Ui.hf, Ui.s 10 ]
                [ -- Slider for the control
                  (disableIf <| gos.record == Nothing || audioOnly)
                    Input.slider
                    [ Element.behindContent <| Element.el [ Ui.wf, Ui.hpx 2, Ui.cy, Background.color Colors.greyBorder ] Element.none
                    ]
                    { onChange = \_ -> App.Noop
                    , label = Input.labelHidden <| Strings.stepsProductionOpacity lang
                    , max = 0
                    , min = 1
                    , step = Just 0.1
                    , thumb = Input.defaultThumb
                    , value = opacity
                    }
                , -- Text label of the opacity value
                  opacity
                    * 100
                    |> floor
                    |> String.fromInt
                    |> (\x -> x ++ "%")
                    |> Element.text
                    |> Element.el [ Ui.wfp 1, Ui.ab ]
                ]
    in
    Element.column [ Ui.wfp 1, Ui.s 30, Ui.at ]
        [ Element.column [ Ui.s 10 ]
            [ useVideo
            , useVideoInfo
            ]
        , Element.column [ Ui.s 10 ]
            [ webcamSizeTitle
            , webcamSizeText
            , webcamSizeRadio
            ]
        , Element.column [ Ui.s 10 ]
            [ webcamPositionTitle
            , webcamPositionRadio
            ]
        , Element.column [ Ui.wf, Ui.s 10 ]
            [ opacityTitle
            , opacitySlider
            ]
        ]


{-| The column with the slide view and the production button.
-}
rightColumn : Config -> Production.Model -> Data.Gos -> Element App.Msg
rightColumn config model gos =
    let
        lang =
            config.clientState.lang

        -- The display of the slide
        slide =
            case gos.slides of
                h :: _ ->
                    Element.image [ Ui.wf, Ui.b 1, Border.color Colors.greyBorder ]
                        { src = Data.slidePath model.capsule h
                        , description = ""
                        }

                _ ->
                    Element.none

        -- The button to produce the video
        produceButton =
            Ui.primary [ Ui.ar ]
                { action = Ui.Msg <| App.ProductionMsg <| Production.Produce
                , label = Strings.stepsProductionProduceVideo lang
                }
    in
    Element.column [ Ui.at, Ui.wfp 3, Ui.s 10 ]
        [ slide
        , produceButton
        ]
