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
import Html.Attributes
import Html.Events
import LoggedIn.Types as LoggedIn
import Preparation.Types as Preparation
import Preparation.Views as Preparation
import Settings.Views as Settings
import Status
import TimeUtils
import Ui.Colors as Colors
import Ui.Ui as Ui


view : Core.Global -> Api.Session -> LoggedIn.Tab -> ( Element Core.Msg, Maybe (Element Core.Msg) )
view global session tab =
    let
        ( mainTab, popup ) =
            case tab of
                LoggedIn.Home uploadForm ->
                    ( homeView global session uploadForm, Nothing )

                LoggedIn.Preparation preparationModel ->
                    Preparation.view global session preparationModel

                LoggedIn.Acquisition acquisitionModel ->
                    ( Acquisition.view global session acquisitionModel, Nothing )

                LoggedIn.Edition editionModel ->
                    ( Edition.view global session editionModel, Nothing )

                LoggedIn.Settings modelSettings ->
                    ( Settings.view global session modelSettings, Nothing )

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
    ( Element.row
        [ Element.height Element.fill
        , Element.scrollbarY
        , Element.width Element.fill
        , Element.spacing 20
        ]
        [ element ]
    , popup
    )


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
                , projectsView global session uploadForm
                ]

        _ ->
            prePreparationView global session uploadForm


prePreparationView : Core.Global -> Api.Session -> LoggedIn.UploadForm -> Element Core.Msg
prePreparationView _ session uploadForm =
    let
        projectField =
            Element.column [ Element.width Element.fill, Element.spacing 10 ]
                [ Element.text "Nom du projet"
                , Dropdown.view (dropdownConfig uploadForm.projectName) uploadForm.dropdown (List.sortBy (\x -> -x.lastVisited) session.projects)
                ]

        capsuleField =
            Input.text []
                { label = Input.labelAbove [] (Element.text "Nom de la capsule")
                , onChange = \x -> Core.LoggedInMsg (LoggedIn.UploadSlideShowMsg (LoggedIn.UploadSlideShowChangeCapsuleName x))
                , text = uploadForm.capsuleName
                , placeholder = Nothing
                }

        slidesLabel =
            Element.column [ Element.spacing 5 ]
                [ Element.text "Regroupement des planches"
                , Element.el [ Font.size 10 ] (Element.text "Les slides séparés par des pointillets seront filmés en une fois")
                ]

        viewSlide : Maybe ( Int, ( Int, Api.Slide ) ) -> Element Core.Msg
        viewSlide slide =
            case slide of
                Nothing ->
                    Element.el [ Element.width Element.fill ] Element.none

                Just ( _, ( _, s ) ) ->
                    Element.image [ Border.color Colors.grey, Border.width 1, Element.width Element.fill ] { description = "", src = s.asset.asset_path }

        buildSlides : Maybe ( Int, ( Int, Api.Slide ) ) -> List (Maybe ( Int, ( Int, Api.Slide ) )) -> List (Element Core.Msg)
        buildSlides nextSlide input =
            let
                emptyPadding =
                    Element.el [ Element.height Element.fill, Element.paddingXY 10 0 ]
                        (Element.el
                            [ Element.height Element.fill
                            , Border.widthEach { left = 2, right = 0, top = 0, bottom = 0 }
                            , Element.htmlAttribute (Html.Attributes.style "border-style" "none")
                            ]
                            Element.none
                        )

                emptyFilling =
                    Element.el
                        [ Element.width Element.fill
                        , Element.height Element.fill
                        ]
                        Element.none
            in
            case input of
                [] ->
                    []

                [ Nothing ] ->
                    [ emptyFilling, emptyPadding ]

                [ Just ( index1, ( gos1, slide1 ) ) ] ->
                    let
                        head =
                            viewSlide (Just ( index1, ( gos1, slide1 ) ))

                        tail =
                            case nextSlide of
                                Just ( index2, ( gos2, _ ) ) ->
                                    let
                                        borderStyle =
                                            if gos1 == gos2 then
                                                Border.dashed

                                            else
                                                Border.solid

                                        delimiter =
                                            Input.button [ Element.paddingXY 10 0, Element.height Element.fill ]
                                                { label =
                                                    Element.el
                                                        [ Element.centerX
                                                        , Border.widthEach { left = 2, right = 0, top = 0, bottom = 0 }
                                                        , Border.color Colors.black
                                                        , borderStyle
                                                        , Element.height Element.fill
                                                        ]
                                                        Element.none
                                                , onPress =
                                                    Just
                                                        (Core.LoggedInMsg (LoggedIn.UploadSlideShowMsg (LoggedIn.UploadSlideShowSlideClicked index2)))
                                                }
                                    in
                                    [ delimiter ]

                                _ ->
                                    [ emptyPadding ]
                    in
                    head :: tail

                (Just ( index1, ( gos1, slide1 ) )) :: (Just ( index2, ( gos2, slide2 ) )) :: t ->
                    let
                        borderStyle =
                            if gos1 == gos2 then
                                Border.dashed

                            else
                                Border.solid

                        delimiter =
                            Input.button [ Element.paddingXY 10 0, Element.height Element.fill ]
                                { label =
                                    Element.el
                                        [ Element.centerX
                                        , Border.widthEach { left = 2, right = 0, top = 0, bottom = 0 }
                                        , Border.color Colors.black
                                        , borderStyle
                                        , Element.height Element.fill
                                        ]
                                        Element.none
                                , onPress =
                                    Just
                                        (Core.LoggedInMsg (LoggedIn.UploadSlideShowMsg (LoggedIn.UploadSlideShowSlideClicked index2)))
                                }
                    in
                    viewSlide (Just ( index1, ( gos1, slide1 ) )) :: delimiter :: buildSlides nextSlide (Just ( index2, ( gos2, slide2 ) ) :: t)

                (Just ( index1, ( gos1, slide1 ) )) :: Nothing :: t ->
                    viewSlide (Just ( index1, ( gos1, slide1 ) )) :: emptyPadding :: emptyFilling :: emptyPadding :: buildSlides nextSlide t

                Nothing :: t ->
                    emptyFilling :: emptyPadding :: buildSlides nextSlide t

        slides : Element Core.Msg
        slides =
            case uploadForm.slides of
                Nothing ->
                    Ui.spinner

                Just s ->
                    let
                        enumeratedSlides =
                            List.indexedMap (\x y -> ( x, y )) s

                        regrouped : List (List (Maybe ( Int, ( Int, Api.Slide ) )))
                        regrouped =
                            regroupSlides uploadForm.numberOfSlidesPerRow enumeratedSlides

                        prepare : List (List (Maybe ( Int, ( Int, Api.Slide ) ))) -> List ( Maybe ( Int, ( Int, Api.Slide ) ), List (Maybe ( Int, ( Int, Api.Slide ) )) )
                        prepare input =
                            case input of
                                [] ->
                                    []

                                h :: [] ->
                                    [ ( Nothing, h ) ]

                                _ :: [] :: _ ->
                                    -- This should be unreachable
                                    []

                                h1 :: (h2 :: t2) :: t ->
                                    ( h2, h1 ) :: prepare ((h2 :: t2) :: t)

                        elements : List (List (Element Core.Msg))
                        elements =
                            List.map (\( x, y ) -> buildSlides x y) (prepare regrouped)
                    in
                    Element.column
                        [ Element.width Element.fill, Element.spacing 10 ]
                        (List.map (\x -> Element.row [ Element.width Element.fill ] x) elements)

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


leftColumn : Core.Global -> Api.Session -> LoggedIn.UploadForm -> Element Core.Msg
leftColumn _ _ _ =
    Element.row [ Element.width Element.fill, Element.padding 10 ]
        [ Element.el [ Element.centerX ] (Ui.primaryButton (Just (Core.LoggedInMsg (LoggedIn.UploadSlideShowMsg LoggedIn.UploadSlideShowSelectFileRequested))) "Créer un nouveau projet")
        ]


capsuleView : Core.Global -> Api.Project -> Maybe LoggedIn.Rename -> Api.Capsule -> Element Core.Msg
capsuleView _ project rename capsule =
    let
        title =
            let
                default =
                    Input.button []
                        { onPress = Just (Core.LoggedInMsg (LoggedIn.CapsuleClicked capsule))
                        , label = Element.text capsule.name
                        }
            in
            case rename of
                Just (LoggedIn.RenameCapsule ( i, j, s )) ->
                    if i == project.id && j == capsule.id then
                        Element.row [ Element.width Element.fill ]
                            [ Input.text
                                [ Ui.onEnterEscape
                                    (Core.LoggedInMsg LoggedIn.ValidateRenameProject)
                                    (Core.LoggedInMsg LoggedIn.CancelRename)
                                , Element.htmlAttribute (Html.Events.onBlur (Core.LoggedInMsg LoggedIn.CancelRename))
                                ]
                                { onChange = \x -> Core.LoggedInMsg (LoggedIn.RenameMsg (LoggedIn.RenameCapsule ( project.id, capsule.id, x )))
                                , placeholder = Nothing
                                , text = s
                                , label = Input.labelHidden ""
                                }
                            ]

                    else
                        default

                _ ->
                    default
    in
    Element.row [ Element.width Element.fill, Element.spacing 10 ]
        [ title
        , Ui.penButton (Just (Core.LoggedInMsg (LoggedIn.RenameMsg (LoggedIn.RenameCapsule ( project.id, capsule.id, capsule.name ))))) "" "Renommer la capsule"
        ]


projectView : Core.Global -> ( Api.Project, Bool, Maybe LoggedIn.Rename ) -> Element Core.Msg
projectView global ( project, even, edited ) =
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
                let
                    default =
                        Input.button []
                            { onPress = Just (Core.LoggedInMsg (LoggedIn.ToggleFoldedProject project.id))
                            , label = Element.text (prefix ++ project.name)
                            }
                in
                case edited of
                    Just (LoggedIn.RenameProject ( i, s )) ->
                        if i == project.id then
                            Element.row [ Element.width Element.fill ]
                                [ Element.text prefix
                                , Input.text
                                    [ Ui.onEnterEscape
                                        (Core.LoggedInMsg LoggedIn.ValidateRenameProject)
                                        (Core.LoggedInMsg LoggedIn.CancelRename)
                                    , Element.htmlAttribute (Html.Events.onBlur (Core.LoggedInMsg LoggedIn.CancelRename))
                                    ]
                                    { onChange = \x -> Core.LoggedInMsg (LoggedIn.RenameMsg (LoggedIn.RenameProject ( project.id, x )))
                                    , placeholder = Nothing
                                    , text = s
                                    , label = Input.labelHidden ""
                                    }
                                ]

                        else
                            default

                    _ ->
                        default

            rename =
                Ui.penButton (Just (Core.LoggedInMsg (LoggedIn.RenameMsg (LoggedIn.RenameProject ( project.id, project.name ))))) "" "Renommer le projet"

            numberOfCapsules =
                let
                    l =
                        List.length project.capsules

                    plural =
                        if l < 2 then
                            ""

                        else
                            "s"
                in
                Element.el [ Font.italic ]
                    (Element.text ("(" ++ String.fromInt l ++ " capsule" ++ plural ++ ")"))

            created =
                Element.text ("crée le " ++ TimeUtils.timeToString global.zone project.lastVisited)

            row =
                Element.row [ Element.spacing 10, Element.width Element.fill ]
                    [ title
                    , rename
                    , numberOfCapsules
                    , Element.el [ Element.width Element.fill ] Element.none
                    , created
                    ]
          in
          if project.folded then
            row

          else
            Element.column
                [ Element.width Element.fill ]
                [ row
                , Element.column
                    [ Element.width Element.fill, Element.paddingXY 20 10, Element.spacing 10 ]
                    (List.map (capsuleView global project edited) project.capsules)
                ]
        ]


projectsView : Core.Global -> Api.Session -> LoggedIn.UploadForm -> Element Core.Msg
projectsView global session uploadForm =
    Element.column [ Element.width (Element.fillPortion 6), Element.alignTop ]
        (List.map (projectView global)
            (List.indexedMap
                (\i x ->
                    ( x
                    , modBy 2 i == 0
                    , uploadForm.rename
                    )
                )
                (List.sortBy (\x -> -x.lastVisited) session.projects)
            )
        )


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


dropdownConfig : String -> Dropdown.Config Api.Project Core.Msg
dropdownConfig name =
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
        |> Dropdown.withPromptElement (Element.el [ Element.width Element.fill ] (Element.text name))
