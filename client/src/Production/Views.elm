module Production.Views exposing (..)

import Capsule
import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input
import Html
import Html.Attributes
import Html.Events
import Lang
import Production.Types as Production
import Route
import Ui.Colors as Colors
import Ui.Utils as Ui
import User exposing (User)
import Utils exposing (isJust)


view : Core.Global -> User -> Production.Model -> ( Element Core.Msg, Maybe (Element Core.Msg) )
view global user model =
    let
        gos : Maybe Capsule.Gos
        gos =
            List.head (List.drop model.gos model.capsule.structure)

        firstSlide : Maybe Capsule.Slide
        firstSlide =
            Maybe.andThen (\x -> List.head x.slides) gos
    in
    case ( gos, firstSlide ) of
        ( Just g, Just s ) ->
            ( Element.column [ Ui.wf, Ui.hf, Element.padding 10 ]
                [ Element.row [ Ui.wf, Ui.hf, Element.spacing 10 ]
                    [ Element.el [ Ui.wfp 1, Ui.hf ] (leftColumn global user model g)
                    , Element.el [ Ui.wfp 3, Ui.hf ] (mainView global user model g s)
                    ]
                , bottomBar global user model
                ]
            , Nothing
            )

        _ ->
            ( Element.el [ Ui.wf, Ui.hf ] Element.none, Nothing )


leftColumn : Core.Global -> User -> Production.Model -> Capsule.Gos -> Element Core.Msg
leftColumn global user _ gos =
    let
        webcamSettings =
            case gos.webcamSettings of
                Capsule.Pip w ->
                    w

                _ ->
                    Capsule.defaultPip

        forceDisabled =
            Maybe.andThen .size gos.record == Nothing

        forceDisabledAttr =
            if forceDisabled then
                Ui.disabled

            else
                []

        forceDisableMsg : Core.Msg -> Core.Msg
        forceDisableMsg msg =
            if forceDisabled then
                Core.Noop

            else
                msg

        forceDisableSelected : Maybe a -> Maybe a
        forceDisableSelected x =
            if forceDisabled then
                Nothing

            else
                x

        forceDisableInfo : Element Core.Msg
        forceDisableInfo =
            Element.paragraph forceDisabledAttr
                [ case Maybe.map .size gos.record of
                    Nothing ->
                        Element.text (Lang.cantUseVideoBecauseNoRecord global.lang)

                    Just Nothing ->
                        Element.text (Lang.cantUseVideoBecauseAudioOnly global.lang)

                    _ ->
                        Element.none
                ]

        disabled =
            forceDisabled || gos.webcamSettings == Capsule.Disabled

        disabledAttr =
            if disabled then
                Ui.disabled

            else
                []

        disableMsg : Core.Msg -> Core.Msg
        disableMsg msg =
            if disabled then
                Core.Noop

            else
                msg

        disableSelected : Maybe a -> Maybe a
        disableSelected x =
            if disabled then
                Nothing

            else
                x

        currentOpacity =
            case gos.webcamSettings of
                Capsule.Pip { opacity } ->
                    opacity

                Capsule.Fullscreen { opacity } ->
                    opacity

                _ ->
                    webcamSettings.opacity

        currentKeyColor =
            case gos.webcamSettings of
                Capsule.Pip { keycolor } ->
                    keycolor

                Capsule.Fullscreen { keycolor } ->
                    keycolor

                _ ->
                    Nothing
    in
    Element.column [ Ui.wf, Element.centerY, Element.spacing 30 ]
        [ Input.checkbox []
            { checked = gos.webcamSettings /= Capsule.Disabled && not forceDisabled
            , icon = Input.defaultCheckbox
            , label = Input.labelRight forceDisabledAttr (Element.text (Lang.useVideo global.lang))
            , onChange = \x -> Core.ProductionMsg (Production.SetVideo x) |> forceDisableMsg
            }
        , forceDisableInfo
        , Input.radio (Element.spacing 10 :: disabledAttr)
            { onChange = \s -> Core.ProductionMsg (Production.WebcamSizeChanged s) |> disableMsg
            , selected =
                (case gos.webcamSettings of
                    Capsule.Fullscreen { opacity } ->
                        Just Production.Fullscreen

                    _ ->
                        Production.intToSize webcamSettings.size
                )
                    |> disableSelected
            , label =
                Input.labelAbove
                    (Element.paddingXY 0 10 :: disabledAttr ++ Ui.formTitle)
                    (Element.text (Lang.webcamSize global.lang))
            , options =
                [ Input.option Production.Small (Element.text (Lang.small global.lang))
                , Input.option Production.Medium (Element.text (Lang.medium global.lang))
                , Input.option Production.Large (Element.text (Lang.large global.lang))
                , Input.option Production.Fullscreen (Element.text (Lang.fullscreen global.lang))
                ]
            }
        , Input.radio (Element.spacing 10 :: disabledAttr)
            { onChange = \s -> Core.ProductionMsg (Production.WebcamAnchorChanged s) |> disableMsg
            , selected = Just webcamSettings.anchor |> disableSelected
            , label =
                Input.labelAbove
                    (Element.paddingXY 0 10 :: disabledAttr ++ Ui.formTitle)
                    (Element.text (Lang.webcamAnchor global.lang))
            , options =
                [ Input.option Capsule.TopLeft (Element.text (Lang.topLeft global.lang))
                , Input.option Capsule.TopRight (Element.text (Lang.topRight global.lang))
                , Input.option Capsule.BottomLeft (Element.text (Lang.bottomLeft global.lang))
                , Input.option Capsule.BottomRight (Element.text (Lang.bottomRight global.lang))
                ]
            }
        , Element.row (Ui.wf :: Ui.hf :: Element.spacing 10 :: disabledAttr)
            [ Input.slider
                [ Element.behindContent
                    (Element.el
                        [ Element.width Element.fill
                        , Element.height (Element.px 2)
                        , Element.centerY
                        , Background.color Colors.grey
                        , Border.rounded 2
                        ]
                        Element.none
                    )
                ]
                { label = Input.labelAbove (disabledAttr ++ Ui.formTitle) (Element.text (Lang.opacity global.lang))
                , min = 0
                , max = 1
                , onChange = \x -> Core.ProductionMsg (Production.WebcamOpacityChanged x) |> disableMsg
                , step = Just 0.1
                , thumb = Input.defaultThumb
                , value = currentOpacity
                }
                |> Element.el [ Ui.wfp 5 ]
            , currentOpacity
                * 100
                |> floor
                |> String.fromInt
                |> (\x -> x ++ "%")
                |> Element.text
                |> Element.el [ Ui.wfp 1, Element.alignBottom ]
            ]
        , if User.isPremium user then
            Element.el (Ui.formTitle ++ disabledAttr) (Element.text (Lang.key global.lang))

          else
            Element.none
        , if User.isPremium user then
            Input.checkbox
                disabledAttr
                { checked = isJust currentKeyColor
                , icon = Input.defaultCheckbox
                , label = Input.labelRight forceDisabledAttr (Element.text (Lang.activateKeying global.lang))
                , onChange =
                    \x ->
                        Core.ProductionMsg
                            (Production.WebcamKeyColorChanged
                                (case currentKeyColor of
                                    Just _ ->
                                        Nothing

                                    Nothing ->
                                        Just "#00FF00"
                                )
                            )
                            |> forceDisableMsg
                }

          else
            Element.none
        , if User.isPremium user then
            Element.row disabledAttr
                [ Element.el
                    (if isJust currentKeyColor then
                        []

                     else
                        Ui.disabled
                    )
                    (Element.text (Lang.keyColor global.lang))
                , Element.el [ Element.paddingEach { left = 10, right = 0, top = 0, bottom = 0 } ]
                    (Element.html
                        (Html.input
                            [ Html.Attributes.type_ "color"
                            , Html.Attributes.value (Maybe.withDefault "#00FF00" currentKeyColor)
                            , Html.Attributes.disabled (not (isJust currentKeyColor))
                            , Html.Events.onInput
                                (\x ->
                                    Core.ProductionMsg
                                        (Production.WebcamKeyColorChanged
                                            (Maybe.map (\_ -> x) currentKeyColor)
                                        )
                                        |> disableMsg
                                )
                            ]
                            []
                        )
                    )
                ]

          else
            Element.none

        --Input.text []
        --  { label = Input.labelHidden ""
        --  , onChange = \x -> Core.ProductionMsg (Production.WebcamKeyColorChanged x) |> disableMsg
        --  , placeholder = Just (Input.placeholder [] (Element.text (Lang.keyColor global.lang)))
        --  , text = currentKeyColor
        --  }
        ]


mainView : Core.Global -> User -> Production.Model -> Capsule.Gos -> Capsule.Slide -> Element Core.Msg
mainView global user model gos slide =
    let
        image : Element Core.Msg
        image =
            case ( gos.slides, slide.extra ) of
                ( _ :: [], Just path ) ->
                    Element.el
                        [ Ui.wf
                        , Element.centerY
                        , Border.width 1
                        , Border.color Colors.greyLighter
                        ]
                        (Element.html
                            (Html.video
                                [ Html.Attributes.controls False, Html.Attributes.class "wf" ]
                                [ Html.source [ Html.Attributes.src (Capsule.assetPath model.capsule (path ++ ".mp4")) ] [] ]
                            )
                        )

                _ ->
                    Element.image
                        [ Ui.wf
                        , Element.centerY
                        , Border.width 1
                        , Border.color Colors.greyLighter
                        ]
                        { src = Capsule.slidePath model.capsule slide, description = "" }

        overlay : Element Core.Msg
        overlay =
            case ( gos.webcamSettings, gos.record ) of
                ( Capsule.Pip s, Just r ) ->
                    let
                        align =
                            case s.anchor of
                                Capsule.TopLeft ->
                                    [ Element.alignTop, Element.alignLeft ]

                                Capsule.TopRight ->
                                    [ Element.alignTop, Element.alignRight ]

                                Capsule.BottomLeft ->
                                    [ Element.alignBottom, Element.alignLeft ]

                                Capsule.BottomRight ->
                                    [ Element.alignBottom, Element.alignRight ]

                        percentage =
                            (Tuple.first s.size * 100 // 1920 |> String.fromInt) ++ "%"
                    in
                    Element.el (Element.htmlAttribute (Html.Attributes.style "width" percentage) :: align)
                        (Element.image [ Element.alpha s.opacity, Ui.wf, Ui.hf ]
                            { src = Capsule.assetPath model.capsule (r.uuid ++ ".png")
                            , description = ""
                            }
                        )

                ( Capsule.Fullscreen { opacity }, Just r ) ->
                    Element.el
                        [ Element.alpha opacity
                        , Ui.hf
                        , Ui.wf
                        , ("center / contain content-box no-repeat url('"
                            ++ Capsule.assetPath model.capsule (r.uuid ++ ".png")
                            ++ "')"
                          )
                            |> Html.Attributes.style "background"
                            |> Element.htmlAttribute
                        ]
                        Element.none

                _ ->
                    Element.none
    in
    Element.el [ Ui.wf, Element.centerY, Element.inFront overlay ] image


bottomBar : Core.Global -> User -> Production.Model -> Element Core.Msg
bottomBar global user model =
    let
        produceInfo =
            case ( model.capsule.published, Capsule.videoPath model.capsule ) of
                ( Capsule.Done, _ ) ->
                    Ui.newTabLink []
                        { label = Element.text (Lang.watchVideo global.lang)
                        , route = Route.Custom (global.videoRoot ++ "/" ++ model.capsule.id ++ "/")
                        }

                ( _, Just path ) ->
                    Ui.newTabLink []
                        { label = Element.text (Lang.watchVideo global.lang)
                        , route = Route.Custom path
                        }

                _ ->
                    Element.none

        produceButton =
            case model.capsule.produced of
                Capsule.Running msg ->
                    Element.row []
                        [ Element.row [ Element.spacing 10 ]
                            [ Ui.primaryButton
                                { label =
                                    Element.row []
                                        [ Element.text (Lang.producing global.lang)
                                        , Element.el [ Element.paddingEach { left = 10, right = 0, top = 0, bottom = 0 } ]
                                            Ui.spinner
                                        ]
                                , onPress = Nothing
                                }
                            , Ui.primaryButton
                                { label = Element.text (Lang.cancelProduction global.lang)
                                , onPress = Just (Core.ProductionMsg Production.CancelProduction)
                                }
                            ]
                        , case msg of
                            Just m ->
                                Element.el [] <| Element.text m

                            Nothing ->
                                Element.none
                        ]

                _ ->
                    Ui.primaryButton
                        { label = Element.text (Lang.produceVideo global.lang)
                        , onPress = Just (Core.ProductionMsg Production.ProduceVideo)
                        }
    in
    Element.row [ Element.alignRight, Element.spacing 10, Element.padding 10 ] [ produceInfo, produceButton ]