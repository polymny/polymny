module Core.Views exposing (..)

import Acquisition.Views as Acquisition
import Admin.Views as Admin
import Browser
import Capsule exposing (Capsule)
import CapsuleSettings.Views as CapsuleSettings
import Core.HomeView as HomeView
import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Lang
import NewCapsule.Views as NewCapsule
import Preparation.Views as Preparation
import Production.Views as Production
import Publication.Views as Publication
import Route
import Settings.Views as Settings
import Ui.BottomBar as Ui
import Ui.Colors as Colors
import Ui.LeftColumn as Ui
import Ui.Navbar as Ui
import Ui.Utils as Ui


view : Maybe Core.Model -> Browser.Document Core.Msg
view fullModel =
    { title = viewTitle fullModel
    , body =
        [ Element.layout
            [ Ui.hf
            , Font.size 18
            , Font.family
                [ Font.typeface "Ubuntu"
                , Font.typeface "Cantarell"
                ]
            ]
            (viewContent fullModel)
        ]
    }


viewTitle : Maybe Core.Model -> String
viewTitle model =
    let
        lang =
            case model of
                Just m ->
                    m.global.lang

                _ ->
                    Lang.default

        capsule c =
            c.capsule.project ++ " / " ++ c.capsule.name

        title =
            "Polymny"
    in
    case Maybe.map .page model of
        Just (Core.Preparation m) ->
            title ++ " - " ++ Lang.prepare lang ++ " - " ++ capsule m

        Just (Core.Acquisition m) ->
            title ++ " - " ++ Lang.record lang ++ " - " ++ capsule m

        Just (Core.Production m) ->
            title ++ " - " ++ Lang.produce lang ++ " - " ++ capsule m

        Just (Core.Publication m) ->
            title ++ " - " ++ Lang.publish lang ++ " - " ++ capsule m

        Just (Core.CapsuleSettings m) ->
            title ++ " - " ++ Lang.settings lang ++ " - " ++ capsule m

        _ ->
            title


viewContent : Maybe Core.Model -> Element Core.Msg
viewContent model =
    let
        ( element, lang, popupContent ) =
            case model of
                Just m ->
                    let
                        ( insideContent, p ) =
                            content m
                    in
                    ( Element.column
                        [ Background.color Colors.whiteBis
                        , Ui.wf
                        , Ui.hf
                        ]
                        [ Ui.navbar m.global (Just m.user) (Just m.page)
                        , insideContent
                        , Ui.bottomBar Core.LangChanged m.global m.page (Just m.user)
                        ]
                    , m.global.lang
                    , p
                    )

                Nothing ->
                    ( Element.none, Lang.default, Nothing )

        inFront =
            case model of
                Just m ->
                    case m.page of
                        Core.Preparation p ->
                            [ Element.inFront (Preparation.viewGosGhost m.global p (List.concat p.slides))
                            , Element.inFront (Preparation.viewSlideGhost m.global p (List.concat p.slides))
                            ]

                        _ ->
                            []

                _ ->
                    []

        fullView =
            case ( Maybe.map .popup model, popupContent ) of
                ( Just (Just p), _ ) ->
                    Element.el [ Ui.wf, Ui.hf, Element.inFront (Ui.popup lang p) ] element

                ( _, Just p ) ->
                    Element.el [ Ui.wf, Ui.hf, Element.inFront p ] element

                _ ->
                    element
    in
    Element.el (Ui.wf :: Ui.hf :: inFront) fullView


content : Core.Model -> ( Element Core.Msg, Maybe (Element Core.Msg) )
content model =
    case model.page of
        Core.Home homeModel ->
            HomeView.view model.global model.user homeModel Core.ToggleFold

        Core.Preparation c ->
            let
                ( innerContent, popup ) =
                    Preparation.view model.global model.user c
            in
            ( innerContent |> addLeftColumn model c.capsule, popup )

        Core.Acquisition c ->
            let
                ( innerContent, popup ) =
                    Acquisition.view model.global model.user c
            in
            ( innerContent |> addLeftColumn model c.capsule, popup )

        Core.Production c ->
            let
                ( innerContent, popup ) =
                    Production.view model.global model.user c
            in
            ( innerContent |> addLeftColumn model c.capsule, popup )

        Core.Publication c ->
            let
                ( innerContent, popup ) =
                    Publication.view model.global model.user c
            in
            ( innerContent |> addLeftColumn model c.capsule, popup )

        Core.CapsuleSettings c ->
            CapsuleSettings.view model.global model.user c

        Core.NewCapsule n ->
            NewCapsule.view model.global model.user n

        Core.Settings m ->
            ( Settings.view model.global model.user m, Nothing )

        Core.Admin m ->
            Admin.view model.global m

        Core.NotFound ->
            ( notFoundView model.global, Nothing )


addLeftColumn : Core.Model -> Capsule -> Element Core.Msg -> Element Core.Msg
addLeftColumn model capsule element =
    Element.row [ Ui.wf, Ui.hf, Element.scrollbarY ]
        [ Element.el [ Ui.wfp 1, Ui.hf, Element.scrollbarY, Background.color Colors.whiteTer ] (Ui.leftColumn model capsule)
        , Element.el [ Ui.wfp 6, Ui.hf, Element.scrollbarY, Background.color Colors.whiteBis ] element
        ]


notFoundView : Core.Global -> Element Core.Msg
notFoundView global =
    Element.row [ Ui.wf, Ui.hf, Element.padding 10 ]
        [ Element.el [ Ui.wfp 1, Ui.hf ] Element.none
        , Element.el [ Ui.wfp 6, Ui.hf ]
            (Element.column [ Element.spacing 10 ]
                [ Element.paragraph Ui.pageTitle [ Element.text (Lang.error404 global.lang) ]
                , Element.paragraph [] [ Element.text (Lang.notFound global.lang) ]
                , Ui.link []
                    { route = Route.Home
                    , label = Element.paragraph [] [ Element.text (Lang.clickHereToGoBackHome global.lang) ]
                    }
                ]
            )
        , Element.el [ Ui.wfp 1, Ui.hf ] Element.none
        ]
