module Core.Views exposing (subscriptions, view)

import Acquisition.Ports
import Acquisition.Types as Acquisition
import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import ForgotPassword.Views as ForgotPassword
import Html
import LoggedIn.Types as LoggedIn
import LoggedIn.Views as LoggedIn
import Login.Views as Login
import Preparation.Types as Preparation
import Preparation.Views as Preparation
import ResetPassword.Views as ResetPassword
import SignUp.Views as SignUp
import Ui.Attributes as Attributes
import Ui.Colors as Colors
import Ui.Ui as Ui


subscriptions : Core.FullModel -> Sub Core.Msg
subscriptions { model } =
    case model of
        Core.LoggedIn { tab } ->
            case tab of
                LoggedIn.Preparation { slideModel, gosModel } ->
                    Sub.map
                        (\x ->
                            Core.LoggedInMsg (LoggedIn.PreparationMsg (Preparation.DnD x))
                        )
                        (Sub.batch
                            [ Preparation.slideSystem.subscriptions slideModel
                            , Preparation.gosSystem.subscriptions gosModel
                            ]
                        )

                LoggedIn.Acquisition _ ->
                    Sub.batch
                        [ Acquisition.Ports.newRecord Acquisition.NewRecord
                        , Acquisition.Ports.streamUploaded Acquisition.StreamUploaded
                        , Acquisition.Ports.nextSlideReceived Acquisition.NextSlideReceived
                        , Acquisition.Ports.goToNextSlide (\_ -> Acquisition.NextSlide False)
                        ]
                        |> Sub.map LoggedIn.AcquisitionMsg
                        |> Sub.map Core.LoggedInMsg

                _ ->
                    Sub.none

        _ ->
            Sub.none


view : Core.FullModel -> Html.Html Core.Msg
view fullModel =
    Element.layout Attributes.fullModelAttributes (viewContent fullModel)


viewContent : Core.FullModel -> Element Core.Msg
viewContent { global, model } =
    let
        content =
            case model of
                Core.Home homeModel ->
                    homeView homeModel

                Core.ResetPassword resetPasswordModel ->
                    ResetPassword.view resetPasswordModel

                Core.LoggedIn { session, tab } ->
                    LoggedIn.view global session tab

        attributes =
            case model of
                Core.LoggedIn { tab } ->
                    case tab of
                        LoggedIn.Preparation { slides, slideModel, gosModel, details } ->
                            [ Element.inFront (Preparation.gosGhostView details gosModel slideModel (List.concat slides))
                            , Element.inFront (Preparation.slideGhostView slideModel (List.concat slides))
                            ]

                        _ ->
                            []

                _ ->
                    []
    in
    Element.column (Element.width Element.fill :: attributes) [ topBar model, content ]


homeView : Core.HomeModel -> Element Core.Msg
homeView model =
    let
        forgotPasswordLinkContent =
            Ui.linkButton (Just Core.ForgotPasswordClicked) "Mot de passe oublié"

        ( form, button, forgotPasswordLink ) =
            case model of
                Core.HomeLogin login ->
                    ( Login.view login
                    , Ui.linkButton (Just Core.SignUpClicked) "Pas encore de compte ? Créez-en un"
                    , forgotPasswordLinkContent
                    )

                Core.HomeSignUp signUp ->
                    ( SignUp.view signUp
                    , Ui.linkButton (Just Core.LoginClicked) "Déjà un compte ? Identifiez-vous"
                    , forgotPasswordLinkContent
                    )

                Core.HomeForgotPassword forgotPassword ->
                    ( ForgotPassword.view forgotPassword
                    , Ui.linkButton (Just Core.LoginClicked) "Retourner au début"
                    , Element.none
                    )

        logoSmall =
            80
    in
    Element.row
        [ Element.centerX
        , Element.spacing 100
        , Element.padding 20
        , Element.width Element.fill
        ]
        [ Element.el [ Element.width (Element.fillPortion 1) ] Element.none
        , Element.column
            [ Element.centerX
            , Element.spacing 10
            , Element.width (Element.fillPortion 4)
            , Element.alignTop
            ]
            [ Element.column
                [ Element.spacing 10
                , Element.padding 20
                , Font.size 16
                ]
                [ Element.el Attributes.attributesHomeTitle <|
                    Element.text "Polymny Studio "
                , Element.paragraph [] [ Element.text "Le studio web des formateurs qui créent, modifient et gèrent des vidéos pédagogiques !" ]
                , Element.paragraph [] [ Element.text "Le tout à distance, sans obstacles ni prérequis, à partir de simples présentations pdf.\n" ]
                , Element.paragraph [] [ Element.text "Polymny.studio est issu d'un programme 2020-2021 de pré-maturation de la Région Occitanie" ]
                , Element.el [ Element.paddingXY 30 5, Element.alignLeft ] <| viewLogo 100 "/dist/logoRegionOccitanie.png"
                , Element.paragraph [] [ Element.text "Les acteurs, les utilisateurs et les soutiens :" ]
                , Element.row [ Element.spacing 10 ]
                    [ viewLogo logoSmall "/dist/logoTTT.png"
                    , viewLogo logoSmall "/dist/logoIRIT.png"
                    , viewLogo logoSmall "/dist/logoCEPFOR.png"
                    , viewLogo logoSmall "/dist/logoCERESA.png"
                    , viewLogo logoSmall "/dist/logoDYP.png"
                    , viewLogo logoSmall "/dist/logoINP.png"
                    , viewLogo logoSmall "/dist/logoUT2J.png"
                    ]
                ]
            ]
        , Element.column
            [ Element.centerX
            , Element.spacing 10
            , Element.width (Element.fillPortion 2)
            , Element.alignTop
            ]
            [ form, forgotPasswordLink, button ]
        , Element.el [ Element.width (Element.fillPortion 1) ] Element.none
        ]


topBar : Core.Model -> Element Core.Msg
topBar model =
    case model of
        Core.LoggedIn { session, tab } ->
            Element.row
                [ Background.color Colors.primary
                , Font.color Colors.white
                , Element.width Element.fill
                , Element.spacing 30
                ]
                [ Element.row
                    [ Element.alignLeft, Element.padding 10, Element.spacing 5 ]
                    [ homeButton ]
                , Element.row [ Element.alignRight, Element.padding 10, Element.spacing 10 ]
                    (if Core.isLoggedIn model then
                        [ Element.el [] (Element.text session.username), logoutButton ]

                     else
                        []
                    )
                ]

        _ ->
            nonFull model


nonFull : Core.Model -> Element Core.Msg
nonFull model =
    Element.row
        [ Background.color Colors.primary
        , Element.width Element.fill
        , Element.spacing 30
        ]
        [ Element.row
            [ Element.alignLeft, Element.padding 10, Element.spacing 10 ]
            [ homeButton ]
        , Element.row [ Element.alignRight, Element.padding 10, Element.spacing 10 ]
            (if Core.isLoggedIn model then
                [ logoutButton ]

             else
                []
            )
        ]


homeButton : Element Core.Msg
homeButton =
    Element.el [ Font.bold, Font.size 18 ] (Ui.homeButton (Just Core.HomeClicked) "")


logoutButton : Element Core.Msg
logoutButton =
    Ui.topBarButton (Just Core.LogoutClicked) "Log out"


viewLogo : Int -> String -> Element Core.Msg
viewLogo size url =
    Element.image [ Element.centerX, Element.width (Element.px size) ] { src = url, description = "One desc" }
