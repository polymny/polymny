module Core.Views exposing (subscriptions, view)

import About
import Acquisition.Ports
import Acquisition.Types as Acquisition
import Acquisition.Views as Acquisition
import Api
import Browser
import Core.Ports
import Core.Types as Core
import Core.Utils as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import ForgotPassword.Views as ForgotPassword
import Json.Decode as Decode
import LoggedIn.Types as LoggedIn
import LoggedIn.Views as LoggedIn
import Login.Views as Login
import Notification.Types exposing (Notification)
import Notification.Views as Notification
import Preparation.Types as Preparation
import Preparation.Views as Preparation
import ResetPassword.Views as ResetPassword
import Routes
import SignUp.Views as SignUp
import Ui.Attributes as Attributes
import Ui.Colors as Colors
import Ui.Icons as Icons
import Ui.Ui as Ui


subscriptions : Core.FullModel -> Sub Core.Msg
subscriptions { model } =
    let
        sub =
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

                        LoggedIn.Acquisition m ->
                            Sub.batch
                                [ Acquisition.subscriptions m
                                , Sub.batch
                                    [ Acquisition.Ports.newRecord Acquisition.NewRecord
                                    , Acquisition.Ports.streamUploaded Acquisition.StreamUploaded
                                    , Acquisition.Ports.nextSlideReceived Acquisition.NextSlideReceived
                                    , Acquisition.Ports.goToNextSlide (\_ -> Acquisition.NextSlide False)
                                    , Acquisition.Ports.cameraReady (\_ -> Acquisition.CameraReady)
                                    , Acquisition.Ports.secondsRemaining Acquisition.SecondsRemaining
                                    , Acquisition.Ports.backgroundCaptured Acquisition.BackgroundCaptured
                                    ]
                                    |> Sub.map LoggedIn.AcquisitionMsg
                                    |> Sub.map Core.LoggedInMsg
                                ]

                        _ ->
                            Sub.none

                _ ->
                    Sub.none
    in
    Sub.batch
        [ sub
        , Core.Ports.onWebSocketMessage websocketMsg
        ]


websocketMsg : Decode.Value -> Core.Msg
websocketMsg value =
    case Decode.decodeValue Core.decodeWebSocketMsg value of
        Ok msg ->
            Core.WebSocket msg

        Err _ ->
            Core.Noop


view : Core.FullModel -> Browser.Document Core.Msg
view fullModel =
    { title = "Polymny"
    , body = [ Element.layout Attributes.fullModelAttributes (viewContent fullModel) ]
    }


viewContent : Core.FullModel -> Element Core.Msg
viewContent { global, model } =
    let
        ( content, givenPopup ) =
            case model of
                Core.Home homeModel ->
                    ( homeView homeModel, Nothing )

                Core.ResetPassword resetPasswordModel ->
                    ( ResetPassword.view resetPasswordModel, Nothing )

                Core.LoggedIn { session, tab } ->
                    LoggedIn.view global session tab

        popup =
            case ( global.showAbout, givenPopup ) of
                ( True, Nothing ) ->
                    Just (Ui.popup "À propos" About.view)

                ( _, p ) ->
                    p

        attributes =
            case model of
                Core.LoggedIn { tab } ->
                    case tab of
                        LoggedIn.Preparation { slides, slideModel, gosModel, broken } ->
                            case broken of
                                Preparation.NotBroken ->
                                    [ Element.inFront (Preparation.gosGhostView global global.numberOfSlidesPerRow gosModel slideModel (List.concat slides))
                                    , Element.inFront (Preparation.slideGhostView global slideModel (List.concat slides))
                                    ]

                                _ ->
                                    []

                        _ ->
                            []

                _ ->
                    []
    in
    Element.column
        (Element.height Element.fill
            :: Element.scrollbarY
            :: Element.width Element.fill
            :: Background.color Colors.whiteDark
            :: Element.inFront (Maybe.withDefault Element.none popup)
            :: attributes
        )
        [ topBar global model
        , content
        , bottomBar global
        ]


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

                Core.HomeAbout ->
                    ( About.view
                    , Ui.linkButton (Just Core.LoginClicked) "Fermer"
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
        , Element.height Element.fill
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
                , Element.paragraph [] [ Element.text "Le studio web des formateurs qui créent, modifient et gèrent des vidéos pédagogiques\u{00A0}!" ]
                , Element.paragraph [] [ Element.text "Le tout à distance, sans obstacles ni prérequis, à partir de simples présentations pdf.\n" ]
                , Element.paragraph [] [ Element.text "Polymny.studio est issu d'un programme 2020-2021 de pré-maturation de la Région Occitanie." ]
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


topBar : Core.Global -> Core.Model -> Element Core.Msg
topBar global model =
    case model of
        Core.LoggedIn { session, tab } ->
            let
                makeButton : Maybe String -> String -> Bool -> Element Core.Msg
                makeButton msg label active =
                    Element.link
                        (Element.padding 7
                            :: Element.height Element.fill
                            :: (if active then
                                    [ Background.color Colors.white
                                    , Font.color Colors.primary
                                    ]

                                else
                                    []
                               )
                        )
                        { url =
                            case msg of
                                Nothing ->
                                    "#"

                                Just u ->
                                    u
                        , label = Element.el [ Element.centerY ] (Element.text label)
                        }

                unreadNotifcaitions =
                    session.notifications |> List.filter (not << .read) |> List.length

                unreadNotificationsInFront =
                    let
                        size =
                            12
                    in
                    if unreadNotifcaitions > 0 then
                        Element.el
                            [ Element.alignRight
                            , Element.alignBottom
                            , Background.color Colors.danger
                            , Element.width (Element.px size)
                            , Element.height (Element.px size)
                            , Border.rounded (size // 2)
                            , Font.size 8
                            ]
                            (Element.el
                                [ Element.centerX, Element.centerY ]
                                (Element.text (String.fromInt unreadNotifcaitions))
                            )

                    else
                        Element.none

                notificationIcon =
                    Input.button []
                        { label =
                            Element.el
                                [ Element.padding 5
                                , Element.inFront unreadNotificationsInFront
                                ]
                                Icons.bell
                        , onPress = Just (Core.NotificationMsg Core.ToggleNotificationPanel)
                        }

                ( details, leftButtons ) =
                    case tab of
                        LoggedIn.Preparation p ->
                            ( Just p.details
                            , [ makeButton Nothing "Préparer" True
                              , makeButton (Just (Routes.acquisition p.details.capsule.id)) "Filmer" False
                              , makeButton (Just (Routes.edition p.details.capsule.id)) "Produire" False
                              ]
                            )

                        LoggedIn.Acquisition p ->
                            ( Just p.details
                            , [ makeButton (Just (Routes.preparation p.details.capsule.id)) "Préparer" False
                              , makeButton Nothing "Filmer" True
                              , makeButton (Just (Routes.edition p.details.capsule.id)) "Produire" False
                              ]
                            )

                        LoggedIn.Edition p ->
                            ( Just p.details
                            , [ makeButton (Just (Routes.preparation p.details.capsule.id)) "Préparer" False
                              , makeButton (Just (Routes.acquisition p.details.capsule.id)) "Filmer" False
                              , makeButton Nothing "Produire" True
                              ]
                            )

                        _ ->
                            ( Nothing, [] )

                projectAndCapsuleName =
                    case details of
                        Just d ->
                            let
                                projectName =
                                    Maybe.withDefault "" <| Maybe.map .name (List.head d.projects)
                            in
                            Element.el
                                [ Element.spacing 5, Element.paddingXY 20 4, Element.alignLeft ]
                            <|
                                Element.text <|
                                    projectName
                                        ++ " / "
                                        ++ d.capsule.name

                        Nothing ->
                            Element.none
            in
            Element.row
                [ Background.color Colors.primary
                , Font.color Colors.white
                , Element.width Element.fill
                , Element.below (notificationPanel global session)
                ]
                [ Element.row
                    [ Element.alignLeft, Element.spacing 40, Element.height Element.fill ]
                    [ homeButton
                    , projectAndCapsuleName
                    , Element.row [ Element.spacing 10, Element.height Element.fill ] leftButtons
                    ]
                , Element.row [ Element.alignRight, Element.padding 5, Element.spacing 10 ]
                    (if Core.isLoggedIn model then
                        [ notificationIcon
                        , settingsButton session.username
                        , logoutButton
                        ]

                     else
                        []
                    )
                ]

        _ ->
            nonFull model


notificationPanel : Core.Global -> Api.Session -> Element Core.Msg
notificationPanel global session =
    let
        notifications =
            if List.isEmpty session.notifications then
                [ Element.paragraph [] [ Element.text "Vous n'avez aucune notification." ] ]

            else
                List.indexedMap Notification.view session.notifications

        header =
            Element.row
                [ Element.width Element.fill
                , Element.paddingEach
                    { top = 0
                    , bottom = 10
                    , left = 0
                    , right = 0
                    }
                , Font.size 16
                , Font.bold
                ]
                [ Element.text "Notifications"
                , Input.button [ Element.alignRight ]
                    { label = Element.text "x"
                    , onPress = Just (Core.NotificationMsg Core.ToggleNotificationPanel)
                    }
                ]
    in
    if global.notificationPanelVisible then
        Element.row [ Element.width Element.fill, Element.paddingXY 10 0 ]
            [ Element.el [ Element.width (Element.fillPortion 3) ] Element.none
            , Element.column
                [ Background.color Colors.whiteDark
                , Font.color Colors.black
                , Border.width 1
                , Border.color Colors.black
                , Border.rounded 10
                , Element.padding 10
                , Element.alignRight
                , Element.height (Element.maximum 400 Element.fill)
                , Element.scrollbarY
                ]
                (header :: notifications)
            ]

    else
        Element.none


bottomBar : Core.Global -> Element Core.Msg
bottomBar global =
    Element.column
        [ Element.width Element.fill
        , Background.color Colors.greyLight
        , Border.color Colors.grey
        , Border.width 1
        , Font.size 12
        ]
        [ Element.el [ Element.height Element.fill ] Element.none
        , Element.row
            [ Element.width Element.fill, Element.alignBottom, Element.padding 15 ]
            [ Element.row [ Element.alignLeft, Element.spacing 5 ]
                [ Element.text
                    "Polymny studio:"
                , Element.link
                    []
                    { url = "mailto:contacter@polymny.studio"
                    , label = Element.el [ Font.bold ] <| Element.text "contacter@polymny.studio"
                    }
                , Element.el [] <| Ui.linkButton (Just Core.AboutClicked) "A propos"
                ]
            , Element.row [ Element.alignRight, Element.spacing 5 ]
                [ Element.link
                    []
                    { url = "https://www.gnu.org/licenses/agpl-3.0.en.html"
                    , label = Element.el [ Font.bold ] <| Element.text "Gnu Affero V3. "
                    }
                , Element.text
                    ("Polymny "
                        ++ global.version
                        ++ (if global.beta then
                                " beta " ++ global.commit

                            else
                                ""
                           )
                    )
                , Element.link
                    []
                    { url = "https://github.com/polymny/polymny"
                    , label = Element.el [ Font.bold ] <| Element.text "Fork me!"
                    }
                ]
            ]
        ]


nonFull : Core.Model -> Element Core.Msg
nonFull model =
    Element.row
        [ Background.color Colors.primary
        , Element.width Element.fill
        , Element.spacing 30
        ]
        [ Element.row
            [ Element.alignLeft, Element.paddingXY 40 10, Element.spacing 10 ]
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
    Element.el [ Element.padding 5 ] (Ui.homeButton (Just Core.HomeClicked) "")


logoutButton : Element Core.Msg
logoutButton =
    Ui.topBarButton (Just Core.LogoutClicked) "Log out"


settingsButton : String -> Element Core.Msg
settingsButton content =
    Ui.topBarButton (Just <| Core.LoggedInMsg <| LoggedIn.SettingsClicked) content


viewLogo : Int -> String -> Element Core.Msg
viewLogo size url =
    Element.image [ Element.centerX, Element.width (Element.px size) ] { src = url, description = "One desc" }
