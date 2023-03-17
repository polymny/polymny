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
import Lang exposing (Lang)
import Material.Icons as Icons
import Material.Icons.Types exposing (Icon)
import Options.Types as Options
import RemoteData
import Route exposing (Route(..))
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Utils as Ui
import Utils


view : Config -> User -> Options.Model Data.Capsule -> ( Element App.Msg, Element App.Msg )
view config _ model =
    let
        -- Helper to get client lang
        lang =
            config.clientState.lang

        -- Helper to create section titles
        title : String -> Element App.Msg
        title input =
            Element.el [ Font.size 30, Font.underline ] (Element.text input)

        -- Helper to create popup
        popup : Element App.Msg
        popup =
            case model.deleteTrack of
                Just t ->
                    deleteTrackConfirmPopup lang model t

                _ ->
                    Element.none
    in
    ( Element.row []
        [ Element.column [ Ui.s 10, Ui.p 100 ]
            [ Strings.stepsOptionsOptionsExplanation config.clientState.lang
                |> title
            , Element.column [ Ui.s 10, Ui.pt 20, Ui.wf ]
                [ defaultProd config model
                ]
            ]
        , Element.column [ Ui.s 10, Ui.p 100 ]
            [ Strings.stepsOptionsGeneralOptions config.clientState.lang
                |> title
            , Element.column [ Ui.s 10, Ui.pt 20, Ui.wf ]
                [ generalOptions config model
                ]
            ]
        ]
    , popup
    )


defaultProd : Config -> Options.Model Data.Capsule -> Element App.Msg
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
                    |> round
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


generalOptions : Config -> Options.Model Data.Capsule -> Element App.Msg
generalOptions config model =
    let
        lang =
            config.clientState.lang

        -- Helper to create section titles
        title : String -> Element App.Msg
        title input =
            Element.text input
                |> Element.el [ Font.size 22, Font.bold ]

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
        --disableIf :
        --    Bool
        --    -> (List (Element.Attribute App.Msg) -> { a | onChange : b -> App.Msg } -> Element App.Msg)
        --    -> List (Element.Attribute App.Msg)
        --    -> { a | onChange : b -> App.Msg }
        --    -> Element App.Msg
        --disableIf disabled constructor attributes parameters =
        --    if disabled then
        --        constructor (disableAttr ++ attributes) { parameters | onChange = \_ -> App.Noop }
        --    else
        --        constructor attributes parameters
        --
        --
        -- Track volume
        volume : Float
        volume =
            case model.capsule.soundTrack of
                Just st ->
                    st.volume

                Nothing ->
                    0.0

        -- Whether the user can control the volume
        noTrack : Bool
        noTrack =
            model.capsule.soundTrack == Nothing

        -- Whether the user is uploading a track
        uploading : Bool
        uploading =
            case model.capsuleUpdate of
                RemoteData.Loading _ ->
                    True

                _ ->
                    False

        --- UI ELEMENTS ---
        -- Sound track title
        soundTrackTitle =
            title (Strings.stepsOptionsSoundTrack lang)

        -- Track name
        soundTrackName =
            case model.capsuleUpdate of
                RemoteData.Loading Nothing ->
                    Ui.spinningSpinner [] 20

                _ ->
                    Element.text
                        (case model.capsule.soundTrack of
                            Just st ->
                                st.name

                            Nothing ->
                                Strings.stepsOptionsNoTrack lang
                        )
                        |> Element.el [ Ui.wfp 1, Ui.s 10 ]

        -- Sound track upload button
        soundTrackUpload =
            let
                action : App.Msg
                action =
                    if uploading then
                        App.Noop

                    else
                        App.OptionsMsg Options.TrackUploadRequested

                spinnerElement : Element App.Msg
                spinnerElement =
                    Element.el
                        [ Ui.wf
                        , Ui.hf
                        , Font.color <| Utils.tern uploading Colors.black Colors.transparent
                        ]
                    <|
                        Ui.spinningSpinner [ Ui.cx, Ui.cy ] 20

                label : Element App.Msg
                label =
                    Element.el
                        [ Font.color <| Utils.tern uploading Colors.transparent Colors.black
                        , Element.inFront spinnerElement
                        ]
                    <|
                        Element.text <|
                            Utils.tern
                                noTrack
                                (Strings.stepsOptionsUploadTrack lang)
                                (Strings.stepsOptionsReplaceTrack lang)
            in
            Ui.secondary
                []
                { label = label
                , action = Ui.Msg action
                }

        -- Sound track remove button
        soundTrackRemove : Element App.Msg
        soundTrackRemove =
            let
                action : Ui.Action App.Msg
                action =
                    if uploading then
                        Config.UploadTrack -1 model.capsule.id
                            |> Config.AbortTask
                            |> App.ConfigMsg
                            |> Ui.Msg

                    else if noTrack then
                        Ui.None

                    else
                        Options.DeleteTrack Utils.Request model.capsule.soundTrack
                            |> App.OptionsMsg
                            |> Ui.Msg
                
                icon : Material.Icons.Types.Icon msg
                icon =
                    if uploading then
                        Icons.close

                    else
                        Icons.delete
                
                tooltip : String
                tooltip =
                    if uploading then
                        Strings.actionsAbortTrack lang

                    else
                        Strings.actionsDeleteTrack lang
            in
            Ui.secondaryIcon (disableAttrIf noTrack)
                { icon = icon
                , tooltip = tooltip
                , action = action
                }

        -- Slider to control volume
        volumeSlider : Element App.Msg
        volumeSlider =
            Element.row [ Ui.wf, Ui.hf, Ui.s 10 ]
                [ -- Slider for the control
                  Input.slider
                    [ Element.behindContent <| Element.el [ Ui.wf, Ui.hpx 2, Ui.cy, Background.color Colors.greyBorder ] Element.none
                    ]
                    { onChange = \x -> App.OptionsMsg <| Options.SetVolume x
                    , label = Input.labelHidden <| Strings.stepsOptionsVolume lang
                    , max = 1
                    , min = 0
                    , step = Just 0.01
                    , thumb = Input.defaultThumb
                    , value = volume
                    }
                , -- Text label of the volume value
                  volume
                    * 100
                    |> round
                    |> String.fromInt
                    |> (\x -> x ++ "%")
                    |> Element.text
                    |> Element.el [ Ui.wfp 1, Ui.ab ]
                ]

        -- Play button
        playButton : Element App.Msg
        playButton =
            let
                attr =
                    disableAttrIf model.playPreview

                action =
                    if model.playPreview then
                        Ui.None

                    else
                        Ui.Msg (App.OptionsMsg Options.Play)
            in
            Ui.secondaryIcon
                attr
                { icon = Icons.play_arrow
                , tooltip = Strings.stepsOptionsPlayPreview lang
                , action = action
                }

        -- Stop button
        stopButton : Element App.Msg
        stopButton =
            let
                attr =
                    disableAttrIf (not model.playPreview)

                action =
                    if model.playPreview then
                        Ui.Msg (App.OptionsMsg Options.Stop)

                    else
                        Ui.None
            in
            Ui.secondaryIcon
                attr
                { icon = Icons.stop
                , tooltip = Strings.stepsOptionsStopPreview lang
                , action = action
                }
    in
    Element.column [ Ui.wfp 1, Ui.s 30, Ui.at ]
        [ Element.column [ Ui.s 10 ]
            ([ soundTrackTitle
             , Element.row [ Ui.s 10 ]
                [ soundTrackName
                , soundTrackUpload
                , soundTrackRemove
                ]
             ]
                ++ (if noTrack then
                        []

                    else
                        [ volumeSlider
                        , Element.row [ Ui.s 10 ]
                            [ playButton
                            , stopButton
                            ]
                        ]
                   )
            )
        ]


{-| Popup to confirm the track deletion.
-}
deleteTrackConfirmPopup : Lang -> Options.Model Data.Capsule -> Data.SoundTrack -> Element App.Msg
deleteTrackConfirmPopup lang _ s =
    Element.column [ Ui.wf, Ui.hf ]
        [ Element.paragraph [ Ui.wf, Ui.cy, Font.center ]
            [ Element.text (Lang.question Strings.actionsConfirmDeleteTrack lang) ]
        , Element.row [ Ui.ab, Ui.ar, Ui.s 10 ]
            [ Ui.secondary []
                { action = mkUiMsg <| Options.DeleteTrack Utils.Cancel <| Just s
                , label = Element.text <| Strings.uiCancel lang
                }
            , Ui.primary []
                { action = mkUiMsg <| Options.DeleteTrack Utils.Confirm <| Just s
                , label = Element.text <| Strings.uiConfirm lang
                }
            ]
        ]
        |> Ui.popup 1 (Strings.actionsDeleteTrack lang)


{-| Easily creates the Ui.Msg for options msg.
-}
mkUiMsg : Options.Msg -> Ui.Action App.Msg
mkUiMsg msg =
    mkMsg msg |> Ui.Msg


{-| Easily creates a options msg.
-}
mkMsg : Options.Msg -> App.Msg
mkMsg msg =
    App.OptionsMsg msg
