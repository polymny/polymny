module Home.Views exposing (view)

{-| This module contains the home view of the polymny application.

@docs view

-}

import App.Types as App
import Config exposing (Config)
import Data.Capsule as Data
import Data.Types as Data
import Data.User as Data exposing (User)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Home.Types as Home
import Lang exposing (Lang)
import Route
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Utils as Ui
import Utils


{-| This function returns the view of the home page.
-}
view : Config -> User -> Element App.Msg
view config user =
    Element.row [ Ui.wf, Ui.p 10 ]
        [ Element.el [ Ui.wfp 2 ] Element.none
        , Element.el [ Ui.wfp 8 ] (table config user)
        , Element.el [ Ui.wfp 2 ] Element.none
        ]


{-| This type can be a project or a capsule.

It represents a line in the table.

-}
type Poc
    = Project Data.Project
    | Capsule Data.Capsule


{-| This function returns the table of the projects and capsules of the user.
-}
table : Config -> User -> Element App.Msg
table config user =
    let
        lang =
            config.clientState.lang
    in
    Element.table [ Ui.wf, Ui.b 1, Border.color Colors.greyBorder, Border.rounded 20 ]
        { data = projectsToPoc user.projects
        , columns =
            [ { header = makeHeader (Strings.dataProjectProjectName lang)
              , width = Element.fill
              , view = \x -> makeCell (name x)
              }
            , { header = makeHeader (Strings.dataCapsuleProgress lang)
              , width = Element.shrink
              , view = \x -> makeCell (progress config.clientState.lang x)
              }
            , { header = makeHeader ""
              , width = Element.fill
              , view = \x -> Element.none
              }
            , { header = makeHeader (Strings.dataCapsuleRoleRole lang)
              , width = Element.shrink
              , view = \x -> Element.none
              }
            , { header = makeHeader "TODO"
              , width = Element.shrink
              , view = \x -> Element.none
              }
            , { header = makeHeader (Strings.dataCapsuleAction lang 3)
              , width = Element.shrink
              , view = \x -> Element.none
              }
            ]
        }


{-| This functions transforms a text into a header element.
-}
makeHeader : String -> Element App.Msg
makeHeader text =
    Element.el [ Ui.p 10, Font.bold ] (Element.text text)


{-| This functions transforms an element into a table cell.
-}
makeCell : Element App.Msg -> Element App.Msg
makeCell element =
    Element.el [ Ui.p 10, Ui.cy ] element


{-| This functions transforms a list of projects into a list of Poc that can be given as data in the table.
-}
projectsToPoc : List Data.Project -> List Poc
projectsToPoc projects =
    let
        mapper : Data.Project -> List Poc
        mapper project =
            if project.folded then
                [ Project project ]

            else
                Project project :: List.map Capsule project.capsules
    in
    List.concatMap mapper projects


{-| This functions returns the name of the project or capsule.
-}
name : Poc -> Element App.Msg
name poc =
    case poc of
        Project p ->
            Ui.link [] { action = Ui.Msg (App.HomeMsg (Home.Toggle p)), label = Utils.tern p.folded "▷ " "▽ " ++ p.name }

        Capsule c ->
            Ui.link [ Ui.pl 30 ] { action = Ui.Route (Route.Preparation c.id), label = Ui.shrink 50 c.name }


{-| This functions returns the progress bar of the capsule.

It indicates at which step the user is in the production of their capsule.

-}
progress : Lang -> Poc -> Element App.Msg
progress lang poc =
    case poc of
        Project p ->
            projectProgress lang p

        Capsule c ->
            capsuleProgress lang c


{-| This functions returns a string that describes the progress of a project, i.e. how many capsules are in the project,
produced, and published.
-}
projectProgress : Lang -> Data.Project -> Element App.Msg
projectProgress lang project =
    let
        capsuleCount =
            List.length project.capsules

        producedCount =
            project.capsules |> List.filter (\x -> x.produced /= Data.Idle) |> List.length

        publishedCount =
            project.capsules |> List.filter (\x -> x.published /= Data.Idle) |> List.length

        text =
            "("
                ++ String.fromInt capsuleCount
                ++ " "
                ++ (Strings.dataCapsuleCapsule lang capsuleCount |> String.toLower)
                ++ ", "
                ++ String.fromInt producedCount
                ++ " "
                ++ (Strings.dataCapsuleProduced lang producedCount |> String.toLower)
                ++ ", "
                ++ String.fromInt publishedCount
                ++ " "
                ++ (Strings.dataCapsulePublished lang publishedCount |> String.toLower)
                ++ ")"
    in
    Element.el [ Font.italic ] (Element.text text)


{-| This function returns th progress of a capsule.

It is a kind of progress bar that shows the different steps between acquisition, production and publication.

-}
capsuleProgress : Lang -> Data.Capsule -> Element App.Msg
capsuleProgress lang capsule =
    let
        computeColor : Data.TaskStatus -> Element.Attribute msg
        computeColor status =
            Background.color <|
                case status of
                    Data.Idle ->
                        Colors.greyBackground

                    _ ->
                        Colors.green2

        makeText : String -> Element msg
        makeText text =
            Element.el [ Element.centerX, Element.centerY ] (Element.text text)

        acquired =
            capsule.structure
                |> List.filterMap .record
                |> List.isEmpty
                |> not
                |> (||) (capsule.produced /= Data.Idle)

        acquisition =
            Element.el
                [ Ui.wf
                , Ui.p 10
                , computeColor (Utils.tern acquired Data.Done Data.Idle)
                , Border.roundEach { topLeft = 10, bottomLeft = 10, topRight = 0, bottomRight = 0 }
                , Border.color Colors.black
                , Border.widthEach { left = 1, top = 1, right = 0, bottom = 1 }
                ]
                (makeText (Strings.stepsAcqusitionAcquisition lang))

        production =
            Element.el
                [ Ui.wf
                , Ui.p 10
                , computeColor capsule.produced
                , Border.color Colors.black
                , Border.widthEach { left = 1, top = 1, right = 0, bottom = 1 }
                ]
                (makeText (Strings.stepsProductionProduction lang))

        publication =
            Element.el
                [ Ui.wf
                , computeColor capsule.published
                , Ui.p 10
                , Border.roundEach { topLeft = 0, bottomLeft = 0, topRight = 10, bottomRight = 10 }
                , Border.color Colors.black
                , Border.width 1
                ]
                (makeText (Strings.stepsPublicationPublication lang))

        duration =
            Element.el [ Ui.p 10 ] <| Element.text <| Ui.formatDuration capsule.duration
    in
    Element.row [ Ui.hf, Ui.wf, Element.centerY ]
        [ acquisition, production, publication, duration ]
