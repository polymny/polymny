module LoggedIn.Views exposing (view)

import Acquisition.Types as Acquisition
import Acquisition.Views as Acquisition
import Api
import Core.Types as Core
import Edition.Types as Edition
import Edition.Views as Edition
import Element exposing (Element)
import Element.Font as Font
import File
import LoggedIn.Types as LoggedIn
import NewCapsule.Types as NewCapsule
import NewCapsule.Views as NewCapsule
import NewProject.Views as NewProject
import Preparation.Types as Preparation
import Preparation.Views as Preparation
import Status
import TimeUtils
import Ui.Ui as Ui


view : Core.Global -> Api.Session -> LoggedIn.Tab -> Element Core.Msg
view global session tab =
    let
        mainTab =
            case tab of
                LoggedIn.Home uploadForm showMenu ->
                    homeView global session uploadForm showMenu

                LoggedIn.Preparation preparationModel ->
                    Preparation.view session preparationModel

                LoggedIn.Acquisition acquisitionModel ->
                    Acquisition.view global session acquisitionModel

                LoggedIn.Edition editionModel ->
                    Edition.view global session editionModel

                LoggedIn.NewProject newProjectModel ->
                    NewProject.view newProjectModel

                LoggedIn.Project project newCapsuleForm ->
                    projectView project newCapsuleForm

        element =
            Element.column
                [ Element.alignTop
                , Element.padding 10
                , Element.width Element.fill
                , Element.scrollbarX
                ]
                [ mainTab
                ]
    in
    Element.row
        [ Element.height Element.fill
        , Element.width Element.fill
        , Element.spacing 20
        ]
        [ element ]


homeView : Core.Global -> Api.Session -> LoggedIn.UploadForm -> Bool -> Element Core.Msg
homeView global session uploadForm showMenu =
    let
        projects =
            if showMenu then
                projectsView global session.projects

            else
                Element.map Core.LoggedInMsg <|
                    Ui.menuPointButton (Just LoggedIn.ShowMenuToggleMsg) " Projets"
    in
    Element.column
        [ Element.width
            Element.fill
        ]
        [ Element.row
            [ Element.spacing 20
            , Element.padding 20
            , Element.width Element.fill
            ]
            [ Element.el
                [ Element.width Element.fill
                ]
              <|
                uploadFormView uploadForm
            , Element.el
                [ Element.width Element.shrink
                ]
                projects
            ]
        ]


uploadFormView : LoggedIn.UploadForm -> Element Core.Msg
uploadFormView { status, file } =
    let
        filename =
            case file of
                Nothing ->
                    ""

                Just realFile ->
                    File.name realFile

        message =
            case status of
                Status.Sent ->
                    Ui.messageWithSpinner
                        ("Préparation de l'enregistement pour le fichier\n " ++ filename)

                Status.Error () ->
                    Ui.errorModal "Echec upload pdf"

                Status.Success () ->
                    Ui.successModal "L Upload du pdf a réussis"

                _ ->
                    Element.none
    in
    Element.row [ Element.centerX, Element.spacing 20 ]
        [ Element.column
            [ Element.spacing 20
            , Element.centerX
            , Font.size 18
            , Font.center
            ]
            [ Element.paragraph
                [ Element.width (Element.fill |> Element.maximum 400)
                , Font.size 14
                , Font.justify
                ]
                [ Element.text " Pour commencer un enregistrement, il faut séléctionner un fichier PDF sur votre machine. Une fois la présentation téléchargée, l'enregisterment vidéo des planches pourra débuter"
                ]
            , message
            , selectFileButton
            ]
        ]


selectFileButton : Element Core.Msg
selectFileButton =
    Element.map Core.LoggedInMsg <|
        Element.map LoggedIn.UploadSlideShowMsg <|
            Ui.simpleButton (Just LoggedIn.UploadSlideShowSelectFileRequested) "Choisir un fichier PDF"


projectsView : Core.Global -> List Api.Project -> Element Core.Msg
projectsView global projects =
    case projects of
        [] ->
            Element.paragraph [ Element.padding 10, Font.size 18 ]
                [ Element.text "You have no projects yet. "
                , Ui.linkButton
                    (Just Core.NewProjectClicked)
                    "Click here to create a new project!"
                ]

        _ ->
            let
                sortedProjects =
                    List.sortBy (\x -> -x.lastVisited) projects
            in
            Element.column [ Element.padding 10 ]
                [ Element.map Core.LoggedInMsg <|
                    Ui.cancelButton (Just LoggedIn.ShowMenuToggleMsg) ""
                , Element.el [ Font.size 18 ] (Element.text "Vos projets:")
                , Element.column [ Element.padding 10, Element.spacing 10 ]
                    (List.map (projectHeader global) sortedProjects)
                , newProjectButton
                ]


newProjectButton : Element Core.Msg
newProjectButton =
    Ui.primaryButton (Just Core.NewProjectClicked) "Créer un nouveau projet"


projectHeader : Core.Global -> Api.Project -> Element Core.Msg
projectHeader global project =
    Element.row [ Element.spacing 10 ]
        [ Ui.linkButton
            (Just
                (Core.LoggedInMsg <|
                    LoggedIn.ProjectClicked project
                )
            )
            project.name
        , Element.text (TimeUtils.timeToString global.zone project.lastVisited)
        ]


headerView : List (Element Core.Msg) -> Element Core.Msg -> List (Element Core.Msg)
headerView header el =
    case List.length header of
        0 ->
            [ el ]

        _ ->
            header ++ [ el ]


projectView : Api.Project -> Maybe NewCapsule.Model -> Element Core.Msg
projectView project newCapsuleModel =
    let
        headers =
            headerView [] <| Element.text (" / " ++ project.name)

        newCapsuleForm =
            case newCapsuleModel of
                Just m ->
                    NewCapsule.view m

                Nothing ->
                    Element.none
    in
    Element.column
        [ Element.width (Element.fill |> Element.maximum 800)
        ]
        [ Element.row [ Font.size 18 ] <| headers
        , Element.row [ Element.width Element.fill, Element.alignTop, Element.padding 20, Element.spacing 30 ]
            [ Element.column [ Element.alignLeft, Element.width Element.fill, Element.alignTop, Element.padding 10 ]
                [ Element.el [ Element.alignLeft ] <| newCapsuleButton project
                , Element.column [ Element.padding 10, Element.spacing 10 ]
                    (List.map capsuleView project.capsules)
                ]
            , Element.el [ Element.alignRight ] newCapsuleForm
            ]
        ]


capsuleView : Api.Capsule -> Element Core.Msg
capsuleView capsule =
    Element.column [ Element.spacing 10 ]
        [ Ui.linkButton
            (Just
                (Core.LoggedInMsg <|
                    LoggedIn.CapsuleClicked capsule
                )
            )
            capsule.name
        , Element.text capsule.title
        , Element.text capsule.description
        ]


newCapsuleButton : Api.Project -> Element Core.Msg
newCapsuleButton project =
    Ui.primaryButton
        (Just
            (Core.LoggedInMsg <|
                LoggedIn.NewCapsuleClicked project
            )
        )
        "New capsule"
