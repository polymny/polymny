module Core.Views exposing (subscriptions, topBar, view)

import About
import Acquisition.Ports
import Acquisition.Types as Acquisition
import Acquisition.Views as Acquisition
import Api
import Browser
import Browser.Events as Events
import Core.Ports
import Core.Types as Core
import Core.Utils as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import ForgotPassword.Views as ForgotPassword
import Html.Attributes
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
import Ui.StaticAssets as Assets
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
        , Events.onResize (\w h -> Core.SizeReceived w h)
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
                    ( homeView homeModel global.device, Nothing )

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
                        LoggedIn.Preparation preparationModel ->
                            case preparationModel.broken of
                                Preparation.NotBroken ->
                                    [ Element.inFront (Preparation.gosGhostView global global.numberOfSlidesPerRow (List.concat preparationModel.slides) preparationModel)
                                    , Element.inFront (Preparation.slideGhostView global (List.concat preparationModel.slides) preparationModel)
                                    ]

                                _ ->
                                    []

                        _ ->
                            []

                _ ->
                    []

        bottomBar =
            case global.device.class of
                Element.Phone ->
                    bottomBarPhone global

                _ ->
                    bottomBarDefault global
    in
    Element.column
        (Element.height Element.fill
            :: Element.scrollbarY
            :: Element.width Element.fill
            :: Background.color Colors.light
            :: Element.inFront (Maybe.withDefault Element.none popup)
            :: attributes
        )
        [ topBar global model
        , content
        , bottomBar
        ]


mobileH1Font =
    40


defaultH1Font =
    60


attributesHomeTitle : Element.Device -> List (Element.Attribute msg)
attributesHomeTitle device =
    let
        fontSize =
            case device.class of
                Element.Phone ->
                    mobileH1Font

                _ ->
                    defaultH1Font
    in
    [ Element.centerX
    , Element.padding 8
    , Font.size fontSize
    , Font.bold
    , Font.justify
    ]


homeView : Core.HomeModel -> Element.Device -> Element Core.Msg
homeView model device =
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

        ( paragraphFontSize, paragraphAttributes ) =
            case device.class of
                Element.Phone ->
                    ( 14
                    , [ Element.width <| Element.maximum 300 Element.fill
                      , Font.justify
                      , Element.centerX
                      , Element.paddingXY 4 20
                      ]
                    )

                _ ->
                    ( 20
                    , [ Element.width <| Element.maximum 700 Element.fill
                      , Font.justify
                      , Element.centerX
                      , Element.paddingXY 4 20
                      ]
                    )
    in
    Element.column
        [ Element.centerX
        , Element.alignTop
        , Font.size paragraphFontSize
        ]
        [ Element.column [ Element.centerX ]
            [ Element.paragraph (attributesHomeTitle device) [ Element.text "Polymny Studio" ]
            , Element.paragraph paragraphAttributes
                [ Element.text "Polymny est le studio web des formateurs qui créent, modifient et gèrent des vidéos pédagogiques\u{00A0}! A partir d’une présentation existante (libre office, powerpoint, beamer, etc.), vous fournissez vos diapositives en PDF et enregistrez une vidéo pédagogique pour vos élèves, vos étudiants, vos clients ou vos collègues. " ]
            ]
        , Element.column
            [ Element.padding 30
            , Element.centerX
            ]
            [ form, forgotPasswordLink, button ]
        , Element.paragraph paragraphAttributes
            [ Element.text "Polymny est un logiciel libre, utilisable gratuitement, 100% web, indépendant du système d’exploitation de votre ordinateur (windows, macOS, linux). Il suffit de créer un compte pour enregistrer une première capsule vidéo.  Besoin d'aide, de  support \u{00A0}:  "
            , Element.link
                []
                { url = "mailto:contacter@polymny.studio"
                , label =
                    Element.el
                        [ Font.underline
                        , Font.bold
                        ]
                    <|
                        Element.text "contacter@polymny.studio"
                }
            ]
        , partnersView device
        , Element.column [ Element.centerX ]
            [ Element.paragraph paragraphAttributes
                [ Element.text "Contacts\u{00A0}:"
                , Element.link
                    []
                    { url = "mailto:contacter@polymny.studio"
                    , label =
                        Element.el
                            [ Font.underline
                            , Font.bold
                            ]
                        <|
                            Element.text "contacter@polymny.studio"
                    }
                ]
            , Element.paragraph paragraphAttributes [ Element.text "Nicolas Bertrand, Thomas Forgione, Axel Carlier, Vincent Charvillat" ]
            ]
        ]


topBar : Core.Global -> Core.Model -> Element Core.Msg
topBar global model =
    let
        makeButton : Maybe String -> String -> Bool -> Element Core.Msg
        makeButton msg label active =
            Element.link
                (Element.padding 7
                    :: Element.height Element.fill
                    :: (if active then
                            [ Background.color Colors.light
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
            case model of
                Core.LoggedIn { session } ->
                    session.notifications |> List.filter (not << .read) |> List.length

                _ ->
                    0

        question =
            Element.newTabLink [ Font.color Colors.white ]
                { label = Icons.questionCircle
                , url = "https://polymny.studio/tutoriels/"
                }

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
            Input.button [ Font.color Colors.white ]
                { label =
                    Element.el
                        [ Element.padding 5
                        , Element.inFront unreadNotificationsInFront
                        ]
                        Icons.bell
                , onPress = Just (Core.NotificationMsg Core.ToggleNotificationPanel)
                }

        ( details, leftButtons ) =
            case model of
                Core.LoggedIn { tab } ->
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

        row =
            case model of
                Core.LoggedIn { session } ->
                    [ question
                    , notificationIcon
                    , settingsButton session.username
                    , logoutButton
                    ]

                _ ->
                    []
    in
    Element.row
        (Background.color Colors.navbar
            :: Element.width Element.fill
            :: Font.bold
            :: (case model of
                    Core.LoggedIn { session } ->
                        [ Element.below (notificationPanel global session) ]

                    _ ->
                        []
               )
        )
        [ Element.row
            [ Element.alignLeft, Element.spacing 40, Element.height Element.fill ]
            [ homeButton
            , projectAndCapsuleName
            , Element.row [ Element.spacing 10, Element.height Element.fill ] leftButtons
            ]
        , Element.row [ Element.alignRight, Element.padding 5, Element.spacing 10 ] row
        ]


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
                [ Background.color Colors.light
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


bottomBarDefault : Core.Global -> Element Core.Msg
bottomBarDefault global =
    Element.column
        [ Element.width Element.fill
        , Background.color Colors.greyLighter
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
                    Ui.linkAttributes
                    { url = "mailto:contacter@polymny.studio"
                    , label = Element.text "contacter@polymny.studio"
                    }
                , Ui.linkButton (Just Core.AboutClicked) "A propos"
                , Element.link
                    Ui.linkAttributes
                    { url = global.home ++ "/protection-des-donnees/"
                    , label = Element.text "Données personnelles"
                    }
                , Element.link
                    Ui.linkAttributes
                    { url = global.home ++ "/cgu/"
                    , label = Element.text "Conditions d'utilisation"
                    }
                ]
            , Element.row [ Element.alignRight, Element.spacing 5 ]
                [ Element.link
                    Ui.linkAttributes
                    { url = "https://www.gnu.org/licenses/agpl-3.0.en.html"
                    , label = Element.text "Gnu Affero V3. "
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
                    Ui.linkAttributes
                    { url = "https://github.com/polymny/polymny"
                    , label = Element.text "Fork me!"
                    }
                ]
            ]
        ]


bottomBarPhone : Core.Global -> Element Core.Msg
bottomBarPhone global =
    Element.column
        [ Element.width Element.fill
        , Background.color Colors.greyLighter
        , Border.color Colors.grey
        , Border.widthEach { top = 1, bottom = 0, left = 0, right = 0 }
        , Font.size 10
        ]
        [ Element.el [ Element.height Element.fill ] Element.none
        , Element.column
            [ Element.width Element.fill, Element.alignBottom, Element.spacing 4, Element.padding 8 ]
            [ Element.paragraph
                []
                [ Element.text "Polymny studio:"
                , Element.link
                    Ui.linkAttributes
                    { url = "mailto:contacter@polymny.studio"
                    , label = Element.text "contacter@polymny.studio"
                    }
                ]
            , Element.link
                Ui.linkAttributes
                { url = global.home ++ "/protection-des-donnees/"
                , label = Element.text "Données personnelles"
                }
            , Element.link
                Ui.linkAttributes
                { url = global.home ++ "/cgu/"
                , label = Element.text "Conditions d'utilisation"
                }
            , Element.paragraph []
                [ Element.text
                    ("Polymny"
                        ++ global.version
                        ++ (if global.beta then
                                " beta " ++ global.commit

                            else
                                ""
                           )
                    )
                , Ui.linkButton (Just Core.AboutClicked) "\u{00A0}A propos"
                ]
            , Element.paragraph [ Element.alignLeft, Element.spacing 5 ]
                [ Element.link
                    Ui.linkAttributes
                    { url = "https://www.gnu.org/licenses/agpl-3.0.en.html"
                    , label = Element.text "Gnu Affero V3. "
                    }
                , Element.link
                    Ui.linkAttributes
                    { url = "https://github.com/polymny/polymny"
                    , label = Element.text "Fork me!"
                    }
                ]
            ]
        ]


partnersView : Element.Device -> Element Core.Msg
partnersView device =
    let
        ( logoSmall, columnAttributes ) =
            case device.class of
                Element.Phone ->
                    ( 40
                    , [ Element.centerX
                      , Element.width <| Element.maximum 300 Element.fill
                      , Font.justify
                      , Element.paddingXY 4 20
                      , Font.size 14
                      ]
                    )

                _ ->
                    ( 80
                    , [ Element.centerX
                      , Element.width <| Element.maximum 700 Element.fill
                      , Font.justify
                      , Element.paddingXY 4 20
                      , Font.size 20
                      ]
                    )
    in
    Element.column columnAttributes
        [ Element.paragraph [] [ Element.text "Polymny.studio est issu d'un programme 2020-2021 de pré-maturation de la Région Occitanie." ]
        , Element.el [ Element.centerX, Element.paddingXY 30 5 ] <| viewLogo 100 "/dist/logoRegionOccitanie.png" <| Just "Logo région Occitanie"
        , Element.paragraph [ Font.center ] [ Element.text "Les acteurs, les utilisateurs et les soutiens :" ]
        , Element.row [ Element.centerX, Element.spacing 10 ]
            [ viewLogo logoSmall "/dist/logoTTT.png" <| Just "Logo TTT"
            , viewLogo logoSmall "/dist/logoIRIT.png" <| Just "Logo IRIT"
            , viewLogo logoSmall "/dist/logoCEPFOR.png" <| Just "Logo CEPFOR"
            , viewLogo logoSmall "/dist/logoCERESA.png" <| Just "Logo CERESA"
            , viewLogo logoSmall "/dist/logoDYP.png" <| Just "Logo DYP - Dyanmique pédagogique"
            , viewLogo logoSmall "/dist/logoINP.png" <| Just "Logo INP Toulouse"
            , viewLogo logoSmall "/dist/logoUT2J.png" <| Just "Logo Université Jean Jaurès"
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


viewLogo : Int -> String -> Maybe String -> Element Core.Msg
viewLogo size url desc =
    let
        description =
            case desc of
                Just x ->
                    x

                Nothing ->
                    "Missing desc"
    in
    Element.image [ Element.centerX, Element.width (Element.px size) ] { src = url, description = description }
