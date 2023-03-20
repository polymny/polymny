module Home.Views exposing (view)

{-| This module contains the home view of the polymny application.

@docs view

-}

import App.Types as App
import Config exposing (Config, Msg(..))
import Data.Capsule as Data
import Data.Types as Data
import Data.User as Data exposing (User)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input
import Home.Types as Home
import Html.Attributes exposing (style)
import Lang exposing (Lang)
import Material.Icons as Icons
import Route
import Simple.Animation as Animation exposing (Animation)
import Simple.Animation.Animated as Animated
import Simple.Animation.Property as P
import Simple.Transition as Transition
import Strings
import Svg
import Svg.Attributes exposing (in_)
import Time
import TimeUtils
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Utils as Ui
import Utils


{-| This function returns the view of the home page.
-}
view : Config -> User -> Home.Model -> ( Element App.Msg, Element App.Msg )
view config user model =
    let
        lang =
            config.clientState.lang

        -- Helper to create popup
        popup : Element App.Msg
        popup =
            case model.popupType of
                Just pt ->
                    case pt of
                        Home.DeleteCapsulePopup c ->
                            let
                                isOwner =
                                    c.role == Data.Owner
                            in
                            if isOwner then
                                deleteCapsuleConfirmPopup lang c

                            else
                                leaveCapsuleConfirmPopup lang c

                        Home.RenameCapsulePopup c ->
                            renameCapsulePopup lang c

                        Home.DeleteProjectPopup p ->
                            deleteProjectConfirmPopup lang p

                        Home.RenameProjectPopup p ->
                            renameProjectPopup lang p

                _ ->
                    Element.none
    in
    ( Element.row [ Ui.wf, Ui.hf ]
        [ Element.el [ Ui.wfp 1, Ui.hf ] (leftColumn config user)
        , Element.el [ Ui.wfp 6, Ui.p 10, Element.alignTop ] (table config user)
        ]
    , popup
    )


{-| This function returns the left colum view.

It contains the button to start a new capsule, but also gives information about users quota.

-}
leftColumn : Config -> User -> Element App.Msg
leftColumn config _ =
    let
        uploadSlidesButton =
            Ui.primary [ Ui.wf ]
                { label = Element.text <| Strings.stepsPreparationSelectPdf config.clientState.lang
                , action = Ui.Msg <| App.HomeMsg <| Home.SlideUploadClicked Nothing
                }
    in
    Element.column
        [ Ui.hf
        , Ui.wf
        , Ui.br 1
        , Element.padding 10
        , Border.color (Colors.grey 6)
        ]
        [ uploadSlidesButton ]


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

        zone =
            config.clientState.zone

        data =
            projectsToPoc user.projects

        len =
            List.length data

        roundBottomLeft =
            Border.roundEach
                { bottomLeft = 20
                , bottomRight = 0
                , topLeft = 0
                , topRight = 0
                }

        roundBottomRight =
            Border.roundEach
                { bottomLeft = 0
                , bottomRight = 20
                , topLeft = 0
                , topRight = 0
                }

        sortByName =
            Just Data.Name

        sortLastModified =
            Just Data.LastModified
    in
    Element.indexedTable [ Ui.wf, Ui.b 1, Border.color Colors.greyBorder, Border.rounded 20 ]
        { data = data
        , columns =
            [ { header = makeHeader (Strings.dataProjectProjectName lang) config sortByName
              , width = Element.fill
              , view = \i x -> makeCell (Utils.tern (i == len - 1) [ roundBottomLeft ] []) i (name x)
              }
            , { header = makeHeader (Strings.dataCapsuleProgress lang) config Nothing
              , width = Element.shrink
              , view = \i x -> makeCell [] i (progress lang x)
              }
            , { header = makeHeader "" config Nothing
              , width = Element.fill
              , view = \i x -> makeCell [] i (progressIcons config x)
              }
            , { header = makeHeader (Strings.dataCapsuleRoleRole lang) config Nothing
              , width = Element.shrink
              , view = \i x -> makeCell [] i (role lang x)
              }
            , { header = makeHeader (Strings.dataCapsuleLastModification lang) config sortLastModified
              , width = Element.shrink
              , view = \i x -> makeCell [] i (lastModified lang zone x)
              }
            , { header = makeHeader (Strings.dataCapsuleAction lang 3) config Nothing
              , width = Element.shrink
              , view = \i x -> makeCell (Utils.tern (i == len - 1) [ roundBottomRight ] []) i (actions lang x user)
              }
            ]
        }


{-| This functions transforms a text into a header element.
-}
makeHeader : String -> Config -> Maybe Data.SortKey -> Element App.Msg
makeHeader text config key =
    let
        curKey =
            config.clientConfig.sortBy.key

        curAscending =
            config.clientConfig.sortBy.ascending

        action =
            case key of
                Just k ->
                    Ui.Msg <|
                        App.ConfigMsg <|
                            Config.SortByChanged <|
                                { key = k
                                , ascending =
                                    if curKey == k then
                                        not curAscending

                                    else
                                        curAscending
                                }

                Nothing ->
                    Ui.Msg App.Noop

        icon =
            case key of
                Just k ->
                    if curKey == k then
                        Ui.icon 24 (Utils.tern curAscending Icons.arrow_drop_down Icons.arrow_drop_up)

                    else
                        Ui.icon 24 Icons.arrow_right

                Nothing ->
                    Element.el [ Ui.h 24 ] Element.none
    in
    Ui.navigationElement action [] <|
        Element.row [ Ui.p 10, Font.bold ]
            [ Element.el [] icon
            , Element.text text
            ]


{-| This functions transforms an element into a table cell.
-}
makeCell : List (Element.Attribute App.Msg) -> Int -> Element App.Msg -> Element App.Msg
makeCell extraAttr index element =
    Element.el
        (Ui.p 10
            :: Ui.hf
            :: (Background.color <| Utils.tern (modBy 2 index == 0) Colors.tableBackground Colors.greyBackground)
            :: extraAttr
        )
        (Element.el [ Ui.wf, Ui.cy ] element)


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
            let
                action =
                    Ui.Msg (App.HomeMsg (Home.Toggle p))
            in
            Ui.navigationElement action
                (Ui.addLinkAttr [ Ui.p 10, Font.bold ])
                (Element.row [ Ui.wf, Ui.hf, Ui.cy ]
                    [ Utils.tern p.folded (Ui.icon 22 Icons.expand_more) (Ui.icon 22 Icons.expand_less)
                    , Element.text p.name
                    ]
                )

        Capsule c ->
            Ui.link [ Ui.pl 30 ] { action = Ui.Route (Route.Preparation c.id), label = Ui.shrink 50 c.name }


{-| This functions returns the actions that can be done on a capsule.
-}
actions : Lang -> Poc -> User -> Element App.Msg
actions lang poc _ =
    case poc of
        Project p ->
            let
                isWriter =
                    List.any (\c -> c.role == Data.Write || c.role == Data.Owner) p.capsules
            in
            Element.row [ Ui.wf, Ui.hf, Ui.cy, Ui.s 5 ]
                [ Ui.secondaryIcon []
                    { icon = Icons.add
                    , tooltip = Strings.actionsAddCapsule lang
                    , action = Ui.Msg <| App.HomeMsg <| Home.SlideUploadClicked <| Just p.name
                    }
                , if isWriter then
                    Ui.secondaryIcon []
                        { icon = Icons.drive_file_rename_outline
                        , tooltip = Strings.actionsRenameProject lang
                        , action =
                            if isWriter then
                                Ui.Msg (App.HomeMsg (Home.RenameProject Utils.Request p))

                            else
                                Ui.None
                        }

                  else
                    Element.none
                , Ui.secondaryIcon []
                    { icon = Icons.delete
                    , tooltip = Strings.actionsDeleteProject lang
                    , action = Ui.Msg (App.HomeMsg (Home.DeleteProject Utils.Request p))
                    }
                ]

        Capsule c ->
            let
                isOwner =
                    c.role == Data.Owner

                isWriter =
                    c.role == Data.Write || isOwner
            in
            Element.row [ Ui.wf, Ui.hf, Ui.cy, Ui.s 5 ] <|
                [ Ui.secondaryIcon []
                    { icon = Icons.ios_share
                    , tooltip = Strings.actionsExportCapsule lang
                    , action = Ui.Msg <| App.HomeMsg <| Home.ExportCapsule c
                    }
                , if isWriter then
                    Ui.secondaryIcon []
                        { icon = Icons.drive_file_rename_outline
                        , tooltip = Strings.actionsRenameCapsule lang
                        , action =
                            if isWriter then
                                Ui.Msg (App.HomeMsg (Home.RenameCapsule Utils.Request c))

                            else
                                Ui.None
                        }

                  else
                    Element.none
                , Ui.secondaryIcon []
                    { icon =
                        if isOwner then
                            Icons.delete

                        else
                            Icons.logout
                    , tooltip =
                        if isOwner then
                            Strings.actionsDeleteCapsule lang

                        else
                            Strings.actionsLeaveCapsule lang
                    , action = Ui.Msg <| App.HomeMsg <| Home.DeleteCapsule Utils.Request c
                    }
                ]


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
    Element.el [ Font.bold, Font.italic ] (Element.text text)


{-| This function returns the progress of a capsule.

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
                (makeText (Strings.stepsAcquisitionAcquisition lang))

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
            Utils.tern (capsule.duration /= 0) (Just capsule.duration) Nothing
                |> Maybe.map TimeUtils.formatDuration
                |> Maybe.map Element.text
                |> Maybe.map (Element.el [ Ui.p 10 ])
                |> Maybe.withDefault Element.none

        pad =
            5

        length =
            75

        totalLength =
            4 * (length + 2 * pad)

        height =
            15

        size =
            26

        startAnimation : Animation
        startAnimation =
            Animation.steps
                { startAt = [ P.x -length ]
                , options = []
                }
                [ Animation.step 200
                    [ P.x <|
                        if not acquired then
                            -(length / 2)

                        else
                            0
                    ]
                ]

        acquisitionAnimation : Animation
        acquisitionAnimation =
            Animation.steps
                { startAt = [ P.x -length ]
                , options = []
                }
                [ Animation.wait 400
                , Animation.step 200
                    [ P.x <|
                        case ( acquired, capsule.produced ) of
                            ( False, _ ) ->
                                -length

                            ( True, Data.Idle ) ->
                                -length / 2

                            _ ->
                                0
                    ]
                ]

        productionAnimation : Animation
        productionAnimation =
            Animation.steps
                { startAt = [ P.x -length ]
                , options = []
                }
                [ Animation.wait 800
                , Animation.step 200
                    [ P.x <|
                        case ( capsule.produced, capsule.published ) of
                            ( Data.Done, Data.Idle ) ->
                                -length / 2

                            ( Data.Done, Data.Done ) ->
                                0

                            _ ->
                                -length
                    ]
                ]

        publicationAnimation : Animation
        publicationAnimation =
            Animation.steps
                { startAt = [ P.x -length ]
                , options = []
                }
                [ Animation.wait 1200
                , Animation.step 200
                    [ P.x <|
                        case capsule.published of
                            Data.Done ->
                                0

                            _ ->
                                -length
                    ]
                ]

        animationAcquisitionDot : Animation
        animationAcquisitionDot =
            Animation.steps
                { startAt = [ P.scale 0.0 ]
                , options = []
                }
                [ Animation.wait 200
                , Animation.step 150 [ P.scale 1.5 ]
                , Animation.step 50 [ P.scale 1.0 ]
                ]

        acquisitionDot : Element App.Msg
        acquisitionDot =
            Element.el
                [ Ui.wpx size
                , Ui.hpx size
                , Ui.r size
                , Ui.p (pad - 2)
                , Background.color <| Colors.grey 6
                , Element.moveLeft (size / 2 + 3 * totalLength / 4)
                , Border.shadow
                    { size = 1
                    , blur = 8
                    , color = Colors.alpha 0.1
                    , offset = ( 0, 0 )
                    }
                ]
            <|
                if acquired then
                    Animated.ui
                        { behindContent = Element.behindContent
                        , htmlAttribute = Element.htmlAttribute
                        , html = Element.html
                        }
                        (\attr el -> Element.el attr el)
                        animationAcquisitionDot
                        [ Ui.wf
                        , Ui.hf
                        , Ui.r size
                        , Ui.p pad
                        , Ui.cx
                        , Ui.cy
                        , Background.color Colors.green2
                        ]
                    <|
                        Element.el
                            [ Ui.wf
                            , Ui.hf
                            , Ui.r size
                            , Ui.cx
                            , Ui.cy
                            , Background.color <| Colors.grey 6
                            ]
                            Element.none

                else
                    Element.none

        animationProductionDot : Animation
        animationProductionDot =
            Animation.steps
                { startAt = [ P.scale 0.0 ]
                , options = []
                }
                [ Animation.wait 600
                , Animation.step 150 [ P.scale 1.5 ]
                , Animation.step 50 [ P.scale 1.0 ]
                ]

        productionDot : Element App.Msg
        productionDot =
            let
                p : Float
                p =
                    case capsule.produced of
                        Data.Idle ->
                            0

                        Data.Running (Just pp) ->
                            pp

                        Data.Done ->
                            1

                        _ ->
                            0
            in
            Element.el
                [ Ui.wpx size
                , Ui.hpx size
                , Ui.r size
                , Ui.p (pad - 2)
                , Background.color <| Colors.grey 6
                , Element.moveLeft (3 * size / 2 + totalLength / 2)
                , Border.shadow
                    { size = 1
                    , blur = 8
                    , color = Colors.alpha 0.1
                    , offset = ( 0, 0 )
                    }
                ]
            <|
                Animated.ui
                    { behindContent = Element.behindContent
                    , htmlAttribute = Element.htmlAttribute
                    , html = Element.html
                    }
                    (\attr el -> Element.el attr el)
                    animationProductionDot
                    []
                <|
                    circleProgress (size / 2 - (pad - 2) - pad / 2) pad p

        animationPublicationDot : Animation
        animationPublicationDot =
            Animation.steps
                { startAt = [ P.scale 0.0 ]
                , options = []
                }
                [ Animation.wait 1000
                , Animation.step 150 [ P.scale 1.5 ]
                , Animation.step 50 [ P.scale 1.0 ]
                ]

        publicationDot : Element App.Msg
        publicationDot =
            Element.el
                [ Ui.wpx size
                , Ui.hpx size
                , Ui.r size
                , Ui.p (pad - 2)
                , Background.color <| Colors.grey 6
                , Element.moveLeft (5 * size / 2 + 1 * totalLength / 4)
                , Border.shadow
                    { size = 1
                    , blur = 8
                    , color = Colors.alpha 0.1
                    , offset = ( 0, 0 )
                    }
                ]
            <|
                if capsule.published == Data.Done then
                    Animated.ui
                        { behindContent = Element.behindContent
                        , htmlAttribute = Element.htmlAttribute
                        , html = Element.html
                        }
                        (\attr el -> Element.el attr el)
                        animationPublicationDot
                        [ Ui.wf
                        , Ui.hf
                        , Ui.r size
                        , Ui.p pad
                        , Ui.cx
                        , Ui.cy
                        , Background.color Colors.green2
                        ]
                    <|
                        Element.el
                            [ Ui.wf
                            , Ui.hf
                            , Ui.r size
                            , Ui.cx
                            , Ui.cy
                            , Background.color <| Colors.grey 6
                            ]
                            Element.none

                else
                    Element.none
    in
    Element.row []
        [ Element.row []
            [ progressBar [ Ui.wpx (length + 2 * pad), Ui.hpx height, Ui.p pad ] startAnimation
            , progressBar [ Ui.wpx (length + 2 * pad), Ui.hpx height, Ui.p pad ] acquisitionAnimation
            , progressBar [ Ui.wpx (length + 2 * pad), Ui.hpx height, Ui.p pad ] productionAnimation
            , progressBar [ Ui.wpx (length + 2 * pad), Ui.hpx height, Ui.p pad ] publicationAnimation
            ]
        , acquisitionDot
        , productionDot
        , publicationDot
        ]


progressBar : List (Element.Attribute App.Msg) -> Animation -> Element App.Msg
progressBar attributes animation =
    Element.el
        ([ Ui.p 5
         , Ui.wpx 100
         , Ui.hpx 20
         , Ui.r 100
         , Ui.ar
         , Background.color <| Colors.grey 6
         , Border.shadow
            { size = 1
            , blur = 8
            , color = Colors.alpha 0.1
            , offset = ( 0, 0 )
            }
         ]
            ++ attributes
        )
    <|
        Element.el
            [ Ui.wf
            , Ui.hf
            , Element.htmlAttribute <| style "overflow" "hidden"
            , Ui.r 100
            ]
        <|
            Animated.ui
                { behindContent = Element.behindContent
                , htmlAttribute = Element.htmlAttribute
                , html = Element.html
                }
                (\attr el -> Element.el attr el)
                animation
                [ Ui.wf, Ui.hf, Ui.r 100, Background.color Colors.green2 ]
                Element.none


circleProgress : Float -> Float -> Float -> Element App.Msg
circleProgress radius width value =
    let
        circumference : Float
        circumference =
            2 * pi * radius
    in
    Element.el [ Ui.cx, Ui.cy ] <|
        Element.html <|
            Svg.svg
                [ Svg.Attributes.width <| String.fromFloat (2 * radius + width)
                , Svg.Attributes.height <| String.fromFloat (2 * radius + width)
                ]
                [ Svg.circle
                    [ Svg.Attributes.cx <| String.fromFloat ((2 * radius + width) / 2)
                    , Svg.Attributes.cy <| String.fromFloat ((2 * radius + width) / 2)
                    , Html.Attributes.style "transition" "0.35s stroke-dashoffset"
                    , Html.Attributes.style "transform" "rotate(90deg)"
                    , Html.Attributes.style "transform-origin" "50% 50%"
                    , Svg.Attributes.r (String.fromFloat radius)
                    , Svg.Attributes.stroke <| Colors.colorToString Colors.green2
                    , Svg.Attributes.strokeWidth (String.fromFloat width)
                    , Svg.Attributes.fill "transparent"
                    , Svg.Attributes.strokeDasharray (String.fromFloat circumference)
                    , (1.0 - value)
                        * circumference
                        |> String.fromFloat
                        |> Svg.Attributes.strokeDashoffset
                    ]
                    []
                ]


{-| The progress icons of a caspule.
-}
progressIcons : Config -> Poc -> Element App.Msg
progressIcons config poc =
    case poc of
        Project _ ->
            Element.none

        Capsule c ->
            let
                lang =
                    config.clientState.lang

                watch : Element App.Msg
                watch =
                    case ( c.published, Data.videoPath c ) of
                        ( Data.Done, _ ) ->
                            Ui.secondaryIcon []
                                { icon = Icons.theaters
                                , action = Ui.Route <| Route.Custom <| config.serverConfig.videoRoot ++ "/" ++ c.id ++ "/"
                                , tooltip = Strings.actionsWatchCapsule lang
                                }

                        ( _, Just url ) ->
                            Ui.secondaryIcon []
                                { icon = Icons.theaters
                                , action = Ui.NewTab url
                                , tooltip = Strings.actionsWatchCapsule lang
                                }

                        _ ->
                            Element.none
            in
            Element.row [ Element.spacing 10 ]
                [ watch ]


{-| This function returns the role of a capsule, or an empty element if a project.
-}
role : Lang -> Poc -> Element App.Msg
role lang poc =
    case poc of
        Project _ ->
            Element.none

        Capsule c ->
            Element.text
                (case c.role of
                    Data.Read ->
                        Strings.dataCapsuleRoleRead lang

                    Data.Write ->
                        Strings.dataCapsuleRoleWrite lang

                    Data.Owner ->
                        Strings.dataCapsuleRoleOwner lang
                )


{-| This function returns the last modified date of a project or a capsule.
-}
lastModified : Lang -> Time.Zone -> Poc -> Element App.Msg
lastModified lang zone poc =
    let
        date =
            case poc of
                Project p ->
                    List.head p.capsules |> Maybe.map .lastModified |> Maybe.withDefault 0

                Capsule c ->
                    c.lastModified
    in
    TimeUtils.formatTime lang zone date |> Element.text


{-| Popup to confirm the capsule deletion.
-}
deleteCapsuleConfirmPopup : Lang -> Data.Capsule -> Element App.Msg
deleteCapsuleConfirmPopup lang capsule =
    Element.column [ Ui.wf, Ui.hf ]
        [ Element.paragraph [ Ui.wf, Ui.cy, Font.center ]
            [ Element.text (Lang.question Strings.actionsConfirmDeleteCapsule lang) ]
        , Element.row [ Ui.ab, Ui.ar, Ui.s 10 ]
            [ Ui.secondary []
                { action = mkUiMsg (Home.DeleteCapsule Utils.Cancel capsule)
                , label = Element.text <| Strings.uiCancel lang
                }
            , Ui.primary []
                { action = mkUiMsg (Home.DeleteCapsule Utils.Confirm capsule)
                , label = Element.text <| Strings.uiConfirm lang
                }
            ]
        ]
        |> Ui.popup 1 (Strings.actionsDeleteCapsule lang)


{-| Popup to confirm leaving a capsule.
-}
leaveCapsuleConfirmPopup : Lang -> Data.Capsule -> Element App.Msg
leaveCapsuleConfirmPopup lang capsule =
    Element.column [ Ui.wf, Ui.hf ]
        [ Element.paragraph [ Ui.wf, Ui.cy, Font.center ]
            [ Element.text (Lang.question Strings.actionsConfirmLeaveCapsule lang) ]
        , Element.row [ Ui.ab, Ui.ar, Ui.s 10 ]
            [ Ui.secondary []
                { action = mkUiMsg (Home.DeleteCapsule Utils.Cancel capsule)
                , label = Element.text <| Strings.uiCancel lang
                }
            , Ui.primary []
                { action = mkUiMsg (Home.DeleteCapsule Utils.Confirm capsule)
                , label = Element.text <| Strings.uiConfirm lang
                }
            ]
        ]
        |> Ui.popup 1 (Strings.actionsLeaveCapsule lang)


{-| Popup to rename a capsule.
-}
renameCapsulePopup : Lang -> Data.Capsule -> Element App.Msg
renameCapsulePopup lang capsule =
    let
        nameInput =
            Element.Input.text
                []
                { onChange = \x -> App.HomeMsg (Home.CapsuleNameChanged capsule x)
                , text = capsule.name
                , placeholder = Nothing
                , label = Element.Input.labelAbove [] (Ui.title (Strings.dataCapsuleCapsuleName lang))
                }
    in
    Element.column [ Ui.wf, Ui.hf, Ui.s 10 ]
        [ nameInput
        , Element.row [ Ui.ab, Ui.ar, Ui.s 10 ]
            [ Ui.secondary []
                { action = mkUiMsg (Home.RenameCapsule Utils.Cancel capsule)
                , label = Element.text <| Strings.uiCancel lang
                }
            , Ui.primary []
                { action = mkUiMsg (Home.RenameCapsule Utils.Confirm capsule)
                , label = Element.text <| Strings.uiConfirm lang
                }
            ]
        ]
        |> Ui.popup 1 (Strings.actionsRenameCapsule lang)


{-| Popup to confirm the project deletion.
-}
deleteProjectConfirmPopup : Lang -> Data.Project -> Element App.Msg
deleteProjectConfirmPopup lang project =
    Element.column [ Ui.wf, Ui.hf, Ui.s 10 ]
        [ Element.paragraph [ Ui.wf, Ui.cy, Font.center ]
            [ Element.text (Lang.warning Strings.uiWarning lang) ]
        , Element.paragraph [ Ui.wf, Ui.cy, Font.center ]
            [ Element.text (Strings.actionsConfirmDeleteProjectWarning lang) ]
        , Element.paragraph [ Ui.wf, Ui.cy, Font.center ]
            [ Element.text (Lang.question Strings.actionsConfirmDeleteProject lang) ]
        , Element.row [ Ui.ab, Ui.ar, Ui.s 10 ]
            [ Ui.secondary []
                { action = mkUiMsg (Home.DeleteProject Utils.Cancel project)
                , label = Element.text <| Strings.uiCancel lang
                }
            , Ui.primary []
                { action = mkUiMsg (Home.DeleteProject Utils.Confirm project)
                , label = Element.text <| Strings.uiConfirm lang
                }
            ]
        ]
        |> Ui.popup 1 (Strings.actionsDeleteProject lang)


{-| Renames a project.
-}
renameProjectPopup : Lang -> Data.Project -> Element App.Msg
renameProjectPopup lang project =
    let
        nameInput =
            Element.Input.text
                []
                { onChange = \x -> App.HomeMsg (Home.ProjectNameChanged project x)
                , text = project.name
                , placeholder = Nothing
                , label = Element.Input.labelAbove [] (Ui.title (Strings.dataProjectProjectName lang))
                }
    in
    Element.column [ Ui.wf, Ui.hf, Ui.s 10 ]
        [ nameInput
        , Element.paragraph [ Ui.wf, Ui.cy, Font.center ]
            [ Element.text (Lang.warning Strings.uiWarning lang) ]
        , Element.paragraph [ Ui.wf, Ui.cy, Font.center ]
            [ Element.text (Strings.actionsConfirmRenameProjectWarning lang) ]
        , Element.row [ Ui.ab, Ui.ar, Ui.s 10 ]
            [ Ui.secondary []
                { action = mkUiMsg (Home.RenameProject Utils.Cancel project)
                , label = Element.text <| Strings.uiCancel lang
                }
            , Ui.primary []
                { action = mkUiMsg (Home.RenameProject Utils.Confirm project)
                , label = Element.text <| Strings.uiConfirm lang
                }
            ]
        ]
        |> Ui.popup 1 (Strings.actionsRenameProject lang)


{-| Easily creates the Ui.Msg for options msg.
-}
mkUiMsg : Home.Msg -> Ui.Action App.Msg
mkUiMsg msg =
    mkMsg msg |> Ui.Msg


{-| Easily creates a options msg.
-}
mkMsg : Home.Msg -> App.Msg
mkMsg msg =
    App.HomeMsg msg
