module Preparation.Views exposing (gosGhostView, slideGhostView, view)

import Api
import Core.Types as Core
import Dialog
import DnDList
import DnDList.Groups
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import File exposing (File)
import Html
import Html.Attributes
import LoggedIn.Types as LoggedIn
import Preparation.Types as Preparation
import Status
import Ui.Attributes as Attributes
import Ui.Colors as Colors
import Ui.Ui as Ui
import Utils


view : Core.Global -> Api.Session -> Preparation.Model -> Element Core.Msg
view global session model =
    let
        mainPage =
            mainView global session model

        element =
            Element.column
                Ui.mainViewAttributes2
                [ Utils.headerView "preparation" model.details
                , mainPage
                ]
    in
    Element.row Ui.mainViewAttributes1
        [ element ]


mainView : Core.Global -> Api.Session -> Preparation.Model -> Element Core.Msg
mainView global session { details, slides, uploadForms, editPrompt, slideModel, gosModel } =
    let
        calculateOffset : Int -> Int
        calculateOffset index =
            slides |> List.map (\l -> List.length l) |> List.take index |> List.foldl (+) 0

        dialogConfig =
            if editPrompt.visible then
                Just (configPromptModal editPrompt)

            else
                Nothing

        capsuleInfo =
            if global.beta then
                capsuleInfoView session details uploadForms

            else
                Element.none

        isGosLocked : Api.Gos -> Bool
        isGosLocked gos =
            gos.locked

        isCapsuleLocked : Bool
        isCapsuleLocked =
            List.all isGosLocked details.structure

        msg =
            Core.LoggedInMsg <| LoggedIn.EditionClicked details True

        autoEdition =
            if isCapsuleLocked then
                Ui.primaryButton (Just msg) "Edition automatique de la vidéo"

            else
                Ui.primaryButtonDisabled "Edition automatique de la vidéo"
    in
    Element.column []
        [ Element.el
            [ Element.padding 10
            , Element.mapAttribute Core.LoggedInMsg <|
                Element.mapAttribute LoggedIn.PreparationMsg <|
                    Element.mapAttribute Preparation.EditPromptMsg <|
                        Element.inFront (Dialog.view dialogConfig)
            ]
            (Element.row (Element.scrollbarX :: Attributes.designAttributes)
                [ capsuleInfo
                , Element.column
                    [ Element.scrollbarX
                    , Element.centerX
                    , Element.alignTop
                    ]
                    [ Element.el
                        [ Element.centerX
                        , Font.color Colors.artEvening
                        , Font.size 20
                        ]
                        (Element.text "Slide timeline")
                    , Element.row (Background.color Colors.white :: Attributes.designAttributes)
                        (List.map
                            (\( i, slide ) -> capsuleGosView global details gosModel slideModel (calculateOffset i) i slide)
                            (filterConsecutiveGosIds (List.indexedMap Tuple.pair slides))
                        )
                    , Element.el [ Element.padding 20, Element.alignLeft ] autoEdition
                    ]
                ]
            )
        ]


filterConsecutiveGosIds : List ( Int, List Preparation.MaybeSlide ) -> List ( Int, List Preparation.MaybeSlide )
filterConsecutiveGosIds slides =
    List.reverse (filterConsecutiveGosIdsAux False [] slides)


filterConsecutiveGosIdsAux : Bool -> List ( Int, List Preparation.MaybeSlide ) -> List ( Int, List Preparation.MaybeSlide ) -> List ( Int, List Preparation.MaybeSlide )
filterConsecutiveGosIdsAux currentIsGosId current slides =
    case slides of
        [] ->
            current

        ( index, [ Preparation.GosId id ] ) :: t ->
            if currentIsGosId then
                filterConsecutiveGosIdsAux True current t

            else
                filterConsecutiveGosIdsAux True (( index, [ Preparation.GosId id ] ) :: current) t

        ( index, list ) :: t ->
            filterConsecutiveGosIdsAux False (( index, list ) :: current) t


capsuleInfoView : Api.Session -> Api.CapsuleDetails -> Preparation.Forms -> Element Core.Msg
capsuleInfoView session capsuleDetails forms =
    let
        backgroundImgView =
            case capsuleDetails.background of
                Just m ->
                    viewSlideImage m.asset_path

                Nothing ->
                    Element.none

        logoImgView =
            case capsuleDetails.logo of
                Just m ->
                    viewSlideImage m.asset_path

                Nothing ->
                    Element.none
    in
    Element.column Attributes.capsuleInfoViewAttributes
        [ Element.column []
            [ Element.el [ Font.size 20 ] (Element.text "Infos sur la capsule")
            , Element.el [ Font.size 14 ] (Element.text ("Loaded capsule is  " ++ capsuleDetails.capsule.name))
            , Element.el [ Font.size 14 ] (Element.text ("Title :   " ++ capsuleDetails.capsule.title))
            , Element.el [ Font.size 14 ] (Element.text ("Desritpion:  " ++ capsuleDetails.capsule.description))
            ]
        , Element.column Attributes.uploadViewAttributes
            [ uploadView forms.slideShow Preparation.SlideShow ]
        , Element.column Attributes.uploadViewAttributes
            [ uploadView forms.background Preparation.Background
            , Element.el [ Element.centerX ] backgroundImgView
            ]
        , Element.column Attributes.uploadViewAttributes
            [ uploadView forms.logo Preparation.Logo
            , Element.el [ Element.centerX ] logoImgView
            ]
        ]



-- DRAG N DROP VIEWS


type DragOptions
    = Drag
    | Drop
    | Ghost
    | EventLess
    | Locked



-- GOS VIEWS


capsuleGosView : Core.Global -> Api.CapsuleDetails -> DnDList.Model -> DnDList.Groups.Model -> Int -> Int -> List Preparation.MaybeSlide -> Element Core.Msg
capsuleGosView global capsule gosModel slideModel offset gosIndex gos =
    case ( global.beta, Preparation.gosSystem.info gosModel ) of
        ( False, _ ) ->
            genericGosView capsule Locked gosModel slideModel offset gosIndex gos

        ( _, Just { dragIndex } ) ->
            if dragIndex /= gosIndex then
                genericGosView capsule Drop gosModel slideModel offset gosIndex gos

            else
                genericGosView capsule EventLess gosModel slideModel offset gosIndex gos

        _ ->
            genericGosView capsule Drag gosModel slideModel offset gosIndex gos


gosGhostView : Api.CapsuleDetails -> DnDList.Model -> DnDList.Groups.Model -> List Preparation.MaybeSlide -> Element Core.Msg
gosGhostView capsule gosModel slideModel slides =
    case maybeDragGos gosModel slides of
        Just s ->
            genericGosView capsule Ghost gosModel slideModel 0 0 s

        _ ->
            Element.none


maybeDragGos : DnDList.Model -> List Preparation.MaybeSlide -> Maybe (List Preparation.MaybeSlide)
maybeDragGos gosModel slides =
    let
        s =
            Preparation.regroupSlides slides
    in
    Preparation.gosSystem.info gosModel
        |> Maybe.andThen (\{ dragIndex } -> s |> List.drop dragIndex |> List.head)


genericGosView : Api.CapsuleDetails -> DragOptions -> DnDList.Model -> DnDList.Groups.Model -> Int -> Int -> List Preparation.MaybeSlide -> Element Core.Msg
genericGosView capsule options gosModel slideModel offset index gos =
    let
        gosId : String
        gosId =
            if options == Ghost then
                "gos-ghost"

            else
                "gos-" ++ String.fromInt index

        -- TODO computing the gosid this way is ugly af
        gosIndex : Int
        gosIndex =
            (index - 1) // 2

        dragAttributes : List (Element.Attribute Core.Msg)
        dragAttributes =
            if options == Drag && not (Preparation.isJustGosId gos) then
                convertAttributes (Preparation.gosSystem.dragEvents index gosId)

            else
                []

        dropAttributes : List (Element.Attribute Core.Msg)
        dropAttributes =
            if options == Drop && not (Preparation.isJustGosId gos) then
                convertAttributes (Preparation.gosSystem.dropEvents index gosId)

            else
                []

        ghostAttributes : List (Element.Attribute Core.Msg)
        ghostAttributes =
            if options == Ghost then
                convertAttributes (Preparation.gosSystem.ghostStyles gosModel)

            else
                []

        eventLessAttributes : List (Element.Attribute Core.Msg)
        eventLessAttributes =
            if options == EventLess then
                [ Element.htmlAttribute (Html.Attributes.style "visibility" "hidden") ]

            else
                []

        slideDropAttributes : List (Element.Attribute Core.Msg)
        slideDropAttributes =
            convertAttributes (Preparation.slideSystem.dropEvents offset slideId)

        slideId : String
        slideId =
            if options == Ghost then
                "slide-ghost"

            else
                "slide-" ++ String.fromInt offset

        slides : List (Element Core.Msg)
        slides =
            List.indexedMap (designSlideView (not (Maybe.withDefault True (Maybe.map .locked structure))) slideModel offset) gos

        structure : Maybe Api.Gos
        structure =
            List.head (List.drop gosIndex capsule.structure)

        cameraButton : Element Core.Msg
        cameraButton =
            Ui.cameraButton (Just (Core.LoggedInMsg (LoggedIn.Record capsule gosIndex))) ""

        movieButton : Element Core.Msg
        movieButton =
            Ui.movieButton Nothing ""

        lockButton : Element Core.Msg
        lockButton =
            (if Maybe.withDefault False (Maybe.map .locked structure) then
                Ui.closeLockButton (Just (Preparation.SwitchLock gosIndex)) ""

             else
                Ui.openLockButton (Just (Preparation.SwitchLock gosIndex)) ""
            )
                |> Element.map LoggedIn.PreparationMsg
                |> Element.map Core.LoggedInMsg

        leftButtons : List (Element Core.Msg)
        leftButtons =
            case Maybe.map .record structure of
                Just (Just _) ->
                    [ movieButton, cameraButton ]

                _ ->
                    [ cameraButton ]
    in
    case gos of
        [ Preparation.GosId _ ] ->
            Element.column
                [ Element.htmlAttribute (Html.Attributes.id gosId)
                , Element.height Element.fill
                , Element.width (Element.px 50)
                ]
                [ Element.el
                    (Element.htmlAttribute (Html.Attributes.id slideId)
                        :: Element.width (Element.px 50)
                        :: Element.height (Element.px 300)
                        :: slideDropAttributes
                    )
                    Element.none
                ]

        _ ->
            Element.column
                (Element.htmlAttribute (Html.Attributes.id gosId)
                    :: dropAttributes
                    ++ ghostAttributes
                    ++ Attributes.designGosAttributes
                )
                [ Element.row (Element.width Element.fill :: eventLessAttributes)
                    [ Element.row [ Element.alignLeft, Element.spacing 10 ] leftButtons
                    , Element.el
                        (Attributes.designGosTitleAttributes ++ dragAttributes)
                        (Element.text (String.fromInt (gosIndex + 1)))
                    , Element.row [ Element.alignRight, Element.spacing 10 ] [ lockButton, Ui.trashButton Nothing "" ]
                    ]
                , Element.column (Element.spacing 10 :: Attributes.designAttributes ++ eventLessAttributes) slides
                ]



-- SLIDES VIEWS


slideGhostView : DnDList.Groups.Model -> List Preparation.MaybeSlide -> Element Core.Msg
slideGhostView slideModel slides =
    case maybeDragSlide slideModel slides of
        Preparation.JustSlide s _ ->
            genericDesignSlideView Ghost slideModel 0 0 (Preparation.JustSlide s -1)

        _ ->
            Element.none


designSlideView : Bool -> DnDList.Groups.Model -> Int -> Int -> Preparation.MaybeSlide -> Element Core.Msg
designSlideView enabled slideModel offset localIndex slide =
    let
        t =
            case ( enabled, Preparation.slideSystem.info slideModel, maybeDragSlide slideModel ) of
                ( False, _, _ ) ->
                    Locked

                ( _, Just { dragIndex }, _ ) ->
                    if offset + localIndex == dragIndex then
                        EventLess

                    else
                        Drop

                _ ->
                    Drag
    in
    genericDesignSlideView t slideModel offset localIndex slide


maybeDragSlide : DnDList.Groups.Model -> List Preparation.MaybeSlide -> Preparation.MaybeSlide
maybeDragSlide slideModel slides =
    let
        x =
            Preparation.slideSystem.info slideModel
                |> Maybe.andThen (\{ dragIndex } -> slides |> List.drop dragIndex |> List.head)
    in
    case x of
        Just (Preparation.JustSlide n id) ->
            Preparation.JustSlide n id

        _ ->
            Preparation.GosId -1


genericDesignSlideView : DragOptions -> DnDList.Groups.Model -> Int -> Int -> Preparation.MaybeSlide -> Element Core.Msg
genericDesignSlideView options slideModel offset localIndex s =
    let
        globalIndex : Int
        globalIndex =
            offset + localIndex

        slideId : String
        slideId =
            if options == Ghost then
                "slide-ghost"

            else
                "slide-" ++ String.fromInt globalIndex

        dragAttributes : List (Element.Attribute Core.Msg)
        dragAttributes =
            if options == Drag && Preparation.isJustSlide s then
                convertAttributes (Preparation.slideSystem.dragEvents globalIndex slideId)

            else
                []

        dropAttributes : List (Element.Attribute Core.Msg)
        dropAttributes =
            if options == Drop then
                convertAttributes (Preparation.slideSystem.dropEvents globalIndex slideId)

            else
                []

        ghostAttributes : List (Element.Attribute Core.Msg)
        ghostAttributes =
            if options == Ghost then
                convertAttributes (Preparation.slideSystem.ghostStyles slideModel)

            else
                []

        eventLessAttributes : List (Element.Attribute Core.Msg)
        eventLessAttributes =
            if options == EventLess then
                [ Element.htmlAttribute (Html.Attributes.style "visibility" "hidden") ]

            else
                []
    in
    case s of
        Preparation.GosId _ ->
            Element.none

        Preparation.JustSlide slide _ ->
            Element.el
                (Element.htmlAttribute (Html.Attributes.id slideId) :: dropAttributes ++ ghostAttributes)
                (Element.column
                    Attributes.genericDesignSlideViewAttributes
                    [ Element.el
                        (Element.height
                            (Element.shrink
                                |> Element.maximum 40
                                |> Element.minimum 20
                            )
                            :: Element.width Element.fill
                            :: eventLessAttributes
                            ++ dragAttributes
                        )
                      <|
                        Element.el
                            [ Font.size 22
                            , Element.centerX
                            , Font.color Colors.artEvening
                            ]
                            (Element.text <| "Slide #" ++ String.fromInt localIndex)
                    , Element.row
                        [ Element.spacingXY 2 0 ]
                        [ genrericDesignSlide1stColumnView (eventLessAttributes ++ dragAttributes) slide
                        , genrericDesignSlide2ndColumnView eventLessAttributes slide
                        ]
                    ]
                )


genrericDesignSlide1stColumnView : List (Element.Attribute Core.Msg) -> Api.Slide -> Element Core.Msg
genrericDesignSlide1stColumnView eventLessAttributes slide =
    Element.column
        (Element.alignTop
            :: Element.width
                (Element.shrink
                    |> Element.maximum 300
                    |> Element.minimum 210
                )
            :: eventLessAttributes
        )
        [ viewSlideImage slide.asset.asset_path
        , Element.column [ Font.size 14, Element.spacing 4 ]
            [ Element.column [ Element.padding 4 ]
                [ Element.el [ Element.paddingXY 0 4 ] <| Element.text "Additional Resources :"
                , Element.el [ Element.spacingXY 2 4 ] <|
                    Ui.addButton
                        Nothing
                        " Ajouter des ressources"
                ]
            , Element.el [] (Element.text ("DEBUG: slide_id = " ++ String.fromInt slide.id))
            ]
        ]


genrericDesignSlide2ndColumnView : List (Element.Attribute Core.Msg) -> Api.Slide -> Element Core.Msg
genrericDesignSlide2ndColumnView eventLessAttributes slide =
    let
        promptMsg : Core.Msg
        promptMsg =
            Core.LoggedInMsg <|
                LoggedIn.PreparationMsg <|
                    Preparation.EditPromptMsg <|
                        Preparation.EditPromptOpenDialog slide.id slide.prompt
    in
    Element.column
        (Element.alignTop
            :: Element.centerX
            :: Element.spacing 4
            :: Element.padding 4
            :: Element.width
                (Element.shrink
                    |> Element.maximum 300
                    |> Element.minimum 210
                )
            :: eventLessAttributes
        )
        [ Element.el
            [ Font.size 14
            , Element.centerX
            ]
            (Element.text "Prompteur")
        , Element.el
            [ Border.rounded 5
            , Border.width 2
            , Border.color Colors.grey
            , Background.color Colors.black
            , Element.centerX
            , Element.scrollbarY
            , Element.height (Element.px 150)
            , Element.width (Element.px 150)
            , Element.padding 5
            , Font.size 12
            , Font.color Colors.white
            ]
            (Element.text slide.prompt)
        , Element.row []
            [ Ui.editButton (Just promptMsg) "Modifier"
            , Ui.clearButton Nothing "Effacer"
            ]
        ]


viewSlideImage : String -> Element Core.Msg
viewSlideImage url =
    Element.image [ Element.width (Element.px 200) ] { src = url, description = "One desc" }


configPromptModal : Preparation.EditPrompt -> Dialog.Config Preparation.EditPromptMsg
configPromptModal editPromptContent =
    { closeMessage = Just Preparation.EditPromptCloseDialog
    , maskAttributes = []
    , containerAttributes =
        [ Background.color Colors.white
        , Border.rounded 5
        , Element.centerX
        , Element.padding 10
        , Element.spacing 20
        , Element.width (Element.px 600)
        ]
    , headerAttributes = [ Font.size 24, Element.padding 5 ]
    , bodyAttributes = [ Background.color Colors.grey, Element.padding 20, Element.width Element.fill ]
    , footerAttributes = []
    , header = Just (Element.text "PROMPTER")
    , body = Just (bodyPromptModal editPromptContent)
    , footer = Nothing
    }


bodyPromptModal : Preparation.EditPrompt -> Element Preparation.EditPromptMsg
bodyPromptModal { status, prompt } =
    let
        submitButton =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "Updating slide..."

                Status.Success () ->
                    Ui.primaryButtonDisabled "Slide updated"

                _ ->
                    Ui.primaryButton (Just Preparation.EditPromptSubmitted) "Update prompt"

        message =
            case status of
                Status.Error () ->
                    Just (Ui.errorModal "Slide update failed")

                Status.Success () ->
                    Just (Ui.successModal "Slide prommpt udpdated")

                _ ->
                    Nothing

        header =
            Element.row [ Element.centerX ] [ Element.text "Edit prompt" ]

        fields =
            [ Input.multiline [ Element.height (Element.px 400) ]
                { label = Input.labelAbove [] (Element.text "Prompteur:")
                , onChange = Preparation.EditPromptTextChanged
                , placeholder = Nothing
                , text = prompt
                , spellcheck = True
                }
            , submitButton
            ]

        form =
            case message of
                Just m ->
                    header :: m :: fields

                Nothing ->
                    header :: fields
    in
    Element.column
        [ Element.centerX
        , Element.padding 10
        , Element.spacing 10
        , Element.width Element.fill
        ]
        form


uploadView : Preparation.UploadForm -> Preparation.UploadModel -> Element Core.Msg
uploadView form model =
    let
        text =
            case model of
                Preparation.SlideShow ->
                    "Choisir une présentation au format PDF"

                Preparation.Background ->
                    "Choisir un fond "

                Preparation.Logo ->
                    "Choisir un logo"
    in
    Element.column
        [ Element.padding 10
        , Element.spacing 10
        ]
        [ Element.text text
        , uploadFormView form model
        ]


uploadFormView : Preparation.UploadForm -> Preparation.UploadModel -> Element Core.Msg
uploadFormView form model =
    Element.column [ Element.centerX, Element.spacing 20 ]
        [ Element.row
            [ Element.spacing 20
            , Element.centerX
            ]
            [ selectFileButton model
            , fileNameElement form.file
            , uploadButton model
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


selectFileButton : Preparation.UploadModel -> Element Core.Msg
selectFileButton model =
    let
        msg =
            case model of
                Preparation.SlideShow ->
                    Element.map Preparation.UploadSlideShowMsg <|
                        Ui.simpleButton (Just Preparation.UploadSlideShowSelectFileRequested) "Select slide show"

                Preparation.Background ->
                    Element.map Preparation.UploadBackgroundMsg <|
                        Ui.simpleButton (Just Preparation.UploadBackgroundSelectFileRequested) "Select backgound"

                Preparation.Logo ->
                    Element.map Preparation.UploadLogoMsg <|
                        Ui.simpleButton (Just Preparation.UploadLogoSelectFileRequested) "Select logo"
    in
    Element.map Core.LoggedInMsg <|
        Element.map LoggedIn.PreparationMsg msg


uploadButton : Preparation.UploadModel -> Element Core.Msg
uploadButton model =
    let
        msg =
            case model of
                Preparation.SlideShow ->
                    Element.map Preparation.UploadSlideShowMsg <|
                        Ui.primaryButton (Just Preparation.UploadSlideShowFormSubmitted) "Upload slide show"

                Preparation.Background ->
                    Element.map Preparation.UploadBackgroundMsg <|
                        Ui.primaryButton (Just Preparation.UploadBackgroundFormSubmitted) "Upload backgound"

                Preparation.Logo ->
                    Element.map Preparation.UploadLogoMsg <|
                        Ui.primaryButton (Just Preparation.UploadLogoFormSubmitted) "Upload logo"
    in
    Element.map Core.LoggedInMsg <|
        Element.map LoggedIn.PreparationMsg msg


convertAttributes : List (Html.Attribute Preparation.DnDMsg) -> List (Element.Attribute Core.Msg)
convertAttributes attributes =
    List.map
        (\x -> Element.mapAttribute (\y -> Core.LoggedInMsg (LoggedIn.PreparationMsg (Preparation.DnD y))) x)
        (List.map Element.htmlAttribute attributes)
