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
                    Ui.menuPointButton (Just LoggedIn.ShowMenuToggleMsg) ""
    in
    Element.column
        [ Element.width
            Element.fill
        ]
        [ Element.el [] (Element.text "Welcome in LoggedIn")
        , Element.row
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
                    Ui.primaryButtonDisabled "Creating project..."

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
            ]
            [ message
            , selectFileButton
            , fileNameElement file
            , uploadButton
            ]
        ]


fileNameElement : Maybe File -> Element Core.Msg
fileNameElement file =
    Element.text <|
        case file of
            Nothing ->
                "No file selected"

            Just realFile ->
                File.name realFile


selectFileButton : Element Core.Msg
selectFileButton =
    Element.map Core.LoggedInMsg <|
        Element.map LoggedIn.UploadSlideShowMsg <|
            Ui.simpleButton (Just LoggedIn.UploadSlideShowSelectFileRequested) "Choisir un fichier PDF"


uploadButton : Element Core.Msg
uploadButton =
    Element.map Core.LoggedInMsg <|
        Element.map LoggedIn.UploadSlideShowMsg <|
            Ui.primaryButton (Just LoggedIn.UploadSlideShowFormSubmitted) "Upload slide show"


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
