module Production.Views exposing (..)

{-| Views for the production page.
-}

import App.Types as App
import App.Utils as App
import Config exposing (Config, TaskStatus)
import Data.Capsule as Data
import Data.Types as Data
import Data.User exposing (User)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Html.Events
import Json.Decode as Decode
import Production.Types as Production exposing (getWebcamSettings)
import Simple.Animation as Animation exposing (Animation)
import Simple.Animation.Animated as Animated
import Simple.Animation.Property as P
import Simple.Transition as Transition
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Utils as Ui
import Utils


{-| The full view of the page.
-}
view : Config -> User -> Production.Model Data.Capsule Data.Gos -> ( Element App.Msg, Element App.Msg )
view config user model =
    ( Element.row [ Ui.wf, Ui.hf, Ui.s 10, Ui.p 10 ]
        [ leftColumn config model
        , rightColumn config user model
        ]
    , Element.none
    )


{-| The column with the controls of the production settings.
-}
leftColumn : Config -> Production.Model Data.Capsule Data.Gos -> Element App.Msg
leftColumn config model =
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
            case getWebcamSettings model.capsule model.gos of
                Data.Pip { size } ->
                    Just (Tuple.first size)

                _ ->
                    Nothing

        -- Video opacity
        opacity : Float
        opacity =
            case getWebcamSettings model.capsule model.gos of
                Data.Pip pip ->
                    pip.opacity

                Data.Fullscreen fullscreen ->
                    fullscreen.opacity

                _ ->
                    1

        -- True if the gos has a record that contains only audio
        audioOnly : Bool
        audioOnly =
            Maybe.map .size model.gos.record == Just Nothing

        -- Gives the anchor if the webcam settings is Pip
        anchor : Maybe Data.Anchor
        anchor =
            case getWebcamSettings model.capsule model.gos of
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
        -- Reset to default options button
        resetButton =
            Ui.secondary
                []
                { label = Element.text <| Strings.stepsProductionResetOptions lang
                , action =
                    case model.gos.webcamSettings of
                        Just _ ->
                            Ui.Msg <| App.ProductionMsg Production.ResetOptions

                        Nothing ->
                            Ui.None
                }

        -- Whether the user wants to include the video inside the slides or not
        useVideo =
            (disableIf <| model.gos.record == Nothing || audioOnly)
                Input.checkbox
                []
                { checked = model.gos.record /= Nothing && model.gos.webcamSettings /= Just Data.Disabled
                , icon = Input.defaultCheckbox
                , label = Input.labelRight [] <| Element.text <| Strings.stepsProductionUseVideo lang
                , onChange = \_ -> App.ProductionMsg Production.ToggleVideo
                }

        -- Text that explains why the user can't use the video (if they can't)
        useVideoInfo =
            case Maybe.map .size model.gos.record of
                Nothing ->
                    Ui.paragraph [] <| Strings.stepsProductionCantUseVideoBecauseNoRecord lang ++ "."

                Just Nothing ->
                    Ui.paragraph [] <| Strings.stepsProductionCantUserVideoBecauseAudioOnly lang ++ "."

                _ ->
                    Element.none

        -- Whether the webcam size is disabled
        webcamSizeDisabled =
            model.gos.record == Nothing || audioOnly || model.gos.webcamSettings == Just Data.Disabled

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
                                App.ProductionMsg <| Production.SetWidth <| Just y

                            _ ->
                                App.Noop
                , placeholder = Nothing
                , text = Maybe.map String.fromInt width |> Maybe.withDefault ""
                }

        -- Element to choose the webcam size among small, medium, large, fullscreen
        webcamSizeRadio =
            (disableIf <| model.gos.record == Nothing || audioOnly || model.gos.webcamSettings == Just Data.Disabled)
                Input.radio
                [ Ui.s 10 ]
                { label = Input.labelHidden <| Strings.stepsProductionWebcamSize lang
                , onChange = \x -> App.ProductionMsg <| Production.SetWidth <| x
                , options =
                    [ Input.option (Just 200) <| Element.text <| Strings.stepsProductionSmall lang
                    , Input.option (Just 400) <| Element.text <| Strings.stepsProductionMedium lang
                    , Input.option (Just 800) <| Element.text <| Strings.stepsProductionLarge lang
                    , Input.option Nothing <| Element.text <| Strings.stepsProductionFullscreen lang
                    , Input.option (Just 533) <| Element.text <| Strings.stepsProductionCustom lang
                    ]
                , selected =
                    case getWebcamSettings model.capsule model.gos of
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
            model.gos.record == Nothing || audioOnly || model.gos.webcamSettings == Just Data.Disabled

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
                , onChange = \x -> App.ProductionMsg <| Production.SetAnchor x
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
            model.gos.record == Nothing || audioOnly || model.gos.webcamSettings == Just Data.Disabled

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
                    { onChange = \x -> App.ProductionMsg <| Production.SetOpacity x
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
                    |> round
                    |> String.fromInt
                    |> (\x -> x ++ "%")
                    |> Element.text
                    |> Element.el (Ui.wfp 1 :: Ui.ab :: disableAttrIf opacityDisabled)
                ]
    in
    Element.column [ Ui.wfp 1, Ui.s 30, Ui.at ]
        [ resetButton
        , Element.column [ Ui.s 10 ]
            [ useVideo
            , useVideoInfo
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


{-| The column with the slide view and the production button.
-}
rightColumn : Config -> User -> Production.Model Data.Capsule Data.Gos -> Element App.Msg
rightColumn config user model =
    let
        lang =
            config.clientState.lang

        -- overlay to show a frame of the record on the slide (if any)
        overlay =
            case ( getWebcamSettings model.capsule model.gos, model.gos.record ) of
                ( Data.Pip s, Just r ) ->
                    let
                        ( ( marginX, marginY ), ( w, h ) ) =
                            ( model.webcamPosition, Tuple.mapBoth toFloat toFloat s.size )

                        ( x, y ) =
                            case s.anchor of
                                Data.TopLeft ->
                                    ( marginX, marginY )

                                Data.TopRight ->
                                    ( 1920 - w - marginX, marginY )

                                Data.BottomLeft ->
                                    ( marginX, 1080 - h - marginY )

                                Data.BottomRight ->
                                    ( 1920 - w - marginX, 1080 - h - marginY )

                        tp =
                            100 * y / 1080

                        lp =
                            100 * x / 1920

                        bp =
                            100 * (1080 - y - h) / 1080

                        rp =
                            100 * (1920 - x - w) / 1920
                    in
                    Element.el
                        [ Element.htmlAttribute (Html.Attributes.style "position" "absolute")
                        , Element.htmlAttribute (Html.Attributes.style "top" (String.fromFloat tp ++ "%"))
                        , Element.htmlAttribute (Html.Attributes.style "left" (String.fromFloat lp ++ "%"))
                        , Element.htmlAttribute (Html.Attributes.style "right" (String.fromFloat rp ++ "%"))
                        , Element.htmlAttribute (Html.Attributes.style "bottom" (String.fromFloat bp ++ "%"))
                        ]
                        (Element.image
                            [ Ui.id Production.miniatureId
                            , Element.alpha s.opacity
                            , Ui.wf
                            , Ui.hf
                            , Decode.map3 (\z pageX pageY -> App.ProductionMsg (Production.HoldingImageChanged (Just ( z, pageX, pageY ))))
                                (Decode.field "pointerId" Decode.int)
                                (Decode.field "pageX" Decode.float)
                                (Decode.field "pageY" Decode.float)
                                |> Html.Events.on "pointerdown"
                                |> Element.htmlAttribute
                            , Decode.succeed (App.ProductionMsg (Production.HoldingImageChanged Nothing))
                                |> Html.Events.on "pointerup"
                                |> Element.htmlAttribute
                            , Element.htmlAttribute
                                (Html.Events.custom "dragstart"
                                    (Decode.succeed
                                        { message = App.Noop
                                        , preventDefault = True
                                        , stopPropagation = True
                                        }
                                    )
                                )
                            ]
                            { src = Data.assetPath model.capsule (r.uuid ++ ".png")
                            , description = ""
                            }
                        )

                ( Data.Fullscreen { opacity }, Just r ) ->
                    Element.el
                        [ Element.alpha opacity
                        , Ui.hf
                        , Ui.wf
                        , ("center / contain content-box no-repeat url('"
                            ++ Data.assetPath model.capsule (r.uuid ++ ".png")
                            ++ "')"
                          )
                            |> Html.Attributes.style "background"
                            |> Element.htmlAttribute
                        ]
                        Element.none

                _ ->
                    Element.none

        -- The display of the slide
        slide =
            case model.gos.slides of
                h :: _ ->
                    Element.image [ Ui.wf, Ui.b 1, Border.color Colors.greyBorder ]
                        { src = Data.slidePath model.capsule h
                        , description = ""
                        }

                _ ->
                    Element.none

        -- The button to produce the video
        produceButton =
            let
                ready2Product : Bool
                ready2Product =
                    case model.capsule.produced of
                        Data.Running _ ->
                            False

                        _ ->
                            True

                action : App.Msg
                action =
                    Utils.tern
                        ready2Product
                        (App.ProductionMsg Production.Produce)
                        App.Noop

                spinnerElement : Element App.Msg
                spinnerElement =
                    Element.el
                        [ Ui.wf
                        , Ui.hf
                        , Font.color <| Utils.tern ready2Product Colors.transparent Colors.white
                        ]
                    <|
                        Ui.spinningSpinner [ Ui.cx, Ui.cy ] 18

                label : Element App.Msg
                label =
                    Element.el
                        [ Font.color <| Utils.tern ready2Product Colors.white Colors.transparent
                        , Element.inFront spinnerElement
                        ]
                    <|
                        Element.text <|
                            Strings.stepsProductionProduceVideo lang
            in
            Ui.primary [ Ui.ar ]
                { action = Ui.Msg <| action
                , label = label
                }

        -- The production progress bar
        progressBar : Element App.Msg
        progressBar =
            case model.capsule.produced of
                Data.Running a ->
                    let
                        loadingAnimation : Animation
                        loadingAnimation =
                            Animation.steps
                                { startAt = [ P.x -300 ]
                                , options = [ Animation.loop ]
                                }
                                [ Animation.step 1000 [ P.x 300 ]
                                , Animation.wait 100
                                , Animation.step 1000 [ P.x -300 ]
                                , Animation.wait 100
                                ]

                        bar : Element App.Msg
                        bar =
                            case a of
                                Just progress ->
                                    Element.el
                                        [ Ui.wf
                                        , Ui.hf
                                        , Ui.r 5
                                        , Element.moveLeft (300.0 * (1.0 - progress))
                                        , Background.color Colors.green2
                                        , Element.htmlAttribute <|
                                            Transition.properties [ Transition.transform 200 [ Transition.easeInOut ] ]
                                        ]
                                        Element.none

                                Nothing ->
                                    Animated.ui
                                        { behindContent = Element.behindContent
                                        , htmlAttribute = Element.htmlAttribute
                                        , html = Element.html
                                        }
                                        (\attr el -> Element.el attr el)
                                        loadingAnimation
                                        [ Ui.wf, Ui.hf, Ui.r 5, Background.color Colors.green2 ]
                                        Element.none
                    in
                    Element.el
                        [ Ui.p 5
                        , Ui.wpx 300
                        , Ui.hpx 30
                        , Ui.r 20
                        , Ui.ar
                        , Background.color <| Colors.alpha 0.1
                        , Border.shadow
                            { size = 1
                            , blur = 8
                            , color = Colors.alpha 0.1
                            , offset = ( 0, 0 )
                            }
                        ]
                    <|
                        Element.el
                            [ Ui.wf
                            , Element.htmlAttribute <| Html.Attributes.style "overflow" "hidden"
                            , Ui.r 100
                            , Ui.hf
                            ]
                            bar

                _ ->
                    Element.none

        -- Link to watch the video
        videoLink =
            case Data.videoPath model.capsule of
                Just path ->
                    Ui.link [] { label = Strings.stepsProductionWatchVideo lang, action = Ui.NewTab path }

                _ ->
                    Element.none
    in
    Element.column [ Ui.at, Ui.wfp 3, Ui.s 10 ]
        [ Element.el [ Ui.wf, Ui.cy, Element.inFront overlay, Element.clip ] slide
        , Element.row [ Ui.ar, Ui.s 10 ] [ videoLink, produceButton ]
        , progressBar
        ]
