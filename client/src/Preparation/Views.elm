module Preparation.Views exposing (view)

import Api
import Capsule.Views as Capsule
import Core.Types as Core
import Element exposing (Element)
import Element.Font as Font
import LoggedIn.Types as LoggedIn
import NewCapsule.Views as NewCapsule
import NewProject.Views as NewProject
import Preparation.Types as Preparation
import TimeUtils
import Ui.Ui as Ui


view : Core.Global -> Api.Session -> Preparation.Model -> Element Core.Msg
view global session preparationModel =
    let
        preparationClickedMsg =
            Just <|
                Core.LoggedInMsg <|
                    LoggedIn.PreparationMsg <|
                        Preparation.PreparationClicked

        clicktab =
            headerView [] <| Ui.linkButton preparationClickedMsg "Préparation"

        mainPage =
            case preparationModel of
                Preparation.Home ->
                    homeView global session

                Preparation.NewProject newProjectModel ->
                    NewProject.view newProjectModel

                Preparation.NewCapsule _ newProjectModel ->
                    NewCapsule.view newProjectModel

                Preparation.Project project ->
                    projectView project clicktab

                Preparation.Capsule capsule ->
                    Capsule.view session capsule clicktab

        element =
            Element.column
                [ Element.alignTop
                , Element.padding 10
                , Element.width Element.fill
                , Element.scrollbarX
                ]
                [ mainPage
                ]
    in
    Element.row
        [ Element.height Element.fill
        , Element.width Element.fill
        , Element.spacing 20
        ]
        [ element ]


newProjectButton : Element Core.Msg
newProjectButton =
    Ui.primaryButton (Just Core.NewProjectClicked) "New project"


homeView : Core.Global -> Api.Session -> Element Core.Msg
homeView global session =
    Element.column []
        [ projectsView global session.projects
        ]


headerView : List (Element Core.Msg) -> Element Core.Msg -> List (Element Core.Msg)
headerView header el =
    case List.length header of
        0 ->
            [ el ]

        _ ->
            header ++ [ el ]


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
                [ newProjectButton
                , Element.el [ Font.size 18 ] (Element.text "Your projects:")
                , Element.column [ Element.padding 10, Element.spacing 10 ]
                    (List.map (projectHeader global) sortedProjects)
                ]


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


newCapsuleButton : Api.Project -> Element Core.Msg
newCapsuleButton project =
    Ui.primaryButton (Just (Core.NewCapsuleClicked project)) "New capsule"


projectView : Api.Project -> List (Element Core.Msg) -> Element Core.Msg
projectView project header =
    let
        headers =
            headerView header <| Element.text (" / " ++ project.name)
    in
    Element.column []
        [ Element.row [ Font.size 18 ] <| headers
        , Element.column [ Element.padding 10 ]
            [ newCapsuleButton project
            , Element.column [ Element.padding 10, Element.spacing 10 ]
                (List.map capsuleView project.capsules)
            ]
        ]


capsuleView : Api.Capsule -> Element Core.Msg
capsuleView capsule =
    Element.column [ Element.spacing 10 ]
        [ Ui.linkButton
            (Just
                (Core.LoggedInMsg <|
                    LoggedIn.PreparationMsg <|
                        Preparation.CapsuleClicked capsule
                )
            )
            capsule.name
        , Element.text capsule.title
        , Element.text capsule.description
        ]
