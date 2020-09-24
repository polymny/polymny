module Preparation.Views exposing (gosGhostView, leftColumnView, slideGhostView, view)

import Api
import Core.Types as Core
import DnDList
import DnDList.Groups
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Html.Attributes
import LoggedIn.Types as LoggedIn
import Preparation.Types as Preparation
import Ui.Attributes as Attributes
import Ui.Colors as Colors
import Ui.Ui as Ui


view : Core.Global -> Api.Session -> Preparation.Model -> ( Element Core.Msg, Maybe (Element Core.Msg) )
view global session model =
    mainView global session model


mainView : Core.Global -> Api.Session -> Preparation.Model -> ( Element Core.Msg, Maybe (Element Core.Msg) )
mainView global _ { details, slides, editPrompt, slideModel, gosModel, broken } =
    let
        calculateOffset : Int -> Int
        calculateOffset index =
            slides |> List.map (\l -> List.length l) |> List.take index |> List.foldl (+) 0

        msg =
            Core.LoggedInMsg <| LoggedIn.EditionClicked details True

        increaseMsg =
            Core.LoggedInMsg <| LoggedIn.PreparationMsg <| Preparation.IncreaseNumberOfSlidesPerRow

        decreaseMsg =
            Core.LoggedInMsg <| LoggedIn.PreparationMsg <| Preparation.DecreaseNumberOfSlidesPerRow

        autoEdition =
            Ui.primaryButton (Just msg) "Edition automatique de la vidéo"

        resultView =
            Element.row [ Element.width Element.fill, Element.height Element.fill, Element.scrollbarY ]
                [ leftColumnView details Nothing
                , Element.column [ Element.width (Element.fillPortion 7), Element.height Element.fill ]
                    [ Element.column [ Element.width Element.fill ]
                        [ Element.row [ Element.spacing 5, Element.padding 5, Element.alignRight ]
                            [ Ui.primaryButton (Just increaseMsg) "-"
                            , Element.text "Zoom"
                            , Ui.primaryButton (Just decreaseMsg) "+"
                            ]
                        ]
                    , Element.el
                        [ Element.padding 10
                        , Element.height Element.fill
                        , Element.scrollbarY
                        ]
                        (Element.row [ Element.width Element.fill ]
                            [ Element.column
                                [ Element.alignTop
                                , Element.width Element.fill
                                ]
                                [ Element.column (Element.width Element.fill :: Attributes.designAttributes)
                                    (List.map
                                        (\( i, slide ) -> capsuleGosView global global.numberOfSlidesPerRow gosModel slideModel (calculateOffset i) i slide)
                                        (filterConsecutiveGosIds (List.indexedMap Tuple.pair slides))
                                    )
                                , Element.el [ Element.padding 20, Element.alignLeft ] autoEdition
                                ]
                            ]
                        )
                    ]
                ]
    in
    case ( broken, editPrompt.visible ) of
        ( Preparation.Broken _, _ ) ->
            let
                reject =
                    Just (Core.LoggedInMsg (LoggedIn.PreparationMsg Preparation.RejectBroken))

                accept =
                    Just (Core.LoggedInMsg (LoggedIn.PreparationMsg Preparation.AcceptBroken))

                element =
                    Element.column [ Element.height Element.fill, Element.width Element.fill ]
                        [ Element.el [ Element.width Element.fill, Background.color Colors.primary ]
                            (Element.el
                                [ Element.centerX, Font.color Colors.white, Element.padding 10 ]
                                (Element.text "ATTENTION")
                            )
                        , Element.el
                            [ Element.width Element.fill, Element.height Element.fill, Background.color Colors.whiteDark ]
                            (Element.column [ Element.width Element.fill, Element.padding 10, Element.height Element.fill, Element.spacing 10, Font.center ]
                                [ Element.el [ Element.height Element.fill ] Element.none
                                , Element.paragraph [] [ Element.text "Ce déplacement va détruire certains de vos enregistrements." ]
                                , Element.paragraph [] [ Element.text "Voulez-vous vraiment continuer ?" ]
                                , Element.el [ Element.height Element.fill ] Element.none
                                , Element.row [ Element.alignRight, Element.spacing 10 ] [ Ui.simpleButton reject "Annuler", Ui.primaryButton accept "Poursuivre" ]
                                ]
                            )
                        ]
            in
            ( resultView, Just (Ui.centerElement element) )

        ( _, True ) ->
            let
                cancel =
                    Just (Core.LoggedInMsg (LoggedIn.PreparationMsg (Preparation.EditPromptMsg Preparation.EditPromptCloseDialog)))

                validate =
                    Just (Core.LoggedInMsg (LoggedIn.PreparationMsg (Preparation.EditPromptMsg Preparation.EditPromptSubmitted)))

                promptModal =
                    bodyPromptModal editPrompt
                        |> Element.map Preparation.EditPromptMsg
                        |> Element.map LoggedIn.PreparationMsg
                        |> Element.map Core.LoggedInMsg

                element =
                    Element.column [ Element.height Element.fill, Element.width Element.fill ]
                        [ Element.el [ Element.width Element.fill, Background.color Colors.primary ]
                            (Element.el
                                [ Element.centerX, Font.color Colors.white, Element.padding 10 ]
                                (Element.text "Prompteur")
                            )
                        , Element.el
                            [ Element.width Element.fill, Element.height Element.fill, Background.color Colors.whiteDark ]
                            (Element.column [ Element.width Element.fill, Element.padding 10, Element.height Element.fill, Element.spacing 10, Font.center ]
                                [ promptModal
                                , Element.el [ Element.height Element.fill ] Element.none
                                , Element.row [ Element.alignRight, Element.spacing 10 ]
                                    [ Ui.simpleButton cancel "Annuler", Ui.primaryButton validate "Valider" ]
                                ]
                            )
                        ]
            in
            ( resultView, Just (Ui.centerElement element) )

        _ ->
            ( resultView, Nothing )


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



-- DRAG N DROP VIEWS


type DragOptions
    = Drag
    | Drop
    | Ghost
    | EventLess



-- GOS VIEWS


capsuleGosView : Core.Global -> Int -> DnDList.Model -> DnDList.Groups.Model -> Int -> Int -> List Preparation.MaybeSlide -> Element Core.Msg
capsuleGosView global numberOfSlidesPerRow gosModel slideModel offset gosIndex gos =
    case Preparation.gosSystem.info gosModel of
        Just { dragIndex } ->
            if dragIndex /= gosIndex then
                genericGosView global numberOfSlidesPerRow Drop gosModel slideModel offset gosIndex gos

            else
                genericGosView global numberOfSlidesPerRow EventLess gosModel slideModel offset gosIndex gos

        _ ->
            genericGosView global numberOfSlidesPerRow Drag gosModel slideModel offset gosIndex gos


gosGhostView : Core.Global -> Int -> DnDList.Model -> DnDList.Groups.Model -> List Preparation.MaybeSlide -> Element Core.Msg
gosGhostView global numberOfSlidesPerRow gosModel slideModel slides =
    case maybeDragGos gosModel slides of
        Just s ->
            genericGosView global numberOfSlidesPerRow Ghost gosModel slideModel 0 0 s

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


regroupSlidesAux : Int -> List (List ( Int, Maybe Preparation.MaybeSlide )) -> List ( Int, Maybe Preparation.MaybeSlide ) -> List (List ( Int, Maybe Preparation.MaybeSlide ))
regroupSlidesAux number current list =
    case ( list, current ) of
        ( [], _ ) ->
            current

        ( h :: t, [] ) ->
            regroupSlidesAux number [ [ h ] ] t

        ( h :: t, h2 :: t2 ) ->
            if List.length (List.filterMap (\( _, x ) -> Preparation.filterSlide (Maybe.withDefault (Preparation.GosId -1) x)) h2) < number then
                regroupSlidesAux number ((h2 ++ [ h ]) :: t2) t

            else
                regroupSlidesAux number ([ h ] :: h2 :: t2) t


regroupSlides : Int -> List ( Int, Preparation.MaybeSlide ) -> List (List ( Int, Maybe Preparation.MaybeSlide ))
regroupSlides number list =
    case regroupSlidesAux number [] (List.map (\( a, b ) -> ( a, Just b )) list) of
        [] ->
            []

        h :: t ->
            (h ++ List.repeat (number - List.length (List.filterMap (\( _, x ) -> Preparation.filterSlide (Maybe.withDefault (Preparation.GosId -1) x)) h)) ( -1, Nothing )) :: t


genericGosView : Core.Global -> Int -> DragOptions -> DnDList.Model -> DnDList.Groups.Model -> Int -> Int -> List Preparation.MaybeSlide -> Element Core.Msg
genericGosView global numberOfSlidesPerRow options gosModel slideModel offset index gos =
    let
        gosId : String
        gosId =
            if options == Ghost then
                "gos-ghost"

            else
                "gos-" ++ String.fromInt index

        -- gosIndex : Int
        -- gosIndex =
        --     (index - 1) // 2
        --
        -- dragAttributes : List (Element.Attribute Core.Msg)
        -- dragAttributes =
        --     if options == Drag && not (Preparation.isJustGosId gos) then
        --         convertAttributes (Preparation.gosSystem.dragEvents index gosId)
        --     else
        --         []
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

        indexedSlides : List ( Int, Preparation.MaybeSlide )
        indexedSlides =
            List.indexedMap (\i x -> ( i, x )) gos

        regroupedSlides : List (List ( Int, Maybe Preparation.MaybeSlide ))
        regroupedSlides =
            regroupSlides numberOfSlidesPerRow indexedSlides

        mapper : ( Int, Maybe Preparation.MaybeSlide ) -> Element Core.Msg
        mapper ( i, s ) =
            case s of
                Just slide ->
                    designSlideView global slideModel offset i slide

                Nothing ->
                    Element.el [ Element.width Element.fill ] Element.none

        slides : Element Core.Msg
        slides =
            Element.column [ Element.spacing 10, Element.width Element.fill ] (List.reverse (List.map (\x -> Element.row [ Element.width Element.fill, Element.spacing 10 ] (List.map mapper x)) regroupedSlides))
    in
    case gos of
        [ Preparation.GosId _ ] ->
            Element.column
                [ Element.htmlAttribute (Html.Attributes.id gosId)
                , Element.width Element.fill
                ]
                [ Element.el
                    (Element.htmlAttribute (Html.Attributes.id slideId)
                        :: Element.height (Element.px 50)
                        :: Element.width Element.fill
                        :: slideDropAttributes
                    )
                    (Element.el [ Element.centerY, Element.width Element.fill ]
                        (Element.el
                            [ Element.width Element.fill
                            , Border.color Colors.black
                            , Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
                            ]
                            Element.none
                        )
                    )
                ]

        _ ->
            Element.row
                (Element.htmlAttribute (Html.Attributes.id gosId)
                    :: Element.width Element.fill
                    :: dropAttributes
                    ++ ghostAttributes
                    ++ Attributes.designGosAttributes
                )
                [ Element.el
                    (Element.spacing 20
                        :: Element.width Element.fill
                        :: Attributes.designAttributes
                        ++ eventLessAttributes
                    )
                    slides
                ]



-- SLIDES VIEWS


slideGhostView : Core.Global -> DnDList.Groups.Model -> List Preparation.MaybeSlide -> Element Core.Msg
slideGhostView global slideModel slides =
    case maybeDragSlide slideModel slides of
        Preparation.JustSlide s _ ->
            genericDesignSlideView global Ghost slideModel 0 0 (Preparation.JustSlide s -1)

        _ ->
            Element.none


designSlideView : Core.Global -> DnDList.Groups.Model -> Int -> Int -> Preparation.MaybeSlide -> Element Core.Msg
designSlideView global slideModel offset localIndex slide =
    let
        t =
            case ( Preparation.slideSystem.info slideModel, maybeDragSlide slideModel ) of
                ( Just { dragIndex }, _ ) ->
                    if offset + localIndex == dragIndex then
                        EventLess

                    else
                        Drop

                _ ->
                    Drag
    in
    genericDesignSlideView global t slideModel offset localIndex slide


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


genericDesignSlideView : Core.Global -> DragOptions -> DnDList.Groups.Model -> Int -> Int -> Preparation.MaybeSlide -> Element Core.Msg
genericDesignSlideView _ options slideModel offset localIndex s =
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
    in
    case s of
        Preparation.GosId _ ->
            Element.none

        Preparation.JustSlide slide index ->
            let
                -- computing the gosid this way is ugly af
                gosIndex : Int
                gosIndex =
                    (index - 1) // 2

                media =
                    case slide.extra of
                        Just asset ->
                            Element.html <|
                                htmlVideo asset.asset_path

                        Nothing ->
                            viewSlideImage slide.asset.asset_path

                extraResourceMsg : Core.Msg
                extraResourceMsg =
                    Core.LoggedInMsg <|
                        LoggedIn.PreparationMsg <|
                            Preparation.UploadExtraResourceMsg <|
                                Preparation.UploadExtraResourceSelectFileRequested slide.id

                promptMsg : Core.Msg
                promptMsg =
                    Core.LoggedInMsg <|
                        LoggedIn.PreparationMsg <|
                            Preparation.EditPromptMsg <|
                                Preparation.EditPromptOpenDialog slide.id slide.prompt

                deleteExtraMsg : Core.Msg
                deleteExtraMsg =
                    Core.LoggedInMsg <|
                        LoggedIn.PreparationMsg <|
                            Preparation.SlideDelete gosIndex slide.id

                inFront =
                    Element.row [ Element.padding 10, Element.spacing 10, Element.alignRight ]
                        [ Ui.imageButton (Just extraResourceMsg) "" "Ajouter une ressource externe"
                        , Ui.fontButton (Just promptMsg) "" "Changer le texte du prompteur"
                        , Ui.trashButton (Just deleteExtraMsg) "" "Supprimer le slide"
                        ]
            in
            Element.el
                (Element.htmlAttribute (Html.Attributes.id slideId)
                    :: Element.inFront inFront
                    :: Element.width Element.fill
                    :: dropAttributes
                    ++ ghostAttributes
                )
                (Element.el (Element.width Element.fill :: dragAttributes) media)


leftColumnView : Api.CapsuleDetails -> Maybe Int -> Element Core.Msg
leftColumnView details currentGos =
    let
        slides =
            Preparation.setupSlides details

        getGos : Int -> Maybe Api.Gos
        getGos gosIndex =
            List.head (List.drop gosIndex details.structure)

        inFront : Int -> Element Core.Msg
        inFront i =
            Element.el [ Element.width Element.fill ]
                (Element.row [ Element.padding 10, Element.spacing 10, Element.alignRight ]
                    [ case Maybe.map .record (getGos i) of
                        Just (Just record) ->
                            Element.newTabLink [] { url = record, label = Ui.movieButton Nothing "" "Voir la vidéo enregistrée" }

                        _ ->
                            Element.none
                    , Ui.cameraButton
                        (case currentGos of
                            Just gosIndex ->
                                if gosIndex == i then
                                    Nothing

                                else
                                    Just (Core.LoggedInMsg (LoggedIn.Record details i))

                            _ ->
                                Just (Core.LoggedInMsg (LoggedIn.Record details i))
                        )
                        ""
                        "Filmer"
                    ]
                )

        gosView : List Preparation.MaybeSlide -> Element Core.Msg
        gosView gos =
            case gos of
                [] ->
                    Element.none

                (Preparation.GosId _) :: t ->
                    gosView t

                (Preparation.JustSlide s i) :: _ ->
                    Input.button
                        (Element.inFront (inFront ((i - 1) // 2))
                            :: (case currentGos of
                                    Just gosIndex ->
                                        if gosIndex == ((i - 1) // 2) then
                                            [ Border.width 5, Border.color Colors.primary ]

                                        else
                                            []

                                    _ ->
                                        []
                               )
                        )
                        { onPress = Just (Core.LoggedInMsg (LoggedIn.GosClicked i))
                        , label = viewSlideImage s.asset.asset_path
                        }

        goss =
            List.map gosView slides
    in
    Element.column
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.scrollbarY
        , Element.padding 15
        , Element.spacing 15
        , Element.alignTop
        , Background.color Colors.grey
        ]
        goss


htmlVideo : String -> Html msg
htmlVideo url =
    Html.video
        [ Html.Attributes.controls True
        , Html.Attributes.class "wf"
        ]
        [ Html.source
            [ Html.Attributes.src url ]
            []
        ]


viewSlideImage : String -> Element Core.Msg
viewSlideImage url =
    Element.image
        [ Element.width Element.fill ]
        { src = url, description = "One desc" }


bodyPromptModal : Preparation.EditPrompt -> Element Preparation.EditPromptMsg
bodyPromptModal { prompt } =
    let
        fields =
            [ Input.multiline [ Element.height (Element.px 400) ]
                { label = Input.labelAbove [] Element.none
                , onChange = Preparation.EditPromptTextChanged
                , placeholder = Nothing
                , text = prompt
                , spellcheck = True
                }
            ]
    in
    Element.column
        [ Element.centerX
        , Element.padding 10
        , Element.spacing 10
        , Element.width Element.fill
        ]
        fields


convertAttributes : List (Html.Attribute Preparation.DnDMsg) -> List (Element.Attribute Core.Msg)
convertAttributes attributes =
    List.map
        (\x -> Element.mapAttribute (\y -> Core.LoggedInMsg (LoggedIn.PreparationMsg (Preparation.DnD y))) x)
        (List.map Element.htmlAttribute attributes)
