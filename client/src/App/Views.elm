module App.Views exposing (view, viewSuccess, viewError)

{-| This module manages the views of the application.

@docs view, viewSuccess, viewError

-}

import Acquisition.Types as Acquisition
import Acquisition.Views as Acquisition
import App.Types as App
import App.Utils as App
import Browser
import Config
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Home.Views as Home
import Lang exposing (Lang)
import NewCapsule.Views as NewCapsule
import Options.Types as Options
import Options.Views as Options
import Preparation.Types as Preparation
import Preparation.Views as Preparation
import Production.Types as Production
import Production.Views as Production
import Profile.Views as Profile
import Publication.Types as Publication
import Publication.Views as Publication
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Graphics as Ui
import Ui.Navbar as Ui
import Ui.Utils as Ui
import Unlogged.Views as Unlogged
import Html
import Html.Attributes


{-| Returns the view of the model.
-}
view : App.MaybeModel -> Browser.Document App.MaybeMsg
view fullModel =
    { title = "Polymny Studio"
    , body =
        [ Element.layout
            [ Ui.wf
            , Ui.hf
            , Font.size 18
            , Font.family
                [ Font.typeface "Urbanist"
                , Font.typeface "Ubuntu"
                , Font.typeface "Cantarell"
                ]
            , Background.color Colors.greyBackground
            , Font.color Colors.greyFont
            ]
            (viewContent fullModel)
        ]
    }


{-| Stylizes all the content of the app.
-}
viewContent : App.MaybeModel -> Element App.MaybeMsg
viewContent fullModel =
    let
        ( content, popup ) =
            case fullModel of
                App.Logged model ->
                    viewSuccess model |> Tuple.mapBoth (Element.map App.LoggedMsg) (Element.map App.LoggedMsg)

                App.Unlogged model ->
                    ( Element.row [ Ui.wf ]
                        [ Element.el [ Ui.wf ] Element.none
                        , Element.el [ Ui.wf ] (Unlogged.view model)
                        , Element.el [ Ui.wf ] Element.none
                        ]
                        |> Element.map App.UnloggedMsg
                    , Element.none
                    )

                App.Error error ->
                    ( viewError error |> Element.map App.LoggedMsg, Element.none )

        clientState =
            case fullModel of
                App.Logged { config } ->
                    config.clientState

                App.Unlogged { config } ->
                    config.clientState

                _ ->
                    Config.initClientState Nothing Nothing

        realPopup =
            if clientState.showLangPicker then
                langPicker clientState.lang

            else
                popup
    in
    Element.column
        [ Ui.wf
        , Ui.hf
        , Element.inFront realPopup
        , Background.gradient
            { angle = pi
            , steps =
                [ Colors.green2
                ,Colors.green2
                , Colors.grey 3
                , Colors.grey 3
                ]
            }
        ]
        [ Ui.navbar
            (fullModel |> App.toMaybe |> Maybe.map .config)
            (fullModel |> App.toMaybe |> Maybe.map .page)
            (fullModel |> App.toMaybe |> Maybe.map .user)
            |> Element.map App.LoggedMsg
        , Element.el
            [ Ui.wf
            , Ui.hf
            , Element.scrollbarY
            , Background.color Colors.greyBackground
            , Ui.r 10
            , Border.shadow
                { offset = ( 0.0, 0.0 )
                , size = 1
                , blur = 10
                , color = Colors.alpha 0.3
                }
            ]
            content
        , Ui.bottombar (fullModel |> App.toMaybe |> Maybe.map .config)
        ]


{-| Returns the view if the model is correct.
-}
viewSuccess : App.Model -> ( Element App.Msg, Element App.Msg )
viewSuccess model =
    let
        ( maybeCapsule, maybeGos ) =
            App.capsuleAndGos model.user model.page
    in
    case ( model.page, maybeCapsule, maybeGos ) of
        ( App.Home m, _, _ ) ->
            Home.view model.config model.user m

        ( App.NewCapsule m, _, _ ) ->
            NewCapsule.view model.config model.user m

        ( App.Preparation m, Just capsule, _ ) ->
            Preparation.view model.config model.user (Preparation.withCapsule capsule m)
                |> Ui.addLeftColumn model.config.clientState.lang model.page capsule Nothing

        ( App.Acquisition m, Just capsule, Just gos ) ->
            Acquisition.view model.config model.user (Acquisition.withCapsuleAndGos capsule gos m)
                |> Ui.addLeftAndRightColumn model.config.clientState.lang model.page capsule (Just m.gos)

        ( App.Production m, Just capsule, Just gos ) ->
            Production.view model.config model.user (Production.withCapsuleAndGos capsule gos m)
                |> Ui.addLeftColumn model.config.clientState.lang model.page capsule (Just m.gos)

        ( App.Publication m, Just capsule, _ ) ->
            Publication.view model.config model.user (Publication.withCapsule capsule m)
                |> Ui.addLeftColumn model.config.clientState.lang model.page capsule Nothing

        ( App.Options m, Just capsule, _ ) ->
            Options.view model.config model.user (Options.withCapsule capsule m)
                |> Ui.addLeftColumn model.config.clientState.lang model.page capsule Nothing

        ( App.Profile m, _, _ ) ->
            Profile.view model.config model.user m

        _ ->
            ( Element.none, Element.none )


{-| Returns the view if the model is in error.
-}
viewError : App.Error -> Element App.Msg
viewError error =
    Element.text (App.errorToString error)


{-| The popup for the lang picker.
-}
langPicker : Lang -> Element App.MaybeMsg
langPicker lang =
    let
        confirmButton =
            Ui.primary [ Ui.ab, Ui.ar ]
                { action = Ui.Msg <| App.LoggedMsg <| App.ConfigMsg <| Config.ToggleLangPicker
                , label = Element.text <| Strings.uiConfirm lang
                }

        langChoice : Lang -> Element App.MaybeMsg
        langChoice l =
            (if lang == l then
                Ui.primary

             else
                Ui.secondary
            )
                []
                { label =
                    Element.row [ Ui.s 5 ]
                        [ Element.text <| Lang.flag l
                        , Element.text <| Lang.toLocal l
                        ]
                , action = Ui.Msg <| App.LoggedMsg <| App.ConfigMsg <| Config.LangChanged l
                }

        langChoices =
            Element.wrappedRow [ Ui.cx, Ui.cy, Ui.s 10 ] <|
                List.map langChoice Lang.langs
    in
    Ui.popup 1 (Strings.configLang lang) <|
        Element.column [ Ui.wf, Ui.hf ]
            [ langChoices
            , confirmButton
            ]
