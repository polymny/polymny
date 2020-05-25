module Capsule.Views exposing (gosGhostView, slideGhostView, view)

import Api
import Capsule.Types as Capsule
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


headerView : List (Element Core.Msg) -> List (Element Core.Msg) -> List (Element Core.Msg)
headerView header el =
    case List.length header of
        0 ->
            el

        _ ->
            header ++ el


view : Api.Session -> Capsule.Model -> List (Element Core.Msg) -> Element Core.Msg
view session { details, slides, uploadForms, editPrompt, slideModel, gosModel } header =
    let
        project_header =
            case session.active_project of
                Just x ->
                    Ui.linkButton
                        (Just
                            (Core.LoggedInMsg <|
                                LoggedIn.PreparationMsg <|
                                    Preparation.ProjectClicked x
                            )
                        )
                        x.name

                Nothing ->
                    Element.none

        headers =
            headerView header
                [ Element.text " / "
                , project_header
                , Element.text " / "
                , Element.text details.capsule.name
                ]

        calculateOffset : Int -> Int
        calculateOffset index =
            slides |> List.map (\l -> List.length l) |> List.take index |> List.foldl (+) 0

        dialogConfig =
            if editPrompt.visible then
                Just (configPromptModal editPrompt)

            else
                Nothing
    in
    Element.column []
        [ Element.row [ Font.size 18 ] <| headers
        , Element.el
            [ Element.padding 10
            , Element.mapAttribute Core.LoggedInMsg <|
                Element.mapAttribute LoggedIn.PreparationMsg <|
                    Element.mapAttribute Preparation.CapsuleMsg <|
                        Element.mapAttribute Capsule.EditPromptMsg <|
                            Element.inFront (Dialog.view dialogConfig)
            ]
            (Element.row (Element.scrollbarX :: Attributes.designAttributes)
                [ capsuleInfoView session details uploadForms
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
                            (\( i, slide ) -> capsuleGosView gosModel slideModel (calculateOffset i) i slide)
                            (filterConsecutiveGosIds (List.indexedMap Tuple.pair slides))
                        )
                    ]
                ]
            )
        ]


filterConsecutiveGosIds : List ( Int, List Capsule.MaybeSlide ) -> List ( Int, List Capsule.MaybeSlide )
filterConsecutiveGosIds slides =
    List.reverse (filterConsecutiveGosIdsAux False [] slides)


filterConsecutiveGosIdsAux : Bool -> List ( Int, List Capsule.MaybeSlide ) -> List ( Int, List Capsule.MaybeSlide ) -> List ( Int, List Capsule.MaybeSlide )
filterConsecutiveGosIdsAux currentIsGosId current slides =
    case slides of
        [] ->
            current

        ( index, [ Capsule.GosId id ] ) :: t ->
            if currentIsGosId then
                filterConsecutiveGosIdsAux True current t

            else
                filterConsecutiveGosIdsAux True (( index, [ Capsule.GosId id ] ) :: current) t

        ( index, list ) :: t ->
            filterConsecutiveGosIdsAux False (( index, list ) :: current) t


capsuleInfoView : Api.Session -> Api.CapsuleDetails -> Capsule.Forms -> Element Core.Msg
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
            [ uploadView forms.slideShow Capsule.SlideShow ]
        , Element.column Attributes.uploadViewAttributes
            [ uploadView forms.background Capsule.Background
            , Element.el [ Element.centerX ] backgroundImgView
            ]
        , Element.column Attributes.uploadViewAttributes
            [ uploadView forms.logo Capsule.Logo
            , Element.el [ Element.centerX ] logoImgView
            ]
        ]



-- DRAG N DROP VIEWS


type DragOptions
    = Drag
    | Drop
    | Ghost
    | EventLess



-- GOS VIEWS


capsuleGosView : DnDList.Model -> DnDList.Groups.Model -> Int -> Int -> List Capsule.MaybeSlide -> Element Core.Msg
capsuleGosView gosModel slideModel offset gosIndex gos =
    case Capsule.gosSystem.info gosModel of
        Just { dragIndex } ->
            if dragIndex /= gosIndex then
                genericGosView Drop gosModel slideModel offset gosIndex gos

            else
                genericGosView EventLess gosModel slideModel offset gosIndex gos

        _ ->
            genericGosView Drag gosModel slideModel offset gosIndex gos


gosGhostView : DnDList.Model -> DnDList.Groups.Model -> List Capsule.MaybeSlide -> Element Core.Msg
gosGhostView gosModel slideModel slides =
    case maybeDragGos gosModel slides of
        Just s ->
            genericGosView Ghost gosModel slideModel 0 0 s

        _ ->
            Element.none


maybeDragGos : DnDList.Model -> List Capsule.MaybeSlide -> Maybe (List Capsule.MaybeSlide)
maybeDragGos gosModel slides =
    let
        s =
            Capsule.regroupSlides slides
    in
    Capsule.gosSystem.info gosModel
        |> Maybe.andThen (\{ dragIndex } -> s |> List.drop dragIndex |> List.head)


genericGosView : DragOptions -> DnDList.Model -> DnDList.Groups.Model -> Int -> Int -> List Capsule.MaybeSlide -> Element Core.Msg
genericGosView options gosModel slideModel offset index gos =
    let
        gosId : String
        gosId =
            if options == Ghost then
                "gos-ghost"

            else
                "gos-" ++ String.fromInt index

        dragAttributes : List (Element.Attribute Core.Msg)
        dragAttributes =
            if options == Drag && not (Capsule.isJustGosId gos) then
                convertAttributes (Capsule.gosSystem.dragEvents index gosId)

            else
                []

        dropAttributes : List (Element.Attribute Core.Msg)
        dropAttributes =
            if options == Drop && not (Capsule.isJustGosId gos) then
                convertAttributes (Capsule.gosSystem.dropEvents index gosId)

            else
                []

        ghostAttributes : List (Element.Attribute Core.Msg)
        ghostAttributes =
            if options == Ghost then
                convertAttributes (Capsule.gosSystem.ghostStyles gosModel)

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
            convertAttributes (Capsule.slideSystem.dropEvents offset slideId)

        slideId : String
        slideId =
            if options == Ghost then
                "slide-ghost"

            else
                "slide-" ++ String.fromInt offset

        slides : List (Element Core.Msg)
        slides =
            List.indexedMap (designSlideView slideModel offset) gos
    in
    case gos of
        [ Capsule.GosId _ ] ->
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
                [ Element.row (Element.width Element.fill :: dragAttributes ++ eventLessAttributes)
                    [ Element.el
                        Attributes.designGosTitleAttributes
                        (Element.text (String.fromInt index))
                    , Element.row [ Element.alignRight ] [ Ui.trashButton Nothing "" ]
                    ]
                , Element.column (Element.spacing 10 :: Attributes.designAttributes ++ eventLessAttributes) slides
                ]



-- SLIDES VIEWS


slideGhostView : DnDList.Groups.Model -> List Capsule.MaybeSlide -> Element Core.Msg
slideGhostView slideModel slides =
    case maybeDragSlide slideModel slides of
        Capsule.JustSlide s ->
            genericDesignSlideView Ghost slideModel 0 0 (Capsule.JustSlide s)

        _ ->
            Element.none


designSlideView : DnDList.Groups.Model -> Int -> Int -> Capsule.MaybeSlide -> Element Core.Msg
designSlideView slideModel offset localIndex slide =
    case ( Capsule.slideSystem.info slideModel, maybeDragSlide slideModel ) of
        ( Just { dragIndex }, _ ) ->
            if offset + localIndex == dragIndex then
                genericDesignSlideView EventLess slideModel offset localIndex slide

            else
                genericDesignSlideView Drop slideModel offset localIndex slide

        _ ->
            genericDesignSlideView Drag slideModel offset localIndex slide


maybeDragSlide : DnDList.Groups.Model -> List Capsule.MaybeSlide -> Capsule.MaybeSlide
maybeDragSlide slideModel slides =
    let
        x =
            Capsule.slideSystem.info slideModel
                |> Maybe.andThen (\{ dragIndex } -> slides |> List.drop dragIndex |> List.head)
    in
    case x of
        Just (Capsule.JustSlide n) ->
            Capsule.JustSlide n

        _ ->
            Capsule.GosId -1


genericDesignSlideView : DragOptions -> DnDList.Groups.Model -> Int -> Int -> Capsule.MaybeSlide -> Element Core.Msg
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
            if options == Drag && Capsule.isJustSlide s then
                convertAttributes (Capsule.slideSystem.dragEvents globalIndex slideId)

            else
                []

        dropAttributes : List (Element.Attribute Core.Msg)
        dropAttributes =
            if options == Drop then
                convertAttributes (Capsule.slideSystem.dropEvents globalIndex slideId)

            else
                []

        ghostAttributes : List (Element.Attribute Core.Msg)
        ghostAttributes =
            if options == Ghost then
                convertAttributes (Capsule.slideSystem.ghostStyles slideModel)

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
        Capsule.GosId _ ->
            Element.none

        Capsule.JustSlide slide ->
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
                            (Element.text <| "Slide #" ++ String.fromInt slide.position)
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
            , Element.el [] (Element.text ("DEBUG: Slide position  = " ++ String.fromInt slide.position))
            , Element.el [] (Element.text ("DEBUG: position in gos = " ++ String.fromInt slide.position_in_gos))
            , Element.el [] (Element.text ("DEBUG: gos = " ++ String.fromInt slide.gos))
            ]
        ]


genrericDesignSlide2ndColumnView : List (Element.Attribute Core.Msg) -> Api.Slide -> Element Core.Msg
genrericDesignSlide2ndColumnView eventLessAttributes slide =
    let
        promptMsg : Core.Msg
        promptMsg =
            Core.LoggedInMsg <|
                LoggedIn.PreparationMsg <|
                    Preparation.CapsuleMsg <|
                        Capsule.EditPromptMsg <|
                            Capsule.EditPromptOpenDialog slide.id slide.prompt
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


configPromptModal : Capsule.EditPrompt -> Dialog.Config Capsule.EditPromptMsg
configPromptModal editPromptContent =
    { closeMessage = Just Capsule.EditPromptCloseDialog
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


bodyPromptModal : Capsule.EditPrompt -> Element Capsule.EditPromptMsg
bodyPromptModal { status, prompt } =
    let
        submitButton =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "Updating slide..."

                Status.Success () ->
                    Ui.primaryButtonDisabled "Slide updated"

                _ ->
                    Ui.primaryButton (Just Capsule.EditPromptSubmitted) "Update prompt"

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
                , onChange = Capsule.EditPromptTextChanged
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


uploadView : Capsule.UploadForm -> Capsule.UploadModel -> Element Core.Msg
uploadView form model =
    let
        text =
            case model of
                Capsule.SlideShow ->
                    "Choisir une présentation au format PDF"

                Capsule.Background ->
                    "Choisir un fond "

                Capsule.Logo ->
                    "Choisir un logo"
    in
    Element.column
        [ Element.padding 10
        , Element.spacing 10
        ]
        [ Element.text text
        , uploadFormView form model
        ]


uploadFormView : Capsule.UploadForm -> Capsule.UploadModel -> Element Core.Msg
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


selectFileButton : Capsule.UploadModel -> Element Core.Msg
selectFileButton model =
    let
        msg =
            case model of
                Capsule.SlideShow ->
                    Element.map Capsule.UploadSlideShowMsg <|
                        Ui.simpleButton (Just Capsule.UploadSlideShowSelectFileRequested) "Select slide show"

                Capsule.Background ->
                    Element.map Capsule.UploadBackgroundMsg <|
                        Ui.simpleButton (Just Capsule.UploadBackgroundSelectFileRequested) "Select backgound"

                Capsule.Logo ->
                    Element.map Capsule.UploadLogoMsg <|
                        Ui.simpleButton (Just Capsule.UploadLogoSelectFileRequested) "Select logo"
    in
    Element.map Core.LoggedInMsg <|
        Element.map LoggedIn.PreparationMsg <|
            Element.map Preparation.CapsuleMsg msg


uploadButton : Capsule.UploadModel -> Element Core.Msg
uploadButton model =
    let
        msg =
            case model of
                Capsule.SlideShow ->
                    Element.map Capsule.UploadSlideShowMsg <|
                        Ui.primaryButton (Just Capsule.UploadSlideShowFormSubmitted) "Upload slide show"

                Capsule.Background ->
                    Element.map Capsule.UploadBackgroundMsg <|
                        Ui.primaryButton (Just Capsule.UploadBackgroundFormSubmitted) "Upload backgound"

                Capsule.Logo ->
                    Element.map Capsule.UploadLogoMsg <|
                        Ui.primaryButton (Just Capsule.UploadLogoFormSubmitted) "Upload logo"
    in
    Element.map Core.LoggedInMsg <|
        Element.map LoggedIn.PreparationMsg <|
            Element.map Preparation.CapsuleMsg msg


convertAttributes : List (Html.Attribute Capsule.DnDMsg) -> List (Element.Attribute Core.Msg)
convertAttributes attributes =
    List.map
        (\x -> Element.mapAttribute (\y -> Core.LoggedInMsg (LoggedIn.PreparationMsg (Preparation.CapsuleMsg (Capsule.DnD y)))) x)
        (List.map Element.htmlAttribute attributes)
