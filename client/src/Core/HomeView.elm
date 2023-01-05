module Core.HomeView exposing (..)

import Capsule exposing (Capsule)
import Core.Types as Core
import Core.Utils as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import FontAwesome as Fa
import Html
import Html.Attributes
import Html.Events
import Lang
import Route
import TimeUtils
import Ui.Colors as Colors
import Ui.Utils as Ui
import User exposing (User)
import Utils exposing (formatTime, tern)


type ProjectOrCapsule
    = Project User.Project
    | Capsule Capsule.Capsule


view : Core.Global -> User -> Core.HomeModel -> (String -> Core.Msg) -> ( Element Core.Msg, Maybe (Element Core.Msg) )
view global user model mkToggleFold =
    if List.isEmpty user.projects then
        ( Element.row [ Ui.wf, Ui.hf, Element.padding 10 ]
            [ Element.el [ Ui.wf ] Element.none
            , Element.column [ Ui.wf, Ui.hf, Element.spacing 20 ]
                [ Element.el [ Font.size 24, Font.bold, Element.centerX ] (Element.text (Lang.welcomeOnPolymny global.lang))
                , Element.text (Lang.noProjectsYet global.lang)
                , Element.paragraph [ Font.justify ]
                    [ Element.el [ Font.bold ] (Element.text (Lang.startRecordSentence global.lang ++ " "))
                    , Element.text (Lang.nextSentence global.lang)
                    ]
                , Element.el [ Element.centerX ] (newCapsulePrimary global)
                ]
            , Element.el [ Ui.wf ] Element.none
            ]
        , Nothing
        )

    else
        let
            elements =
                user.projects
                    |> List.map
                        (\x ->
                            if x.folded then
                                [ Project x ]

                            else
                                Project x :: List.map Capsule x.capsules
                        )
                    |> List.concat

            table =
                Element.table [ Ui.wf ]
                    { data = elements
                    , columns =
                        [ { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.projectName global.lang))
                          , width = Element.fill
                          , view = titleView global mkToggleFold
                          }
                        , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.progress global.lang))
                          , width = Element.shrink
                          , view = progressView global
                          }
                        , { header = Element.el [ Element.padding 10 ] Element.none
                          , width = Element.fill
                          , view = progressIconsView global
                          }
                        , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.role global.lang))
                          , width = Element.shrink
                          , view = roleView global
                          }
                        , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.lastModified global.lang))
                          , width = Element.shrink
                          , view = lastModifiedView global
                          }
                        , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.diskUsage global.lang))
                          , width = Element.shrink
                          , view = diskUsageView global
                          }
                        , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.actions global.lang))
                          , width = Element.shrink
                          , view = actionsView global
                          }
                        ]
                    }

            leftColumn =
                Element.column [ Ui.wf, Element.alignTop, Element.centerX, Element.spacing 30 ]
                    [ Element.el [ Ui.wfp 1, Ui.hf ] Element.none
                    , Element.el [ Element.centerX ] (newCapsulePrimary global)
                    , Ui.diskSpace global.lang (Core.userDiskUsage user) (toFloat user.diskQuota)
                    , Element.el [ Ui.wfp 1, Ui.hf ] Element.none
                    ]

            element =
                Element.row [ Ui.wf, Ui.hf ]
                    [ Element.el [ Ui.wfp 1, Ui.hf ] Element.none
                    , leftColumn
                    , Element.column [ Element.spacing 10, Ui.wfp 6, Ui.hf ]
                        [ Element.el [ Ui.wf ] table
                        , newCapsule global
                        ]
                    , Element.el [ Ui.wfp 1 ] Element.none
                    ]

            popup =
                case model.renameCapsule of
                    Just capsule ->
                        let
                            validate =
                                Ui.primaryButton
                                    { onPress = Just (Core.ValidateRenameCapsule capsule)
                                    , label = Element.text (Lang.confirm global.lang)
                                    }

                            cancel =
                                Ui.simpleButton
                                    { onPress = Just (Core.RenameCapsule Nothing)
                                    , label = Element.text (Lang.cancel global.lang)
                                    }

                            onProjectChange =
                                Html.Events.onInput
                                    (\x ->
                                        Core.RenameCapsule
                                            (Just
                                                { capsule
                                                    | project =
                                                        if x == "__empty" then
                                                            ""

                                                        else
                                                            x
                                                }
                                            )
                                    )

                            projects =
                                (user.projects |> List.map Just) ++ [ Nothing ]

                            projectOption : Maybe User.Project -> Html.Html Core.Msg
                            projectOption project =
                                case project of
                                    Just p ->
                                        Html.option
                                            [ Html.Attributes.selected (capsule.project == p.name)
                                            , Html.Attributes.value p.name
                                            ]
                                            [ Html.text p.name ]

                                    Nothing ->
                                        Html.option
                                            [ Html.Attributes.value "__empty" ]
                                            [ Html.text (Lang.createNewProject global.lang) ]

                            showTextInput =
                                List.all (\x -> capsule.project /= x) (List.map .name user.projects)
                        in
                        Just
                            (Ui.customSizedPopup 1
                                (Lang.renameCapsule global.lang)
                                (Element.column
                                    [ Element.padding 10
                                    , Ui.wf
                                    , Ui.hf
                                    , Element.spacing 20
                                    , Background.color Colors.whiteBis
                                    ]
                                    [ Element.el [ Element.centerY ] (Element.text (Lang.chooseProject global.lang))
                                    , Html.select [ onProjectChange ] (List.map projectOption projects)
                                        |> Element.html
                                        |> Element.el [ Element.centerY ]
                                    , if showTextInput then
                                        Input.text [ Element.centerY ]
                                            { label = Input.labelHidden ""
                                            , onChange = \x -> Core.RenameCapsule (Just { capsule | project = x })
                                            , placeholder = Nothing
                                            , text = capsule.project
                                            }

                                      else
                                        Element.none
                                    , Input.text [ Element.centerY ]
                                        { label = Input.labelAbove [] (Element.text (Lang.enterNewNameForCapsule global.lang))
                                        , onChange = \x -> Core.RenameCapsule (Just { capsule | name = x })
                                        , placeholder = Nothing
                                        , text = capsule.name
                                        }
                                    , Element.row [ Element.alignRight, Element.spacing 10 ] [ cancel, validate ]
                                    ]
                                )
                            )

                    _ ->
                        Nothing
        in
        ( element, popup )


titleView : Core.Global -> (String -> Core.Msg) -> ProjectOrCapsule -> Element Core.Msg
titleView _ mkToggleFold projectOrCapsule =
    let
        text =
            case projectOrCapsule of
                Project project ->
                    Ui.linkButton []
                        { onPress = Just (mkToggleFold project.name)
                        , label = Element.text (tern project.folded "▷ " "▽ " ++ Ui.shrink 50 project.name)
                        }

                Capsule capsule ->
                    Element.el [ Element.paddingXY 20 0 ]
                        (Ui.link []
                            { route = Route.Preparation capsule.id Nothing
                            , label = Element.text <| Ui.shrink 50 capsule.name
                            }
                        )
    in
    Element.el [ Element.padding 10, Element.centerY ] text


progressCapsuleView :
    Core.Global
    -> Capsule
    ->
        { acquisition : Element Core.Msg
        , edition : Element Core.Msg
        , publication : Element Core.Msg
        , duration : Element Core.Msg
        }
progressCapsuleView global capsule =
    let
        computeColor : Capsule.TaskStatus -> Element.Attribute msg
        computeColor status =
            Background.color <|
                case status of
                    Capsule.Idle ->
                        Colors.light

                    _ ->
                        Colors.navbar

        acquired =
            capsule.structure
                |> List.filterMap .record
                |> List.isEmpty
                |> not
                |> (||) (capsule.produced /= Capsule.Idle)

        acquisition =
            Element.el
                [ computeColor (tern acquired Capsule.Done Capsule.Idle)
                , Element.padding 10
                , Border.roundEach { topLeft = 10, bottomLeft = 10, topRight = 0, bottomRight = 0 }
                , Border.color Colors.black
                , Border.widthEach { left = 1, top = 1, right = 0, bottom = 1 }
                ]
                (Element.el [ Element.centerX, Element.centerY ] (Element.text (Lang.acquisition global.lang)))

        edition =
            Element.el
                [ computeColor capsule.produced
                , Element.padding 10
                , Border.color Colors.black
                , Border.widthEach { left = 1, top = 1, right = 0, bottom = 1 }
                ]
                (Element.el [ Element.centerX, Element.centerY ] (Element.text (Lang.production global.lang)))

        publication =
            Element.el
                [ computeColor capsule.published
                , Element.padding 10
                , Border.roundEach { topLeft = 0, bottomLeft = 0, topRight = 10, bottomRight = 10 }
                , Border.color Colors.black
                , Border.width 1
                ]
                (Element.el [ Element.centerX, Element.centerY ] (Element.text (Lang.publication global.lang)))

        duration =
            case capsule.produced of
                Capsule.Done ->
                    Element.el [ Element.padding 10 ] <| Element.text <| formatTime capsule.durationMs

                _ ->
                    Element.el [ Element.padding 10 ] <| Element.text "   "
    in
    { acquisition = acquisition, edition = edition, publication = publication, duration = duration }


progressView : Core.Global -> ProjectOrCapsule -> Element Core.Msg
progressView global projectOrCapsule =
    case projectOrCapsule of
        Project project ->
            let
                capsuleCount =
                    List.length project.capsules

                producedCount =
                    project.capsules |> List.filter (\x -> x.produced /= Capsule.Idle) |> List.length

                publishedCount =
                    project.capsules |> List.filter (\x -> x.published /= Capsule.Idle) |> List.length

                text =
                    "("
                        ++ String.fromInt capsuleCount
                        ++ " "
                        ++ Lang.capsule global.lang capsuleCount
                        ++ ", "
                        ++ String.fromInt producedCount
                        ++ " "
                        ++ Lang.produced global.lang producedCount
                        ++ ", "
                        ++ String.fromInt publishedCount
                        ++ " "
                        ++ Lang.published global.lang publishedCount
                        ++ ")"
            in
            Element.el [ Font.italic, Element.padding 10 ] (Element.text text)

        Capsule capsule ->
            let
                progress =
                    progressCapsuleView global capsule
            in
            Element.row [ Ui.hf, Ui.wf, Element.centerY, Element.padding 5 ]
                [ progress.acquisition, progress.edition, progress.publication, progress.duration ]


progressCapsuleIconsView : Core.Global -> Capsule -> ( Element Core.Msg, Element Core.Msg, Element Core.Msg )
progressCapsuleIconsView global c =
    let
        attr =
            [ Font.color Colors.navbar ]

        watchButton =
            case ( c.published, Capsule.videoPath c ) of
                ( Capsule.Done, _ ) ->
                    Ui.newTabIconLink attr
                        { route = Route.Custom (global.videoRoot ++ "/" ++ c.id ++ "/")
                        , icon = Fa.film
                        , text = Nothing
                        , tooltip = Just (Lang.watchVideo global.lang)
                        }

                ( _, Just url ) ->
                    Ui.newTabIconLink attr
                        { route = Route.Custom url
                        , icon = Fa.film
                        , text = Nothing
                        , tooltip = Just (Lang.watchVideo global.lang)
                        }

                _ ->
                    Element.none

        downloadButton =
            case Capsule.videoPath c of
                Just url ->
                    Ui.downloadIconLink attr
                        { route = Route.Custom url
                        , icon = Fa.download
                        , text = Nothing
                        , tooltip = Just (Lang.downloadVideo global.lang)
                        }

                _ ->
                    Element.none

        copyUrlButton =
            case c.published of
                Capsule.Done ->
                    Ui.iconButton attr
                        { onPress = Core.Copy (global.videoRoot ++ "/" ++ c.id ++ "/") |> Just
                        , icon = Fa.link
                        , text = Nothing
                        , tooltip = Just (Lang.copyVideoUrl global.lang)
                        }

                _ ->
                    Element.none
    in
    ( watchButton, downloadButton, copyUrlButton )


progressIconsView : Core.Global -> ProjectOrCapsule -> Element Core.Msg
progressIconsView global projectOrCapsule =
    case projectOrCapsule of
        Capsule c ->
            let
                ( watchButton, downloadButton, copyUrlButton ) =
                    progressCapsuleIconsView global c
            in
            Element.row [ Element.spacing 10, Element.centerY ]
                [ watchButton, downloadButton, copyUrlButton ]

        _ ->
            Element.none


iconButton : Maybe Core.Msg -> Fa.Icon -> Maybe String -> String -> Element Core.Msg
iconButton onPress icon text tooltip =
    Ui.iconButton [ Font.color Colors.navbar ]
        { onPress = onPress
        , icon = icon
        , text = text
        , tooltip = Just tooltip
        }


actionsView : Core.Global -> ProjectOrCapsule -> Element Core.Msg
actionsView global projectOrCapsule =
    case projectOrCapsule of
        Project project ->
            let
                newCapsuleMsg =
                    Core.SlideUploadRequested (Just project.name) |> Just

                deleteProjectMsg =
                    Core.RequestDeleteProject project.name |> Just
            in
            Element.row [ Element.spacing 10, Element.centerY ]
                [ -- iconButton Nothing Fa.pen Nothing (Lang.renameProject global.lang)
                  iconButton deleteProjectMsg Fa.trash Nothing (Lang.deleteProject global.lang)
                , iconButton newCapsuleMsg Fa.plus Nothing (Lang.newCapsule global.lang)
                ]

        Capsule capsule ->
            let
                renameCapsuleMsg =
                    Core.RenameCapsule (Just capsule) |> Just

                deleteCapsuleMsg =
                    Core.RequestDeleteCapsule capsule.id |> Just

                exportMsg =
                    Core.ExportCapsule capsule |> Just
            in
            Element.row [ Element.spacing 10, Element.centerY ]
                [ iconButton renameCapsuleMsg Fa.pen Nothing (Lang.renameCapsule global.lang)
                , iconButton exportMsg Fa.fileExport Nothing (Lang.exportCapsule global.lang)
                , iconButton deleteCapsuleMsg Fa.trash Nothing (Lang.deleteCapsule global.lang)
                ]


newCapsule : Core.Global -> Element Core.Msg
newCapsule global =
    let
        newCapsuleMsg =
            Core.SlideUploadRequested Nothing |> Just
    in
    Element.el [ Element.paddingXY 10 0 ]
        (iconButton newCapsuleMsg Fa.plus Nothing (Lang.newCapsule global.lang))


newCapsulePrimary : Core.Global -> Element Core.Msg
newCapsulePrimary global =
    let
        newCapsuleMsg =
            Core.SlideUploadRequested Nothing |> Just
    in
    Element.el [ Element.paddingXY 10 0 ]
        (Ui.primaryButton { onPress = newCapsuleMsg, label = Element.text (Lang.selectPdf global.lang) })


roleView : Core.Global -> ProjectOrCapsule -> Element Core.Msg
roleView global projectOrCapsule =
    let
        c =
            case projectOrCapsule of
                Project _ ->
                    Element.none

                Capsule cap ->
                    Element.text (Lang.roleView global.lang cap.role)
    in
    Element.el [ Element.paddingEach { top = 10, bottom = 10, right = 20, left = 0 }, Element.centerY ] c


lastModifiedView : Core.Global -> ProjectOrCapsule -> Element Core.Msg
lastModifiedView global projectOrCapsule =
    let
        date =
            case projectOrCapsule of
                Project p ->
                    List.head p.capsules |> Maybe.map .lastModified |> Maybe.withDefault 0

                Capsule c ->
                    c.lastModified
    in
    TimeUtils.timeToString global.lang global.zone date
        |> Element.text
        |> Element.el [ Element.paddingEach { top = 10, bottom = 10, right = 20, left = 0 }, Element.centerY ]


diskUsageView : Core.Global -> ProjectOrCapsule -> Element Core.Msg
diskUsageView global projectOrCapsule =
    let
        diskUsage =
            case projectOrCapsule of
                Project p ->
                    List.head p.capsules |> Maybe.map .diskUsage |> Maybe.withDefault 0

                Capsule c ->
                    c.diskUsage
    in
    Element.el [ Element.padding 10, Element.centerY ] <| Element.text <| (String.fromInt diskUsage ++ " Mo")
