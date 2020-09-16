module LoggedIn.Views exposing (dropdownConfig, view)

import Acquisition.Types as Acquisition
import Acquisition.Views as Acquisition
import Api
import Core.Types as Core
import Dropdown
import Edition.Types as Edition
import Edition.Views as Edition
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import File
import LoggedIn.Types as LoggedIn
import NewCapsule.Types as NewCapsule
import NewCapsule.Views as NewCapsule
import NewProject.Views as NewProject
import Preparation.Types as Preparation
import Preparation.Views as Preparation
import Settings.Views as Settings
import Status
import TimeUtils
import Ui.Colors as Colors
import Ui.Ui as Ui


view : Core.Global -> Api.Session -> LoggedIn.Tab -> Element Core.Msg
view global session tab =
    let
        mainTab =
            case tab of
                LoggedIn.Home uploadForm ->
                    homeView global session uploadForm

                LoggedIn.Preparation preparationModel ->
                    Preparation.view global session preparationModel

                LoggedIn.Acquisition acquisitionModel ->
                    Acquisition.view global session acquisitionModel

                LoggedIn.Edition editionModel ->
                    Edition.view global session editionModel

                LoggedIn.NewProject newProjectModel ->
                    NewProject.view newProjectModel

                LoggedIn.Project project newCapsuleForm ->
                    projectView global project newCapsuleForm

                LoggedIn.Settings modelSettings ->
                    Settings.view global session modelSettings

        element =
            Element.column
                [ Element.alignTop
                , Element.width Element.fill
                , Element.height Element.fill
                , Element.scrollbarY
                ]
                [ mainTab
                ]
    in
    Element.row
        [ Element.height Element.fill
        , Element.scrollbarY
        , Element.width Element.fill
        , Element.spacing 20
        ]
        [ element ]


homeView : Core.Global -> Api.Session -> LoggedIn.UploadForm -> Element Core.Msg
homeView global session uploadForm =
    case uploadForm.status of
        Status.NotSent ->
            Element.row [ Element.width Element.fill, Element.height Element.fill ]
                [ Element.el
                    [ Element.width (Element.fillPortion 1)
                    , Background.color Colors.grey
                    , Element.height Element.fill
                    ]
                    (leftColumn global session uploadForm)
                , newProjectsView global session uploadForm
                ]

        _ ->
            prePreparationView global session uploadForm


prePreparationView : Core.Global -> Api.Session -> LoggedIn.UploadForm -> Element Core.Msg
prePreparationView global session uploadForm =
    let
        projectField =
            Element.column [ Element.width Element.fill, Element.spacing 10 ]
                [ Element.text "Nom du projet"
                , Dropdown.view dropdownConfig uploadForm.dropdown session.projects
                ]

        -- Input.text []
        --     { label = Input.labelAbove [] (Element.text "Nom du projet")
        --     , onChange = \x -> Core.LoggedInMsg (LoggedIn.UploadSlideShowMsg (LoggedIn.UploadSlideShowChangeProjectName x))
        --     , text = uploadForm.projectName
        --     , placeholder = Nothing
        --     }
        capsuleField =
            Input.text []
                { label = Input.labelAbove [] (Element.text "Nom de la capsule")
                , onChange = \x -> Core.LoggedInMsg (LoggedIn.UploadSlideShowMsg (LoggedIn.UploadSlideShowChangeCapsuleName x))
                , text = uploadForm.capsuleName
                , placeholder = Nothing
                }

        slidesLabel =
            Element.text "Regroupement des planches"

        viewSlide : Maybe ( Int, ( Int, Api.Slide ) ) -> Element Core.Msg
        viewSlide slide =
            case slide of
                Nothing ->
                    Element.el [ Element.width Element.fill ] Element.none

                Just ( index, ( i, s ) ) ->
                    Input.button
                        [ Element.width Element.fill, Element.padding 10, Background.color (getColor i) ]
                        { onPress =
                            Just
                                (Core.LoggedInMsg (LoggedIn.UploadSlideShowMsg (LoggedIn.UploadSlideShowSlideClicked index)))
                        , label =
                            Element.image [ Element.width Element.fill ]
                                { description = "", src = s.asset.asset_path }
                        }

        slides =
            case uploadForm.slides of
                Nothing ->
                    Ui.spinner

                Just s ->
                    let
                        enumeratedSlides =
                            List.indexedMap (\x y -> ( x, y )) s
                    in
                    Element.column [ Element.width Element.fill ]
                        (List.map
                            (\x ->
                                Element.row [ Element.width Element.fill ]
                                    (List.map viewSlide x)
                            )
                            (regroupSlides uploadForm.numberOfSlidesPerRow enumeratedSlides)
                        )

        cancel =
            Core.LoggedInMsg (LoggedIn.UploadSlideShowMsg LoggedIn.UploadSlideShowCancel)

        goToAcquisition =
            Core.LoggedInMsg (LoggedIn.UploadSlideShowMsg LoggedIn.UploadSlideShowGoToAcquisition)

        goToPreparation =
            Core.LoggedInMsg (LoggedIn.UploadSlideShowMsg LoggedIn.UploadSlideShowGoToPreparation)

        buttons =
            Element.row [ Element.width Element.fill ]
                [ Element.row [ Element.alignLeft ]
                    [ Ui.simpleButton (Just cancel) "Annuler"
                    ]
                , case uploadForm.slides of
                    Just _ ->
                        Element.row [ Element.spacing 10, Element.alignRight ]
                            [ Ui.simpleButton (Just goToPreparation) "Organiser les planches"
                            , Ui.primaryButton (Just goToAcquisition) "Commencer l'enregistrement"
                            ]

                    Nothing ->
                        Element.none
                ]

        form =
            Element.column
                [ Element.spacing 10, Element.width Element.fill ]
                [ projectField, capsuleField, slidesLabel, slides, buttons ]
    in
    Element.row [ Element.width Element.fill, Element.padding 10 ]
        [ Element.el [ Element.width (Element.fillPortion 1) ] Element.none
        , Element.el [ Element.width (Element.fillPortion 8) ] form
        , Element.el [ Element.width (Element.fillPortion 1) ] Element.none
        ]



--Element.column
--    [ Element.width
--        Element.fill
--    ]
--    [ Element.row
--        [ Element.spacing 20
--        , Element.padding 20
--        , Element.width Element.fill
--        ]
--        [ Element.el
--            [ Element.width Element.fill
--            ]
--          <|
--            uploadFormView uploadForm
--        , Element.el
--            [ Element.width Element.shrink
--            ]
--            projects
--        ]
--    ]


leftColumn : Core.Global -> Api.Session -> LoggedIn.UploadForm -> Element Core.Msg
leftColumn global session uploadForm =
    Element.row [ Element.width Element.fill, Element.padding 10 ]
        [ Element.el [ Element.centerX ] (Ui.primaryButton (Just (Core.LoggedInMsg (LoggedIn.UploadSlideShowMsg LoggedIn.UploadSlideShowSelectFileRequested))) "Créer un nouveau projet")
        ]


newCapsuleView : Core.Global -> Api.Capsule -> Element Core.Msg
newCapsuleView global capsule =
    Input.button []
        { onPress = Just (Core.LoggedInMsg (LoggedIn.CapsuleClicked capsule))
        , label = Element.text capsule.name
        }


newProjectView : Core.Global -> ( Api.Project, Bool ) -> Element Core.Msg
newProjectView global ( project, even ) =
    Element.row
        [ Element.padding 10
        , Element.width Element.fill
        , Background.color
            (if even then
                Colors.white

             else
                Colors.whiteDark
            )
        ]
        [ let
            prefix =
                if project.folded then
                    "▷ "

                else
                    "▽ "

            title =
                Input.button []
                    { onPress = Just (Core.LoggedInMsg (LoggedIn.ToggleFoldedProject project.id))
                    , label = Element.text (prefix ++ project.name)
                    }
          in
          if project.folded then
            title

          else
            Element.column
                [ Element.width Element.fill ]
                [ title
                , Element.column
                    [ Element.width Element.fill, Element.paddingXY 20 10, Element.spacing 10 ]
                    (List.map (newCapsuleView global) project.capsules)
                ]
        ]


newProjectsView : Core.Global -> Api.Session -> LoggedIn.UploadForm -> Element Core.Msg
newProjectsView global session uploadForm =
    Element.column [ Element.width (Element.fillPortion 6), Element.alignTop ]
        (List.map (newProjectView global)
            (List.indexedMap (\i x -> ( x, modBy 2 i == 0 ))
                (List.sortBy (\x -> -x.lastVisited) session.projects)
            )
        )


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
                    Ui.errorModal "Echec de l'upoad du pdf. Merci de nous contacter"

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
                [ Element.width (Element.fill |> Element.maximum 500)
                , Font.size 14
                , Font.justify
                ]
                [ Element.el [ Font.bold ] <| Element.text " Pour commencer un enregistrement"
                , Element.text ", il faut choisir une présentation au format PDF sur votre machine. "
                , Element.text "Par exemple un export PDF de Microsoft PowerPoint ou LibreOffice Impress en paysage au format HD. "
                , Element.text "Une fois la présentation téléchargée, l'enregistrement vidéo des planches pourra débuter. "
                ]
            , Element.paragraph
                [ Element.width (Element.fill |> Element.maximum 400)
                , Font.size 14
                , Font.justify
                ]
                [ Element.text "Pour "
                , Element.el [ Font.bold ] <| Element.text "modifier des vidéos existantes"
                , Element.text " cliquer sur \"Projets\". "
                ]
            , message
            , selectFileButton
            ]
        ]


selectFileButton : Element Core.Msg
selectFileButton =
    Element.map Core.LoggedInMsg <|
        Element.map LoggedIn.UploadSlideShowMsg <|
            Ui.primaryButton (Just LoggedIn.UploadSlideShowSelectFileRequested) "Choisir un fichier PDF"


projectsView : Core.Global -> List Api.Project -> Element Core.Msg
projectsView global projects =
    case projects of
        [] ->
            Element.paragraph [ Element.padding 10, Font.size 18 ]
                [ Element.text "You have no projects yet. "
                , if global.beta then
                    Ui.linkButton
                        (Just Core.NewProjectClicked)
                        "Click here to create a new project!"

                  else
                    Element.none
                ]

        _ ->
            let
                sortedProjects =
                    List.sortBy (\x -> -x.lastVisited) projects
            in
            Element.column [ Element.padding 10 ]
                [ Element.el [ Font.size 18 ] (Element.text "Vos projets:")
                , Element.column [ Element.padding 10, Element.spacing 10 ]
                    (List.map (projectHeader global) sortedProjects)
                , if global.beta then
                    newProjectButton

                  else
                    Element.none
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
          <|
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


projectView : Core.Global -> Api.Project -> Maybe NewCapsule.Model -> Element Core.Msg
projectView global project newCapsuleModel =
    let
        headers =
            headerView [] <| Element.text (" Projet " ++ project.name)

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
                [ Element.el [ Element.alignLeft ] <|
                    if global.beta then
                        newCapsuleButton project

                    else
                        Element.none
                , Element.el [] <| Element.text "Capsule(s) du projet:"
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
          <|
            capsule.name
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


regroupSlidesAux : Int -> List (List ( Int, ( Int, Api.Slide ) )) -> List ( Int, ( Int, Api.Slide ) ) -> List (List ( Int, ( Int, Api.Slide ) ))
regroupSlidesAux number current list =
    case ( list, current ) of
        ( [], _ ) ->
            current

        ( h :: t, [] ) ->
            regroupSlidesAux number [ [ h ] ] t

        ( h :: t, h2 :: t2 ) ->
            if List.length h2 < number then
                regroupSlidesAux number ((h2 ++ [ h ]) :: t2) t

            else
                regroupSlidesAux number ([ h ] :: h2 :: t2) t


regroupSlides : Int -> List ( Int, ( Int, Api.Slide ) ) -> List (List (Maybe ( Int, ( Int, Api.Slide ) )))
regroupSlides number list =
    case regroupSlidesAux number [] list of
        [] ->
            []

        h :: t ->
            List.reverse ((List.map Just h ++ List.repeat (number - List.length h) Nothing) :: List.map (\x -> List.map Just x) t)


dropdownConfig : Dropdown.Config Api.Project Core.Msg
dropdownConfig =
    let
        containerAttrs =
            [ Element.width Element.fill ]

        selectAttrs =
            [ Border.width 1
            , Border.rounded 5
            , Element.paddingXY 16 8
            , Element.spacing 10
            , Element.width Element.fill
            ]

        searchAttrs =
            [ Border.width 0, Element.padding 0, Element.width Element.fill ]

        listAttrs =
            [ Border.width 1
            , Border.roundEach { topLeft = 0, topRight = 0, bottomLeft = 5, bottomRight = 5 }
            , Element.width Element.fill
            , Element.clip
            , Element.scrollbarY
            , Element.height (Element.fill |> Element.maximum 200)
            ]

        itemToPrompt item =
            Element.text item.name

        itemToElement selected highlighted i =
            let
                bgColor =
                    if highlighted then
                        Element.rgb255 128 128 128

                    else if selected then
                        Element.rgb255 100 100 100

                    else
                        Element.rgb255 255 255 255
            in
            Element.row
                [ Background.color bgColor
                , Element.padding 8
                , Element.spacing 10
                , Element.width Element.fill
                ]
                [ Element.el [] (Element.text "-")
                , Element.el [ Font.size 16 ] (Element.text i.name)
                ]
    in
    Dropdown.filterable
        (\x -> Core.LoggedInMsg (LoggedIn.DropdownMsg x))
        (\x -> Core.LoggedInMsg (LoggedIn.OptionPicked x))
        itemToPrompt
        itemToElement
        .name
        |> Dropdown.withContainerAttributes containerAttrs
        |> Dropdown.withSelectAttributes selectAttrs
        |> Dropdown.withListAttributes listAttrs
        |> Dropdown.withSearchAttributes searchAttrs
        |> Dropdown.withFilterPlaceholder "Entrez un nom de projet"
        |> Dropdown.withPromptElement (Element.el [ Element.width Element.fill ] (Element.text "Choisir un projet"))


getColor : Int -> Element.Color
getColor index =
    let
        colors =
            [ Element.rgb255 31 119 180
            , Element.rgb255 255 127 14
            , Element.rgb255 44 160 44
            , Element.rgb255 215 39 40
            , Element.rgb255 148 103 189
            , Element.rgb255 140 86 75
            , Element.rgb255 227 119 194
            , Element.rgb255 127 127 127
            , Element.rgb255 188 189 34
            , Element.rgb255 23 190 207
            ]

        newIndex =
            modBy (List.length colors) index
    in
    Maybe.withDefault (Element.rgb255 31 119 180) (List.head (List.drop newIndex colors))
