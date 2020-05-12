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
        mainPage =
            case preparationModel of
                Preparation.Home ->
                    homeView global session

                Preparation.NewProject newProjectModel ->
                    NewProject.view newProjectModel

                Preparation.NewCapsule _ newProjectModel ->
                    NewCapsule.view newProjectModel

                Preparation.Project project ->
                    projectView project

                Preparation.Capsule capsule ->
                    Capsule.view session capsule

        element =
            Element.column
                [ Element.alignTop
                , Element.padding 10
                , Element.width Element.fill
                , Element.scrollbarX
                ]
                [ mainPage ]
    in
    Element.row
        [ Element.height Element.fill
        , Element.width Element.fill
        , Element.spacing 20
        ]
        [ element ]


homeView : Core.Global -> Api.Session -> Element Core.Msg
homeView global session =
    Element.column []
        [ Element.el [] <|
            Element.text "Preparation tab"
        , projectsView
            global
            session.projects
        ]


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
                [ Element.el [ Font.size 18 ] (Element.text "Your projects:")
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


projectView : Api.Project -> Element Core.Msg
projectView project =
    Element.column [ Element.padding 10 ]
        [ Element.el [ Font.size 18 ] (Element.text ("Capsules for project " ++ project.name))
        , Element.column [ Element.padding 10, Element.spacing 10 ]
            (List.map capsuleView project.capsules)
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
