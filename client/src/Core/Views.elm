module Core.Views exposing (subscriptions, topBar, view)

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
    in
    Element.column
        [ Element.centerX
        , Element.spacing 50
        , Element.padding 30
        , Element.width (Element.fillPortion 4)
        , Element.alignTop
        , Font.size 20
        , Font.center
        ]
        [ Element.column [ Element.centerX, Element.width Element.fill ]
            [ Element.textColumn [ Element.centerX, Element.width Element.fill ]
                [ Element.el Attributes.attributesHomeTitle <| Element.text "Polymny Studio "
                , Element.paragraph [] [ Element.text "Le studio web des formateurs qui créent, modifient et gèrent des vidéos pédagogiques\u{00A0}!" ]
                , Element.paragraph [] [ Element.text "Le tout à distance, sans obstacles ni prérequis, à partir de simples présentations pdf.\n" ]
                ]
            , Element.column
                [ Element.centerX
                , Element.alignTop
                ]
                [ form, forgotPasswordLink, button ]
            ]
        , featuresView
        , partnersView
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


featuresView : Element Core.Msg
featuresView =
    Element.column [ Element.centerX, Element.width Element.fill, Element.spacing 20 ]
        [ Assets.videoBonjour
        , Element.row []
            [ Element.textColumn [ Element.spacing 5, Element.padding 10, Font.size 20, Font.alignLeft ]
                [ Element.el [ Element.centerX ] Element.none
                , Element.paragraph [ Font.bold, Font.size 48, Font.center ] [ Element.text "Que fait polymny?" ]
                , Element.textColumn [ Element.paddingXY 20 2, Font.alignLeft ]
                    [ Element.paragraph [ Element.centerX, Font.alignLeft ]
                        [ Element.text "A partir d'un présentation au format PDF vous simplifie la création et la distribution d'une capsule vidéo. L'outil permet par des étapes simples:"
                        ]
                    , Element.el [ Element.alignLeft, Element.padding 2 ] Element.none
                    , Element.paragraph [ Element.alignLeft, Element.spacingXY 10 0 ]
                        [ Element.el
                            [ Element.alignLeft
                            , Element.paddingXY 20 30
                            , Font.bold
                            ]
                            (Element.text "-")
                        , Element.text "Préparer la présentation PDF en vue de la création de la capsule vidéo. Ajouter des resources vidéos, grouper des planches, supprimer des planches, ..."
                        ]
                    , Element.paragraph [ Element.alignLeft, Element.spacingXY 10 0 ]
                        [ Element.el
                            [ Element.alignLeft
                            , Element.paddingXY 20 40
                            , Font.bold
                            ]
                            (Element.text "-")
                        , Element.text "Se filmer avec une webcam planche par planche. L'outil permet de facilement recommencer un enregistrement sans avoir à tourt reprendre. On peut aussi s'aider d'un prompteur pour de la lecture de texte."
                        ]
                    , Element.paragraph [ Element.alignLeft, Element.spacingXY 10 0 ]
                        [ Element.el
                            [ Element.alignLeft
                            , Element.paddingXY 20 20
                            , Font.bold
                            ]
                            (Element.text "-")
                        , Element.text "Produire une capsule. Choisir ou positionner la webcam sur une planhe ou bien de n'activer que la voix sur une planche."
                        ]
                    , Element.paragraph [ Element.alignLeft, Element.spacingXY 10 0 ]
                        [ Element.el
                            [ Element.alignLeft
                            , Element.paddingXY 20 20
                            , Font.bold
                            ]
                            (Element.text "-")
                        , Element.text "Publier la capsule. L'outil ajoute la capsule dans un serveur vidéo. On peut alors diffuser la vidéo par un simple lien."
                        ]
                    ]
                ]
            , Element.el [ Element.paddingXY 30 5, Element.alignLeft ] <| viewLogo 700 "/dist/bigPicture.png" <| Just "Vue globale de Polymny"
            ]
        , Element.row [ Element.width Element.fill, Element.height Element.fill, Element.padding 50, Element.spacing 20 ]
            [ Element.column
                [ Element.width Element.fill
                , Element.centerY
                , Element.spacing 10
                , Border.widthEach { right = 1, left = 0, top = 0, bottom = 0 }
                , Border.color <| Element.rgb255 0xE0 0xE0 0xE0
                ]
                [ Element.el [ Element.centerX, Border.rounded 100 ] <|
                    Element.image [ Element.width <| Element.px 700 ]
                        { src = "/dist/projectManagement.png"
                        , description = "Gestion de projet"
                        }
                ]
            , Element.column [ Element.width Element.fill, Element.centerY, Element.spacing 10 ]
                [ Element.el [ Element.centerX, Font.bold, Font.size 48 ] <| Element.text "Gestion de projet"
                , Element.paragraph [ Element.width <| Element.maximum 400 Element.fill, Element.centerX, Font.size 20, Font.alignLeft ]
                    [ Element.text "Polymny vous permet d'organsier vos capsules videos, et de les regrouper par projet. " ]
                ]
            ]
        , Element.row [ Element.width Element.fill, Element.height Element.fill, Element.padding 50, Element.spacing 20 ]
            [ Element.column [ Element.width Element.fill, Element.centerY, Element.spacing 10 ]
                [ Element.el [ Element.centerX, Font.bold, Font.size 48 ] <| Element.text "Enregistrement facile"
                , Element.paragraph [ Element.width <| Element.maximum 400 Element.fill, Element.centerX, Font.size 20, Font.alignLeft ]
                    [ Element.text "Enregistrez vous depuis votre webcam. Interface intuitive et épurée pour s'enregistrer autant de fois que nécessaire et garder le meilleur shoot. " ]
                ]
            , Element.column
                [ Element.width Element.fill
                , Element.centerY
                , Element.spacing 10
                , Border.widthEach { right = 1, left = 0, top = 0, bottom = 0 }
                , Border.color <| Element.rgb255 0xE0 0xE0 0xE0
                ]
                [ Element.el [ Element.centerX, Border.rounded 100 ] <|
                    Element.image [ Element.width <| Element.px 700 ]
                        { src = "/dist/recording.png"
                        , description = "S'enregsitrer"
                        }
                ]
            ]
        , Element.row [ Element.width Element.fill, Element.height Element.fill, Element.padding 50, Element.spacing 20 ]
            [ Element.column
                [ Element.width Element.fill
                , Element.centerY
                , Element.spacing 10
                , Border.widthEach { right = 1, left = 0, top = 0, bottom = 0 }
                , Border.color <| Element.rgb255 0xE0 0xE0 0xE0
                ]
                [ Element.el [ Element.centerX, Border.rounded 100 ] <|
                    Element.image [ Element.width <| Element.px 700 ]
                        { src = "/dist/productionWithVideo.png"
                        , description = "Générer la capsule"
                        }
                ]
            , Element.column [ Element.width Element.fill, Element.centerY, Element.spacing 10 ]
                [ Element.el [ Element.centerX, Font.bold, Font.size 48 ] <| Element.text "Rendu de la capsule"
                , Element.paragraph [ Element.width <| Element.maximum 400 Element.fill, Element.centerX, Font.size 20, Font.alignLeft ]
                    [ Element.text " On peut choisir d'incruster le retour caméra dans chaque coin de la planche ou bien de n'utiliser que l'audio.\n                    Aucune manipulation de fichier vidéo pour générer la vidéo" ]
                ]
            ]
        , Element.row [ Element.width Element.fill, Element.height Element.fill, Element.padding 50, Element.spacing 20 ]
            [ Element.column [ Element.width Element.fill, Element.centerY, Element.spacing 10 ]
                [ Element.el [ Element.centerX, Font.bold, Font.size 48 ] <| Element.text "Groupe de planches"
                , Element.paragraph [ Element.width <| Element.maximum 400 Element.fill, Element.centerX, Font.size 20, Font.alignLeft ]
                    [ Element.text "Suivant les usages on peut réalsier les enregistrements planche par planche. Mais aussi par groupe de planche: ceci permet d'expliciter une idée plus en détail, ou cadencer l'affichage des items d'une liste à puce." ]
                ]
            , Element.column
                [ Element.width Element.fill
                , Element.centerY
                , Element.spacing 10
                , Border.widthEach { right = 1, left = 0, top = 0, bottom = 0 }
                , Border.color <| Element.rgb255 0xE0 0xE0 0xE0
                ]
                [ Element.el [ Element.centerX, Border.rounded 100 ] <|
                    Element.image [ Element.width <| Element.px 700 ]
                        { src = "/dist/editionGos.png"
                        , description = "Groupe de planche"
                        }
                ]
            ]
        , Element.row [ Element.width Element.fill, Element.height Element.fill, Element.padding 50, Element.spacing 20 ]
            [ Element.column
                [ Element.width Element.fill
                , Element.centerY
                , Element.spacing 10
                , Border.widthEach { right = 1, left = 0, top = 0, bottom = 0 }
                , Border.color <| Element.rgb255 0xE0 0xE0 0xE0
                ]
                [ Element.el [ Element.centerX, Border.rounded 100 ] <|
                    Element.image [ Element.width <| Element.px 700 ]
                        { src = "/dist/prompteur.png"
                        , description = "Utilisation d'un prompteur"
                        }
                ]
            , Element.column [ Element.width Element.fill, Element.centerY, Element.spacing 10 ]
                [ Element.el [ Element.centerX, Font.bold, Font.size 48 ] <| Element.text "Utiliser un prompteur"
                , Element.paragraph [ Element.width <| Element.maximum 400 Element.fill, Element.centerX, Font.size 20, Font.alignLeft ]
                    [ Element.text "Lors d'un enregistrement, un prompteur peut s'afficher pour aider à la diction du propos associé à une planche." ]
                ]
            ]
        , Element.row [ Element.width Element.fill, Element.height Element.fill, Element.padding 50, Element.spacing 20 ]
            [ Element.column [ Element.width Element.fill, Element.centerY, Element.spacing 10 ]
                [ Element.el [ Element.centerX, Font.bold, Font.size 48 ] <| Element.text "Vidéos additionelles"
                , Element.paragraph [ Element.width <| Element.maximum 400 Element.fill, Element.centerX, Font.size 20, Font.alignLeft ]
                    [ Element.text "Insérer des vidéos supplémentaires dans la présentation. Jingle vidéos, screencasts, ...\n                " ]
                ]
            , Element.column
                [ Element.width Element.fill
                , Element.centerY
                , Element.spacing 10
                , Border.widthEach { right = 1, left = 0, top = 0, bottom = 0 }
                , Border.color <| Element.rgb255 0xE0 0xE0 0xE0
                ]
                [ Element.el [ Element.centerX, Border.rounded 100 ] <|
                    Element.image [ Element.width <| Element.px 700 ]
                        { src = "/dist/addResource.png"
                        , description = "ajout de vidéos additionelles"
                        }
                ]
            ]
        , Element.column [ Element.width Element.fill, Element.height Element.fill ]
            [ Element.row [ Element.width Element.fill, Element.height Element.fill, Element.padding 50, Element.spacing 20 ]
                [ Element.column
                    [ Element.width Element.fill
                    , Element.centerY
                    , Element.spacing 10
                    , Border.widthEach { right = 1, left = 0, top = 0, bottom = 0 }
                    , Border.color <| Element.rgb255 0xE0 0xE0 0xE0
                    ]
                    [ Element.el [ Element.centerX, Border.rounded 100 ] <|
                        Element.image [ Element.width <| Element.px 700 ]
                            { src = "/dist/publier.png"
                            , description = "Publier une capsule"
                            }
                    ]
                , Element.column [ Element.width Element.fill, Element.centerY, Element.spacing 10 ]
                    [ Element.el [ Element.centerX, Font.bold, Font.size 48 ] <| Element.text "Publier une capsule "
                    , Element.paragraph [ Element.width <| Element.maximum 400 Element.fill, Element.centerX, Font.size 20, Font.alignLeft ]
                        [ Element.text "On peut directement publier une capsule vidéo en ligne. Partager le lien générer suffit pour diffuser la vidéo."
                        ]
                    ]
                ]
            , Element.textColumn
                [ Element.centerX, Font.center ]
                [ Element.text "Exemple de lien :"
                , Element.link
                    []
                    { url = "https://video.polymny.studio/?v=971181dd-ecb3-4406-b193-07d6bd9be587/"
                    , label = Element.el [ Font.bold, Font.size 20 ] <| Element.text "https://video.polymny.studio/?v=971181dd-ecb3-4406-b193-07d6bd9be587/"
                    }
                ]
            ]
        , Element.row [ Element.width Element.fill, Element.height Element.fill, Element.padding 50, Element.spacing 20 ]
            [ Element.column [ Element.width Element.fill, Element.centerY, Element.spacing 10 ]
                [ Element.el [ Element.centerX, Font.bold, Font.size 48 ] <| Element.text "OS free"
                , Element.paragraph [ Element.width <| Element.maximum 400 Element.fill, Element.centerX, Font.size 20, Font.alignLeft ]
                    [ Element.text "Polymny est un service 100% web.  Il ne dépend pas d'un système d'exploitation. Et pas d'installation de logiciel à faire. Il est sur un nuage! Et il est libre, polymny! " ]
                ]
            , Element.column [ Element.width Element.fill, Element.centerY, Element.spacing 10 ]
                [ Element.el [ Element.centerX, Font.bold, Font.size 48 ] <| Element.text "Studio révé ?"
                , Element.paragraph [ Element.width <| Element.maximum 450 Element.fill, Element.centerX, Font.size 20, Font.alignLeft ]
                    [ Element.text "Utilisez le studio de l'équipe Reva ! Vous avez besoin de prises de vues de meilleure qualité? Un son plus limpide ? D'effet de type fond vert et détourage ? Un studio est à votre disposition à l'ENSEEIHT à Toulouse. Envoyez nous un mail à contatcter@polymny.studio, pour plus de détails sur cette prestation et son coût." ]
                ]
            ]
        ]


partnersView : Element Core.Msg
partnersView =
    let
        logoSmall =
            80
    in
    Element.column [ Element.centerX, Element.width Element.fill, Element.spacing 20, Font.size 20 ]
        [ Element.paragraph [ Font.center ] [ Element.text "Polymny.studio est issu d'un programme 2020-2021 de pré-maturation de la Région Occitanie." ]
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
