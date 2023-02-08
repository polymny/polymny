module Options.Views exposing (..)

import App.Types as App
import Config exposing (Config)
import Data.Capsule as Data
import Data.User exposing (User)
import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Options.Types as Options
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Utils as Ui


view : Config -> User -> Options.Model -> ( Element App.Msg, Element App.Msg )
view config user model =
    let
        -- Helper to create section titles
        title : String -> Element App.Msg
        title input =
            Element.el [ Font.size 30, Font.underline ] (Element.text input)
    in
    ( Element.row []
        [ Element.column [ Ui.s 10, Ui.p 100 ]
            [ "Options de production par défaut"
                |> title
            , Element.column [ Ui.s 10, Ui.pt 20, Ui.wf ]
                [ defaultProd config model
                ]
            ]
        , Element.column [ Ui.s 10, Ui.p 100 ]
            [ "Options générales\n(TODO with sound track and backrgound)"
                |> title
            , Element.column [ Ui.s 10 ]
                []
            ]
        ]
    , Element.none
    )


defaultProd : Config -> Options.Model -> Element App.Msg
defaultProd config model =
    let
        --- HELPERS ---
        -- Shortcut for lang
        lang =
            config.clientState.lang

        -- Helper to create section titles
        title : Bool -> String -> Element App.Msg
        title disabled input =
            Element.text input
                |> Element.el (disableAttrIf disabled ++ [ Font.size 22, Font.bold ])

        -- Video width if pip
        width : Maybe Int
        width =
            case model.capsule.defaultWebcamSettings of
                Data.Pip { size } ->
                    Just (Tuple.first size)

                _ ->
                    Nothing

        -- Video opacity
        opacity : Float
        opacity =
            case model.capsule.defaultWebcamSettings of
                Data.Pip pip ->
                    pip.opacity

                Data.Fullscreen fullscreen ->
                    fullscreen.opacity

                _ ->
                    1

        -- Gives the anchor if the webcam settings is Pip
        anchor : Maybe Data.Anchor
        anchor =
            case model.capsule.defaultWebcamSettings of
                Data.Pip p ->
                    Just p.anchor

                _ ->
                    Nothing

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
            Input.checkbox
                []
                { checked = model.capsule.defaultWebcamSettings /= Data.Disabled
                , icon = Input.defaultCheckbox
                , label = Input.labelRight [] <| Element.text <| Strings.stepsProductionUseVideo lang
                , onChange = \_ -> App.OptionsMsg Options.ToggleVideo
                }

        -- Whether the webcam size is disabled
        webcamSizeDisabled =
            model.capsule.defaultWebcamSettings == Data.Disabled

        --  Title to introduce webcam size settings
        webcamSizeTitle =
            Strings.stepsProductionWebcamSize lang
                |> title webcamSizeDisabled

        -- Element to control the webcam size
        webcamSizeText =
            disableIf webcamSizeDisabled
                Input.text
                [ Element.htmlAttribute <| Html.Attributes.type_ "number"
                , Element.htmlAttribute <| Html.Attributes.min "10"
                ]
                { label = Input.labelHidden <| Strings.stepsProductionCustom lang
                , onChange =
                    \x ->
                        case String.toInt x of
                            Just y ->
                                App.OptionsMsg <| Options.SetWidth <| Just y

                            _ ->
                                App.Noop
                , placeholder = Nothing
                , text = Maybe.map String.fromInt width |> Maybe.withDefault ""
                }

        -- Element to choose the webcam size among small, medium, large, fullscreen
        webcamSizeRadio =
            (disableIf <| model.capsule.defaultWebcamSettings == Data.Disabled)
                Input.radio
                [ Ui.s 10 ]
                { label = Input.labelHidden <| Strings.stepsProductionWebcamSize lang
                , onChange = \x -> App.OptionsMsg <| Options.SetWidth x
                , options =
                    [ Input.option (Just 200) <| Element.text <| Strings.stepsProductionSmall lang
                    , Input.option (Just 400) <| Element.text <| Strings.stepsProductionMedium lang
                    , Input.option (Just 800) <| Element.text <| Strings.stepsProductionLarge lang
                    , Input.option Nothing <| Element.text <| Strings.stepsProductionFullscreen lang
                    , Input.option (Just 533) <| Element.text <| Strings.stepsProductionCustom lang
                    ]
                , selected =
                    case model.capsule.defaultWebcamSettings of
                        Data.Pip { size } ->
                            if List.member (Tuple.first size) [ 200, 400, 800 ] then
                                Just <| Just <| Tuple.first size

                            else
                                Just <| Just 533

                        Data.Fullscreen _ ->
                            Just Nothing

                        Data.Disabled ->
                            Nothing
                }

        -- Whether the webcam position is disabled
        webcamPositionDisabled =
            model.capsule.defaultWebcamSettings == Data.Disabled

        -- Title to introduce webcam position settings
        webcamPositionTitle =
            Strings.stepsProductionWebcamPosition lang
                |> title webcamPositionDisabled

        -- Element to choose the webcam position among the four corners
        webcamPositionRadio =
            disableIf webcamPositionDisabled
                Input.radio
                [ Ui.s 10 ]
                { label = Input.labelHidden <| Strings.stepsProductionWebcamPosition lang
                , onChange = \x -> App.OptionsMsg <| Options.SetAnchor x
                , options =
                    [ Input.option Data.TopLeft <| Element.text <| Strings.stepsProductionTopLeft lang
                    , Input.option Data.TopRight <| Element.text <| Strings.stepsProductionTopRight lang
                    , Input.option Data.BottomLeft <| Element.text <| Strings.stepsProductionBottomLeft lang
                    , Input.option Data.BottomRight <| Element.text <| Strings.stepsProductionBottomRight lang
                    ]
                , selected = anchor
                }

        -- Whether the user can control the opacity
        opacityDisabled =
            model.capsule.defaultWebcamSettings == Data.Disabled

        -- Title to introduce webcam opacity settings
        opacityTitle =
            Strings.stepsProductionOpacity lang
                |> title opacityDisabled

        -- Slider to control opacity
        opacitySlider =
            Element.row [ Ui.wf, Ui.hf, Ui.s 10 ]
                [ -- Slider for the control
                  disableIf opacityDisabled
                    Input.slider
                    [ Element.behindContent <| Element.el [ Ui.wf, Ui.hpx 2, Ui.cy, Background.color Colors.greyBorder ] Element.none
                    ]
                    { onChange = \x -> App.OptionsMsg <| Options.SetOpacity x
                    , label = Input.labelHidden <| Strings.stepsProductionOpacity lang
                    , max = 1
                    , min = 0
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
                    |> Element.el (Ui.wfp 1 :: Ui.ab :: disableAttrIf opacityDisabled)
                ]
    in
    Element.column [ Ui.wfp 1, Ui.s 30, Ui.at ]
        [ Element.column [ Ui.s 10 ]
            [ useVideo
            ]
        , Element.column [ Ui.s 10 ]
            [ webcamSizeTitle
            , webcamSizeRadio
            , webcamSizeText
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
