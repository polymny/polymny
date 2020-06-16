module LoggedIn.Views exposing (view)

import Acquisition.Types as Acquisition
import Acquisition.Views as Acquisition
import Api
import Core.Types as Core
import Element exposing (Element)
import Element.Font as Font
import File exposing (File)
import LoggedIn.Types as LoggedIn
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
                    Preparation.view global session preparationModel

                LoggedIn.Acquisition acquisitionModel ->
                    Acquisition.view global session acquisitionModel

                LoggedIn.Edition ->
                    Preparation.view global session Preparation.Home

                LoggedIn.Publication ->
                    Preparation.view global session Preparation.Home

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
        message =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "Préparation de l'enregitrement"

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
            , uploadFileElement file
            ]
        ]


uploadFileElement : Maybe File -> Element Core.Msg
uploadFileElement file =
    let
        button =
            case file of
                Nothing ->
                    Element.none

                Just realFile ->
                    uploadButton <| File.name realFile
    in
    Element.column [ Element.centerX ]
        [ button
        ]


selectFileButton : Element Core.Msg
selectFileButton =
    Element.map Core.LoggedInMsg <|
        Element.map LoggedIn.UploadSlideShowMsg <|
            Ui.simpleButton (Just LoggedIn.UploadSlideShowSelectFileRequested) "Choisir un fichier PDF"


uploadButton : String -> Element Core.Msg
uploadButton filename =
    Element.map Core.LoggedInMsg <|
        Element.map LoggedIn.UploadSlideShowMsg <|
            Ui.simpleButton (Just LoggedIn.UploadSlideShowFormSubmitted) ("Télécharger le fichier " ++ filename)


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
                    LoggedIn.PreparationMsg <|
                        Preparation.ProjectClicked project
                )
            )
            project.name
        , Element.text (TimeUtils.timeToString global.zone project.lastVisited)
        ]
