module Preparation.Views exposing (..)

import Capsule
import Core.Types as Core
import DnDList
import DnDList.Groups
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import FontAwesome as Fa
import Html
import Html.Attributes
import Lang
import Preparation.Types as Preparation
import Preparation.Updates as P2
import Status
import Ui.Colors as Colors
import Ui.LeftColumn as Ui
import Ui.Utils as Ui
import User exposing (User)


view : Core.Global -> User -> Preparation.Model -> ( Element Core.Msg, Maybe (Element Core.Msg) )
view global _ model =
    let
        calculateOffset : Int -> Int
        calculateOffset index =
            model.slides |> List.map (\l -> List.length l) |> List.take index |> List.foldl (+) 0

        zoomOutButton =
            Ui.iconButton
                [ Font.color Colors.navbar ]
                { onPress = Just Core.ZoomOut, icon = Fa.searchMinus, text = Nothing, tooltip = Just (Lang.zoomOut global.lang) }

        zoomInButton =
            Ui.iconButton
                [ Font.color Colors.navbar ]
                { onPress = Just Core.ZoomIn, icon = Fa.searchPlus, text = Nothing, tooltip = Just (Lang.zoomIn global.lang) }

        toolbar =
            Element.row
                [ Element.alignRight, Element.spacing 10, Element.padding 10 ]
                [ zoomOutButton, zoomInButton ]

        output =
            model.slides
                |> List.indexedMap Tuple.pair
                |> filterConsecutiveGosIds
                |> List.map (\( i, s ) -> viewGos global model (calculateOffset i) i s)
                |> Element.column [ Ui.wf, Element.padding 10 ]

        popup =
            case ( model.editPrompt, model.changeSlideForm, model.tracker ) of
                ( Just s, _, _ ) ->
                    Just (viewEditPrompt global model s)

                ( _, _, Just p ) ->
                    Just (waitView global (Tuple.second p))

                ( _, Just i, _ ) ->
                    Just (viewSlideChangeSlideForm global i)

                _ ->
                    Nothing
    in
    ( Element.column [ Ui.wf, Ui.hf ] [ toolbar, output ], popup )


viewSlideChangeSlideForm : Core.Global -> Preparation.ChangeSlideForm -> Element Core.Msg
viewSlideChangeSlideForm global { page, status } =
    let
        validate =
            case String.toInt page of
                Just o ->
                    if o >= 1 then
                        Ui.primaryButton
                            { onPress = Just (Core.PreparationMsg Preparation.ExtraResourcePageValidate)
                            , label = Element.text (Lang.confirm global.lang)
                            }

                    else
                        Element.text (Lang.insertNumber global.lang)

                _ ->
                    Element.text (Lang.insertNumber global.lang)

        cancel =
            Ui.simpleButton
                { onPress = Just (Core.PreparationMsg Preparation.ExtraResourcePageCancel)
                , label = Element.text (Lang.cancel global.lang)
                }

        error =
            case status of
                Status.Error ->
                    Ui.error (Element.text (Lang.pdfConvertFailed global.lang))

                _ ->
                    Element.none
    in
    Ui.customSizedPopup 1
        (Lang.replaceSlide global.lang)
        (Element.column [ Element.padding 10, Ui.wf, Ui.hf, Background.color Colors.whiteBis ]
            [ error
            , Input.text [ Element.centerY, Element.htmlAttribute (Html.Attributes.type_ "number") ]
                { label = Input.labelAbove [] (Element.text (Lang.whichPage global.lang))
                , onChange = \x -> Core.PreparationMsg (Preparation.ExtraResourceChangePage x)
                , placeholder = Nothing
                , text = page
                }
            , Element.row [ Element.alignRight, Element.spacing 10 ] [ cancel, validate ]
            ]
        )


waitView : Core.Global -> Preparation.Progress -> Element Core.Msg
waitView global progress =
    let
        ( msg, pf ) =
            case progress of
                Preparation.Upload p ->
                    ( Lang.uploading global.lang, p )

                Preparation.Transcoding p ->
                    ( Lang.transcoding global.lang, p )

        cancel =
            Ui.simpleButton
                { onPress = Just (Core.PreparationMsg Preparation.ExtraResourceVideoUploadCancel)
                , label = Element.text (Lang.cancel global.lang)
                }
    in
    Ui.customSizedPopup 1
        (Lang.replaceSlide global.lang)
        (Element.el [ Element.padding 10, Ui.wf, Ui.hf, Background.color Colors.whiteBis ]
            (Element.column [ Ui.wf, Element.centerY ]
                [ Element.paragraph [ Element.centerX, Element.centerY, Font.center ]
                    [ Element.text msg ]
                , Ui.progressBar pf
                , Element.row [ Element.alignRight, Element.spacing 10 ] [ cancel ]
                ]
            )
        )


viewGos : Core.Global -> Preparation.Model -> Int -> Int -> List Preparation.MaybeSlide -> Element Core.Msg
viewGos global model offset index slides =
    let
        gosIndex =
            (index - 1) // 2

        ty =
            case Preparation.gosSystem.info model.gosModel of
                Just { dragIndex } ->
                    if dragIndex == gosIndex then
                        EventLess

                    else
                        Drop

                _ ->
                    Drag
    in
    viewGosGeneric global model offset index slides ty


viewGosGhost : Core.Global -> Preparation.Model -> List Preparation.MaybeSlide -> Element Core.Msg
viewGosGhost global model slides =
    case maybeDragGos model.gosModel slides of
        Just s ->
            viewGosGeneric global model 0 0 s Ghost

        _ ->
            Element.none


maybeDragGos : DnDList.Model -> List Preparation.MaybeSlide -> Maybe (List Preparation.MaybeSlide)
maybeDragGos gosModel slides =
    let
        s =
            P2.regroupSlides slides
    in
    Preparation.gosSystem.info gosModel
        |> Maybe.andThen (\{ dragIndex } -> s |> List.drop dragIndex |> List.head)


viewGosGeneric : Core.Global -> Preparation.Model -> Int -> Int -> List Preparation.MaybeSlide -> DragOptions -> Element Core.Msg
viewGosGeneric global model offset index slides ty =
    let
        gosIndex : Int
        gosIndex =
            (index - 1) // 2

        gosId : String
        gosId =
            if ty == Ghost then
                "gos-ghost"

            else
                "gos-" ++ String.fromInt index

        dropAttributes : List (Element.Attribute Core.Msg)
        dropAttributes =
            if ty == Drop && not (isJustGosId slides) then
                convertAttributes (Preparation.gosSystem.dropEvents index gosId)

            else
                []

        ghostAttributes : List (Element.Attribute Core.Msg)
        ghostAttributes =
            if ty == Ghost then
                convertAttributes (Preparation.gosSystem.ghostStyles model.gosModel)

            else
                []

        eventLessAttributes : List (Element.Attribute Core.Msg)
        eventLessAttributes =
            if ty == EventLess then
                [ Ui.hidden ]

            else
                []

        slideDropAttributes : List (Element.Attribute Core.Msg)
        slideDropAttributes =
            convertAttributes (Preparation.slideSystem.dropEvents offset slideId)

        slideDropAttributes2 : List (Element.Attribute Core.Msg)
        slideDropAttributes2 =
            let
                o =
                    offset + List.length slides - 1
            in
            convertAttributes (Preparation.slideSystem.dropEvents o ("slide-" ++ String.fromInt o))

        slideId : String
        slideId =
            if ty == Ghost then
                "slide-ghost"

            else
                "slide-" ++ String.fromInt offset

        indexedSlides : List ( Int, Preparation.MaybeSlide )
        indexedSlides =
            List.indexedMap Tuple.pair slides

        regroupedSlides : List (List ( Int, Maybe Preparation.MaybeSlide ))
        regroupedSlides =
            Preparation.regroupSlides global.zoomLevel indexedSlides

        mapper : ( Int, Maybe Preparation.MaybeSlide ) -> Element Core.Msg
        mapper ( i, s ) =
            case s of
                Just slide ->
                    viewSlide global model gosIndex offset i slide

                Nothing ->
                    Element.el (Ui.hf :: Ui.wf :: slideDropAttributes2) Element.none

        slideElement : Element Core.Msg
        slideElement =
            List.map (\x -> Element.row [ Ui.wf, Element.spacing 10 ] (List.map mapper x)) regroupedSlides
                |> List.reverse
                |> Element.column [ Element.spacing 10, Ui.wf ]
    in
    case slides of
        [ Preparation.GosId insideId ] ->
            Element.row [ Ui.wf, Element.spacing 10 ]
                [ Element.el
                    [ Ui.id gosId, Ui.wf ]
                    (Element.el
                        (Ui.id slideId :: Element.paddingXY 0 20 :: Ui.wf :: slideDropAttributes)
                        (Element.el [ Element.centerY, Ui.wf ]
                            (Element.el
                                [ Ui.wf, Border.color Colors.greyLighter, Ui.borderBottom 1 ]
                                Element.none
                            )
                        )
                    )
                , Ui.iconButton [ Font.color Colors.navbar ]
                    { onPress = Just (Core.PreparationMsg (Preparation.ExtraResourceSelect (Preparation.AddGos (insideId // 2))))
                    , icon = Fa.plusSquare
                    , text = Nothing
                    , tooltip = Just (Lang.createGrain global.lang)
                    }
                ]

        _ ->
            Element.row [ Ui.wf, Element.spacing 10 ]
                [ Element.el
                    (Ui.id gosId :: Ui.wf :: dropAttributes ++ ghostAttributes)
                    (Element.el (Element.spacing 20 :: Ui.wf :: eventLessAttributes) slideElement)
                , Ui.iconButton [ Font.color Colors.navbar ]
                    { onPress = Just (Core.PreparationMsg (Preparation.ExtraResourceSelect (Preparation.AddSlide gosIndex)))
                    , icon = Fa.plusSquare
                    , text = Nothing
                    , tooltip = Just (Lang.addSlide global.lang)
                    }
                ]


viewSlide : Core.Global -> Preparation.Model -> Int -> Int -> Int -> Preparation.MaybeSlide -> Element Core.Msg
viewSlide global model gosIndex offset localIndex s =
    let
        ty =
            case ( Preparation.slideSystem.info model.slideModel, maybeDragSlide model.slideModel ) of
                ( Just { dragIndex }, _ ) ->
                    if offset + localIndex == dragIndex then
                        EventLess

                    else
                        Drop

                _ ->
                    Drag
    in
    viewSlideGeneric global model gosIndex offset localIndex s ty


viewSlideGhost : Core.Global -> Preparation.Model -> List Preparation.MaybeSlide -> Element Core.Msg
viewSlideGhost global model slides =
    case maybeDragSlide model.slideModel slides of
        Preparation.Slide _ s ->
            viewSlideGeneric global model 0 0 0 (Preparation.Slide -1 s) Ghost

        _ ->
            Element.none


viewSlideGeneric : Core.Global -> Preparation.Model -> Int -> Int -> Int -> Preparation.MaybeSlide -> DragOptions -> Element Core.Msg
viewSlideGeneric global model gosIndex offset localIndex s ty =
    let
        globalIndex : Int
        globalIndex =
            offset + localIndex

        slideId : String
        slideId =
            if ty == Ghost then
                "slide-ghost"

            else
                "slide-" ++ String.fromInt globalIndex

        dragAttributes : List (Element.Attribute Core.Msg)
        dragAttributes =
            if ty == Drag && isJustSlide s then
                convertAttributes (Preparation.slideSystem.dragEvents globalIndex slideId)

            else
                []

        dropAttributes : List (Element.Attribute Core.Msg)
        dropAttributes =
            if ty == Drop then
                convertAttributes (Preparation.slideSystem.dropEvents globalIndex slideId)

            else
                []

        ghostAttributes : List (Element.Attribute Core.Msg)
        ghostAttributes =
            if ty == Ghost then
                convertAttributes (Preparation.slideSystem.ghostStyles model.slideModel)

            else
                []

        media =
            case s of
                Preparation.Slide _ realSlide ->
                    case realSlide.extra of
                        Nothing ->
                            Element.image [ Ui.wf, Border.width 1, Border.color Colors.greyLighter ]
                                { src = Capsule.slidePath model.capsule realSlide, description = "" }

                        Just uuid ->
                            let
                                src =
                                    Capsule.assetPath model.capsule (uuid ++ ".mp4")
                            in
                            Element.html
                                (Html.video
                                    [ Html.Attributes.class "wf", Html.Attributes.controls True ]
                                    [ Html.source [ Html.Attributes.src src, Html.Attributes.controls True ] [] ]
                                )

                _ ->
                    Element.none

        mkButton data =
            Ui.iconButton
                [ Font.color Colors.navbar
                , Element.padding 5
                , Background.color Colors.greyLighter
                , Border.rounded 5
                ]
                data
                |> Element.map Core.PreparationMsg

        toolBar =
            case s of
                Preparation.Slide _ realSlide ->
                    Element.row [ Element.alignRight, Element.padding 5, Element.spacing 5 ]
                        [ mkButton
                            { onPress = Just (Preparation.StartEditPrompt realSlide.uuid)
                            , icon = Fa.font
                            , text = Nothing
                            , tooltip = Just (Lang.editPrompt global.lang)
                            }
                        , case realSlide.extra of
                            Just _ ->
                                mkButton
                                    { onPress = Just (Preparation.ExtraResourceDelete realSlide)
                                    , icon = Fa.times
                                    , text = Nothing
                                    , tooltip = Just (Lang.replaceSlideOrAddExternalResource global.lang)
                                    }

                            Nothing ->
                                mkButton
                                    { onPress = Just (Preparation.ExtraResourceSelect (Preparation.ReplaceSlide realSlide))
                                    , icon = Fa.image
                                    , text = Nothing
                                    , tooltip = Just (Lang.replaceSlideOrAddExternalResource global.lang)
                                    }
                        , mkButton
                            { onPress = Just (Preparation.RequestDeleteSlide realSlide.uuid)
                            , icon = Fa.trash
                            , text = Nothing
                            , tooltip = Just (Lang.deleteSlide global.lang)
                            }
                        ]

                _ ->
                    Element.none

        info =
            Element.el
                [ Element.alignTop
                , Element.alignLeft
                , Background.color Colors.greyLighter
                , Border.roundEach { topLeft = 0, topRight = 0, bottomLeft = 0, bottomRight = 10 }
                , Element.padding 5
                ]
                (Element.text
                    (Lang.grain global.lang
                        ++ " "
                        ++ String.fromInt (gosIndex + 1)
                        ++ " / "
                        ++ Lang.slide global.lang
                        ++ " "
                        ++ String.fromInt localIndex
                    )
                )
    in
    case s of
        Preparation.Slide _ _ ->
            Element.el
                (Ui.id slideId :: Ui.wf :: Element.inFront toolBar :: Element.inFront info :: dropAttributes ++ ghostAttributes)
                (Element.el (Element.width Element.fill :: dragAttributes) media)

        _ ->
            Element.none


viewEditPrompt : Core.Global -> Preparation.Model -> Capsule.Slide -> Element Core.Msg
viewEditPrompt global model slide =
    let
        previousSlide =
            Capsule.previousSlide slide model.capsule

        nextSlide =
            Capsule.nextSlide slide model.capsule

        content =
            Element.column [ Ui.wf, Ui.hf, Background.color Colors.whiteBis, Element.padding 10, Element.spacing 10 ]
                [ Element.row [ Ui.wf, Ui.hf, Element.spacing 10 ]
                    [ Element.column [ Element.spacing 10, Ui.wf, Element.centerY ]
                        [ Element.image
                            [ Ui.wf, Border.width 1, Border.color Colors.greyLighter ]
                            { src = Capsule.slidePath model.capsule slide, description = "" }
                        , Element.row [ Ui.wf ]
                            [ case previousSlide of
                                Just s ->
                                    Ui.iconButton [ Font.color Colors.navbar ]
                                        { onPress = Just (Core.PreparationMsg (Preparation.PromptChangeSlide (Just s)))
                                        , icon = Fa.arrowLeft
                                        , text = Nothing
                                        , tooltip = Just (Lang.goToPreviousSlide global.lang)
                                        }
                                        |> Element.el [ Element.alignLeft ]

                                _ ->
                                    Element.none
                            , case nextSlide of
                                Just s ->
                                    Ui.iconButton [ Font.color Colors.navbar ]
                                        { onPress = Just (Core.PreparationMsg (Preparation.PromptChangeSlide (Just s)))
                                        , icon = Fa.arrowRight
                                        , text = Nothing
                                        , tooltip = Just (Lang.goToNextSlide global.lang)
                                        }
                                        |> Element.el [ Element.alignRight ]

                                _ ->
                                    Element.none
                            ]
                        ]
                    , Input.multiline [ Ui.wf, Ui.hf ]
                        { label = Input.labelAbove [] Element.none
                        , onChange = \x -> Core.PreparationMsg (Preparation.PromptChanged x)
                        , placeholder = Nothing
                        , spellcheck = False
                        , text = slide.prompt
                        }
                    ]
                , Element.row [ Element.alignRight, Element.spacing 10 ]
                    [ Ui.simpleButton
                        { onPress = Just (Core.PreparationMsg Preparation.CancelPromptChange)
                        , label = Element.text (Lang.cancel global.lang)
                        }
                    , Ui.primaryButton
                        { onPress = Just (Core.PreparationMsg (Preparation.PromptChangeSlide Nothing))
                        , label = Element.text (Lang.confirm global.lang)
                        }
                    ]
                ]
    in
    Ui.customSizedPopup 5 (Lang.promptEdition global.lang) content



-- Utils functions


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


convertAttributes : List (Html.Attribute Preparation.DnDMsg) -> List (Element.Attribute Core.Msg)
convertAttributes attributes =
    List.map
        (\x -> Element.mapAttribute (\y -> Core.PreparationMsg (Preparation.DnD y)) x)
        (List.map Element.htmlAttribute attributes)


isJustGosId : List Preparation.MaybeSlide -> Bool
isJustGosId slides =
    case slides of
        [ Preparation.GosId _ ] ->
            True

        _ ->
            False


maybeDragSlide : DnDList.Groups.Model -> List Preparation.MaybeSlide -> Preparation.MaybeSlide
maybeDragSlide slideModel slides =
    let
        x =
            Preparation.slideSystem.info slideModel
                |> Maybe.andThen (\{ dragIndex } -> slides |> List.drop dragIndex |> List.head)
    in
    case x of
        Just (Preparation.Slide id n) ->
            Preparation.Slide id n

        _ ->
            Preparation.GosId -1


isJustSlide : Preparation.MaybeSlide -> Bool
isJustSlide slide =
    case slide of
        Preparation.Slide _ _ ->
            True

        _ ->
            False



-- DnD shit


type DragOptions
    = Drag
    | Drop
    | Ghost
    | EventLess
