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
    in
    Element.column
        [ Element.centerX
        , Element.padding 30
        , Element.alignTop
        , Font.size 20
        , Font.justify
        , Element.centerX
        ]
        [ Element.column [ Element.centerX ]
            [ Element.textColumn [ Element.centerX ]
                [ Element.el Attributes.attributesHomeTitle <| Element.text "Polymny Studio"
                , Element.paragraph [ Element.width <| Element.maximum 600 Element.fill ] [ Element.text "Polymny est le studio web des formateurs qui créent, modifient et gèrent des vidéos pédagogiques\u{00A0}! A partir d’une présentation existante (libre office, powerpoint, beamer, etc.), vous fournissez vos diapositives en PDF et enregistrez une vidéo pédagogique pour vos élèves, vos étudiants, vos clients ou vos collègues. " ]
                ]
            , Element.column
                [ Element.padding 30
                ]
                [ form, forgotPasswordLink, button ]
            , Element.paragraph [ Element.width <| Element.maximum 600 Element.fill ]
                [ Element.text "Polymny est un logiciel libre, utilisable gratuitement, 100% web, indépendant du système d’exploitation de votre ordinateur (windows, macOS, linux). Il suffit de créer un compte pour enregistrer une première capsule vidéo.  Besoin d'aide, de  support \u{00A0}:  "
                , Element.link
                    []
                    { url = "mailto:contacter@polymnu.studio"
                    , label =
                        Element.el
                            [ Font.underline
                            , Font.bold
                            ]
                        <|
                            Element.text "contacter@polymny.studio"
                    }
                ]
            ]
        , Element.link
            [ Element.centerX, Element.padding 30 ]
            { url = "/#tutoriels"
            , label =
                Element.el
                    [ Font.color Colors.primary
                    , Font.underline
                    , Font.bold
                    ]
                <|
                    Element.text "Tutoriels d'utilisation de polymny "
            }
        , partnersView
        , featuresView device
        , tutosView
        , Element.textColumn [ Element.centerX, Element.width <| Element.maximum 1000 Element.fill, Font.size 20, Element.padding 30, Element.spacing 20 ]
            [ Element.paragraph []
                [ Element.text "Contacts\u{00A0}:"
                , Element.link
                    []
                    { url = "mailto:contacter@polymnu.studio"
                    , label =
                        Element.el
                            [ Font.underline
                            , Font.bold
                            ]
                        <|
                            Element.text "contacter@polymny.studio"
                    }
                ]
            , Element.paragraph [] [ Element.text "Nicolas Bertrand, Thomas Forgione, Axel Carlier, Vincent Charvillat" ]
            , Element.paragraph [] [ Element.text "Post-scriptum pour la planète. L’équipe de Polymny.studio s’engage enfin à estimer et limiter l’impact environnemental des vidéos stockées sur ses serveurs (ou sur vos serveurs dédiés et sécurisés, serveurs professionnels, associatifs, universitaires ou HDS par exemple). Une contribution éco-citoyenne est demandée aux utilisateurs de Polymny qui consomment, sur la durée, beaucoup de stockage. " ]
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
            case model of
                Core.LoggedIn { session } ->
                    session.notifications |> List.filter (not << .read) |> List.length

                _ ->
                    0

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
                    [ notificationIcon
                    , settingsButton session.username
                    , logoutButton
                    ]

                _ ->
                    []
    in
    Element.row
        (Background.color Colors.primary
            :: Font.color Colors.white
            :: Element.width Element.fill
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


featuresView : Element.Device -> Element Core.Msg
featuresView device =
    let
        imageSize =
            500

        twoColMaximum =
            500

        ( builder, contentSpacing ) =
            case device.class of
                Element.Phone ->
                    ( Element.column [ Element.width Element.fill, Element.height Element.fill, Element.paddingXY 2 50 ]
                    , Element.spacingXY 2 40
                    )

                _ ->
                    ( Element.row [ Element.width Element.fill, Element.paddingXY 2 50, Element.spacingXY 40 10 ]
                    , Element.spacingXY 2 50
                    )
    in
    Element.column [ Element.centerX, Element.width Element.fill, Font.justify, Font.size 20, Element.spacingXY 5 50 ]
        [ Assets.videoBonjour
        , builder
            [ Element.column
                [ Element.centerX
                ]
                [ Element.el [ Element.centerX, Border.rounded 100 ] <|
                    Element.image [ Element.width <| Element.px imageSize ]
                        { src = "/dist/moodle.png"
                        , description = "Partager des capsules sur moodle"
                        }
                ]
            , Element.column [ Element.width <| Element.maximum twoColMaximum Element.fill, Element.centerX ]
                [ Element.el [ Element.centerX, Font.bold, Font.size 40 ] <| Element.text "Partage des capsules"
                , Element.paragraph [ Element.centerX ]
                    [ Element.text "Aucune expertise technique n’est requise, pas de montage, pas de compression, pas de manipulations numériques des vidéos. Les capsules sont automatiquement stockées et publiées en ligne sur un serveur vidéo. Elles sont accessibles par un lien web (url) partageable par mail ou texto, sur les réseaux sociaux ou sur toute plateforme de formation (moodle, 360, etc.). La figure de gauche montre des vidéos polymny partagées sur MOODLE." ]
                ]
            ]
        , builder
            [ Element.column [ Element.width <| Element.maximum twoColMaximum Element.fill, Element.centerX ]
                [ Element.el [ Element.centerX, Font.bold, Font.size 40 ] <| Element.text "Enregistrement facile"
                , Element.paragraph [ Element.centerX ]
                    [ Element.text "A la différence des logiciels d’enregistrement d’écrans, Polymny guide et facilite l’enregistrement des commentaires vidéos (avec la webcam) ou audios (avec le micro de votre ordinateur).  L’enregistrement se fait simplement depuis un navigateur web." ]
                ]
            , Element.column
                [ Element.width Element.fill
                , Element.centerY
                , Element.spacing 10
                ]
                [ Element.el [ Element.centerX, Border.rounded 100 ] <|
                    Element.image [ Element.width <| Element.px imageSize ]
                        { src = "/dist/recording.png"
                        , description = "S'enregsitrer"
                        }
                ]
            ]
        , builder
            [ Element.column
                [ Element.width Element.fill
                , Element.centerY
                , Element.spacing 10
                ]
                [ Element.el [ Element.centerX, Border.rounded 100 ] <|
                    Element.image [ Element.width <| Element.px imageSize ]
                        { src = "/dist/bigPicture.png"
                        , description = "Polymny en 4 étapes"
                        }
                ]
            , Element.column [ Element.width <| Element.maximum twoColMaximum Element.fill, Element.centerX, Element.spacing 10 ]
                [ Element.el [ Element.centerX, Font.bold, Font.size 40 ] <| Element.text "4 étapes"
                , Element.paragraph [ Element.centerX ]
                    [ Element.text "Le protocole de Polymny repose sur 4 étapes : préparer (en utilisant ou pas le prompteur), filmer (en se limitant éventuellement au son), produire (en plaçant les médias selon différents motifs) et publier (en obtenant le lien à partager sans aucun effort technique)." ]
                ]
            ]
        , builder
            [ Element.column [ Element.width <| Element.maximum twoColMaximum Element.fill, Element.centerX, Element.spacing 10 ]
                [ Element.el [ Element.centerX, Font.bold, Font.size 40 ] <| Element.text "Gérer les caspules"
                , Element.paragraph [ Element.centerX ]
                    [ Element.text "Aucune minute passée pour s’enregistrer n’est perdue, chaque effort est modifiable et réutilisable plus tard : comme au cinéma, vous pouvez multiplier les «\u{00A0}prises\u{00A0}» pour satisfaire le réalisateur (vous\u{00A0}!).  Vous n’enregistrez plus votre écran mais vous gérez vos projets de capsules vidéos, d’une année sur l’autre, d’une classe à l’autre, d’une version initiale à l’amélioration suivante\u{00A0}! L’interface de Polymny ci-contre montre 3 projets d’un utilisateur\u{00A0}: 3 séquences pédagogiques comportant chacune plusieurs capsules vidéos, dont certaines en cours de préparation ne sont pas encore finalisées."
                    ]
                , Element.paragraph [ Element.centerX ]
                    [ Element.text "Gérer chaque capsule comme un projet permet l’intervention d’ingénieurs pédagogiques ou de communicants dans la phase de préparation des ressources pédagogiques\u{00A0}: alignement pédagogique, ajustement de la durée du message ou de la clarté de la vidéo. "
                    ]
                ]
            , Element.column
                [ Element.width Element.fill
                , Element.centerY
                , Element.spacing 10
                ]
                [ Element.el [ Element.centerX, Border.rounded 100 ] <|
                    Element.image [ Element.width <| Element.px imageSize ]
                        { src = "/dist/projectManagement.png"
                        , description = "Gestion de capsules"
                        }
                ]
            ]
        , builder
            [ Element.column
                [ Element.width Element.fill
                , Element.centerY
                , Element.spacing 10
                ]
                [ Element.el [ Element.centerX, Border.rounded 100 ] <|
                    Element.image [ Element.width <| Element.px imageSize ]
                        { src = "/dist/addResource.png"
                        , description = "ajout de vidéos additionelles"
                        }
                ]
            , Element.column [ Element.width <| Element.maximum twoColMaximum Element.fill, Element.centerX, Element.spacing 10 ]
                [ Element.el [ Element.centerX, Font.bold, Font.size 40 ] <| Element.text "Vidéos additionelles"
                , Element.paragraph [ Element.centerX ]
                    [ Element.text "Parmi les fonctionnalités plébiscitées, Polymny permet d’insérer, en lieu et place d’une diapositive, toute vidéo externe (captures de vos écrits sur tablettes pour les enseignants, vidéos ou screencasts issus d’un smartphone, clips libres de droit importés depuis internet). L’illustration suivante montre un jingle vidéo (une animation) insérée en guise de générique d’une vidéo de formation. Polymny est utilisé avec succès par des formateurs des sphères publiques (universités, lycées, MOOC FUN) et privées (organismes de formation professionnelle).\n" ]
                ]
            ]
        , builder
            [ Element.column
                [ Element.width Element.fill
                , Element.centerY
                , Element.spacing 10
                ]
                [ Element.el [ Element.centerX ] Element.none
                , Element.paragraph [ Font.bold, Font.size 40, Font.center ] [ Element.text "Fonctions avancées" ]
                , Element.textColumn [ Element.width <| Element.maximum twoColMaximum Element.fill, Element.centerX, Element.paddingXY 20 2, Element.spacingXY 2 10 ]
                    [ Element.paragraph [ Element.centerX ]
                        [ Element.text "Des fonctionnalités avancées sont disponibles sous forme de services additionnels et optionnels."
                        ]
                    , Element.paragraph
                        [ Element.width <| Element.maximum twoColMaximum Element.fill, Element.centerX ]
                        [ Element.text "Si votre capsule, déjà préparée et prototypée sur le web, mérite une version professionnelle, l’équipe de Polymny met à votre disposition\u{00A0}:"
                        ]
                    , Element.wrappedRow [ Element.alignLeft ]
                        [ Element.el
                            [ Element.alignTop
                            , Element.paddingXY 10 0
                            , Font.bold
                            ]
                            (Element.text "•")
                        , Element.paragraph []
                            [ Element.text <| "des services de production en studios audiovisuels virtuels (incrustations, keying/matting par deeplearning, génération graphique de background et foreground dynamiques, pointeurs, templates d’édition personnalisés, système de recommandation pour la grammaire du montage),"
                            ]
                        ]
                    , Element.wrappedRow [ Element.alignLeft ]
                        [ Element.el
                            [ Element.alignTop
                            , Element.paddingXY 10 0
                            , Font.bold
                            ]
                            (Element.text "•")
                        , Element.paragraph []
                            [ Element.text "des services de production en studios physiques accessibles par réservation (incrustations et keying fond vert, caméras et plans multiples, son haute qualité, scénarios de dialogues multi-micros, pré/postproduction). "
                            ]
                        ]
                    ]
                ]
            , Element.column
                [ Element.width Element.fill
                , Element.centerY
                , Element.spacing 10
                ]
                [ Element.el [ Element.centerX, Border.rounded 100 ] <|
                    Element.image [ Element.width <| Element.px imageSize ]
                        { src = "/dist/studioFondVert.png"
                        , description = "Studio fond vert"
                        }
                ]
            ]
        , Element.paragraph [ Element.centerX, Element.width <| Element.maximum 1000 Element.fill, Font.size 20 ]
            [ Element.text "La préparation et la gestion de projet opérées en amont, sur le web et sur le socle open-source, limitent le temps de réservation des studios, accélèrent et fluidifient la production professionnelle pour un coût de la minute de vidéo produite rendu ultra compétitif. Ce protocole innovant a fait l’objet de recherches \u{00A0}[Bakkay et al. 2019]\u{00A0} à l’IRIT (Toulouse INP – ENSEEIHT) depuis 2016. La région Occitanie finance actuellement le développement de Polymny au travers d’un projet de pré-maturation et de l’accompagnement de Toulouse Tech Transfer."
            ]
        , Element.paragraph
            [ Element.centerX, Element.width <| Element.maximum 1000 Element.fill, Font.size 18, Font.italic ]
            [ Element.text "Bakkay et al  (2019). Protocols and software for simplified educational video capture and editing. Journal of Computers in Education, 6(2), 257-276."
            , Element.link
                []
                { url = "https://oatao.univ-toulouse.fr/24824/1/bakkay_24824.pdf"
                , label =
                    Element.el
                        [ Font.italic
                        , Font.underline
                        ]
                    <|
                        Element.text "\u{00A0}link"
                }
            ]
        ]


tutosView : Element Core.Msg
tutosView =
    Element.column [ Element.centerX, Element.padding 30, Element.spacingXY 0 30 ]
        [ Element.el
            [ Element.centerX
            , Font.bold
            , Font.size 40
            , Element.htmlAttribute (Html.Attributes.id "tutoriels")
            ]
          <|
            Element.text "Tutoriels polymny en vidéo."
        , Assets.videoPlayerView
            "Étape 1: Débuter avec polymny"
            "https://video.polymny.studio/?v=b4a86be5-eb21-4681-8716-b96458e60cfe/"
        , Assets.videoPlayerView
            "Étape 2 : Choisir les options de production"
            "https://video.polymny.studio/?v=a60ee619-48f0-49ca-9a01-2c6611842980/"
        , Assets.videoPlayerView
            "Étape 3: Insérer une vidéo additionelle"
            "https://video.polymny.studio/?v=c7c42c13-52cd-47ea-8e6e-35b1209ca1b4/"
        , Assets.videoPlayerView
            "Étape 4: Utiliser le prompteur"
            "https://video.polymny.studio/?v=ce1b9dfa-44cb-4b4a-9d1d-a4dafe0116fc/"
        , Assets.videoPlayerView
            "Étape 5: Organiser les planches.  "
            "https://video.polymny.studio/?v=b8edf9bc-5ebc-4c9e-8b3b-af4c50fbb6f1/"
        ]


partnersView : Element Core.Msg
partnersView =
    let
        logoSmall =
            80
    in
    Element.column [ Element.centerX, Element.width <| Element.maximum 700 Element.fill, Element.padding 30, Element.spacing 20, Font.size 20 ]
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
