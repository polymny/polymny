module Preparation.Views exposing (gosGhostView, leftColumnView, slideGhostView, view)

import Api
import Core.Types as Core
import DnDList
import DnDList.Groups
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import File exposing (File)
import Html exposing (Html)
import Html.Attributes
import LoggedIn.Types as LoggedIn
import Preparation.Types as Preparation
import Status
import Ui.Attributes as Attributes
import Ui.Colors as Colors
import Ui.Ui as Ui


view : Core.Global -> Api.Session -> Preparation.Model -> ( Element Core.Msg, Maybe (Element Core.Msg) )
view global session model =
    mainView global session model


mainView : Core.Global -> Api.Session -> Preparation.Model -> ( Element Core.Msg, Maybe (Element Core.Msg) )
mainView global session { details, slides, uploadForms, editPrompt, slideModel, gosModel, t, broken } =
    let
        calculateOffset : Int -> Int
        calculateOffset index =
            slides |> List.map (\l -> List.length l) |> List.take index |> List.foldl (+) 0

        -- capsuleInfo =
        --     if global.beta then
        --         capsuleInfoView session details uploadForms
        --     else
        --         Element.none
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
                , Element.column [ Element.width (Element.fillPortion 6), Element.height Element.fill ]
                    [ Element.row [ Element.spacing 5, Element.padding 5, Element.alignRight ]
                        [ Ui.primaryButton (Just decreaseMsg) "-"
                        , Element.text (String.fromInt global.numberOfSlidesPerRow)
                        , Ui.primaryButton (Just increaseMsg) "+"
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
                                        (\( i, slide ) -> capsuleGosView global uploadForms.extraResource global.numberOfSlidesPerRow uploadForms.replaceSlide details gosModel slideModel (calculateOffset i) i slide)
                                        (filterConsecutiveGosIds (List.indexedMap Tuple.pair slides))
                                    )
                                , Element.el [ Element.padding 20, Element.alignLeft ] autoEdition

                                --, Element.column []
                                --    [ Element.row
                                --        [ Element.centerX, Element.alignLeft ]
                                --        [ tabEl Preparation.First t
                                --        , tabEl Preparation.Second t
                                --        , tabEl Preparation.Third t
                                --        ]
                                --    ]
                                --, Element.text "Un texte dans le tab"
                                ]
                            ]
                        )
                    ]
                ]

        centerElement element =
            Element.column
                [ Element.width Element.fill, Element.height Element.fill, Background.color (Element.rgba255 0 0 0 0.8) ]
                [ Element.el [ Element.width Element.fill, Element.height Element.fill ] Element.none
                , Element.el [ Element.width Element.fill, Element.height Element.fill ]
                    (Element.row [ Element.width Element.fill, Element.height Element.fill ]
                        [ Element.el [ Element.width Element.fill, Element.height Element.fill ] Element.none
                        , Element.el [ Element.width Element.fill, Element.height Element.fill ] element
                        , Element.el [ Element.width Element.fill, Element.height Element.fill ] Element.none
                        ]
                    )
                , Element.el [ Element.width Element.fill, Element.height Element.fill ] Element.none
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
            ( resultView, Just (centerElement element) )

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
            ( resultView, Just (centerElement element) )

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


capsuleGosView : Core.Global -> Preparation.UploadExtraResourceForm -> Int -> Preparation.ReplaceSlideForm -> Api.CapsuleDetails -> DnDList.Model -> DnDList.Groups.Model -> Int -> Int -> List Preparation.MaybeSlide -> Element Core.Msg
capsuleGosView global uploadForm numberOfSlidesPerRow replaceSlideForm capsule gosModel slideModel offset gosIndex gos =
    case ( global.beta, Preparation.gosSystem.info gosModel ) of
        ( False, _ ) ->
            genericGosView global uploadForm numberOfSlidesPerRow replaceSlideForm capsule Locked gosModel slideModel offset gosIndex gos

        ( _, Just { dragIndex } ) ->
            if dragIndex /= gosIndex then
                genericGosView global uploadForm numberOfSlidesPerRow replaceSlideForm capsule Drop gosModel slideModel offset gosIndex gos

            else
                genericGosView global uploadForm numberOfSlidesPerRow replaceSlideForm capsule EventLess gosModel slideModel offset gosIndex gos

        _ ->
            genericGosView global uploadForm numberOfSlidesPerRow replaceSlideForm capsule Drag gosModel slideModel offset gosIndex gos


gosGhostView : Core.Global -> Preparation.UploadExtraResourceForm -> Int -> Preparation.ReplaceSlideForm -> Api.CapsuleDetails -> DnDList.Model -> DnDList.Groups.Model -> List Preparation.MaybeSlide -> Element Core.Msg
gosGhostView global uploadForm numberOfSlidesPerRow replaceSlideForm capsule gosModel slideModel slides =
    case maybeDragGos gosModel slides of
        Just s ->
            genericGosView global uploadForm numberOfSlidesPerRow replaceSlideForm capsule Ghost gosModel slideModel 0 0 s

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


genericGosView : Core.Global -> Preparation.UploadExtraResourceForm -> Int -> Preparation.ReplaceSlideForm -> Api.CapsuleDetails -> DragOptions -> DnDList.Model -> DnDList.Groups.Model -> Int -> Int -> List Preparation.MaybeSlide -> Element Core.Msg
genericGosView global uploadForm numberOfSlidesPerRow replaceSlideForm capsule options gosModel slideModel offset index gos =
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
                    designSlideView global uploadForm replaceSlideForm (not (Maybe.withDefault True (Maybe.map .locked structure))) slideModel offset i slide

                Nothing ->
                    Element.el [ Element.width Element.fill ] Element.none

        slides : Element Core.Msg
        slides =
            Element.column [ Element.spacing 10, Element.width Element.fill ] (List.reverse (List.map (\x -> Element.row [ Element.width Element.fill, Element.spacing 10 ] (List.map mapper x)) regroupedSlides))

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
            if global.beta then
                (if Maybe.withDefault False (Maybe.map .locked structure) then
                    Ui.closeLockButton (Just (Preparation.SwitchLock gosIndex)) ""

                 else
                    Ui.openLockButton (Just (Preparation.SwitchLock gosIndex)) ""
                )
                    |> Element.map LoggedIn.PreparationMsg
                    |> Element.map Core.LoggedInMsg

            else
                Element.none

        leftButtons : List (Element Core.Msg)
        leftButtons =
            case Maybe.map .record structure of
                Just (Just record) ->
                    [ Element.newTabLink [] { url = record, label = movieButton }, cameraButton ]

                _ ->
                    [ cameraButton ]
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
                [ -- Element.column eventLessAttributes
                  --   [ Element.column [ Element.spacing 10 ] leftButtons
                  --   , Element.el
                  --       (Attributes.designGosTitleAttributes ++ dragAttributes)
                  --       (Element.text (String.fromInt (gosIndex + 1)))
                  --   , Element.column
                  --       [ Element.spacing 10 ]
                  --       [ lockButton
                  --       , Ui.trashButton (Just (Preparation.GosDelete gosIndex)) ""
                  --           |> Element.map LoggedIn.PreparationMsg
                  --           |> Element.map Core.LoggedInMsg
                  --       ]
                  --   ],
                  Element.el (Element.spacing 20 :: Element.width Element.fill :: Attributes.designAttributes ++ eventLessAttributes) slides
                ]



-- SLIDES VIEWS


slideGhostView : Core.Global -> Preparation.UploadExtraResourceForm -> Preparation.ReplaceSlideForm -> DnDList.Groups.Model -> List Preparation.MaybeSlide -> Element Core.Msg
slideGhostView global uploadForm replaceSlideForm slideModel slides =
    case maybeDragSlide slideModel slides of
        Preparation.JustSlide s _ ->
            genericDesignSlideView global uploadForm replaceSlideForm Ghost slideModel 0 0 (Preparation.JustSlide s -1)

        _ ->
            Element.none


designSlideView : Core.Global -> Preparation.UploadExtraResourceForm -> Preparation.ReplaceSlideForm -> Bool -> DnDList.Groups.Model -> Int -> Int -> Preparation.MaybeSlide -> Element Core.Msg
designSlideView global uploadForm replaceSlideForm enabled slideModel offset localIndex slide =
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
    genericDesignSlideView global uploadForm replaceSlideForm t slideModel offset localIndex slide


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


genericDesignSlideView : Core.Global -> Preparation.UploadExtraResourceForm -> Preparation.ReplaceSlideForm -> DragOptions -> DnDList.Groups.Model -> Int -> Int -> Preparation.MaybeSlide -> Element Core.Msg
genericDesignSlideView global extraResourceForm replaceSlideForm options slideModel offset localIndex s =
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

        Preparation.JustSlide slide index ->
            let
                -- TODO computing the gosid this way is ugly af
                gosIndex : Int
                gosIndex =
                    (index - 1) // 2

                -- secondColumn =
                --     genrericDesignSlide2ndColumnView global eventLessAttributes slide extraResourceForm gosIndex replaceSlideForm
                filename =
                    case extraResourceForm.file of
                        Nothing ->
                            "No file selected"

                        Just realFile ->
                            File.name realFile

                messageExtra =
                    case extraResourceForm.activeSlideId of
                        Just x ->
                            if x == slide.id then
                                case extraResourceForm.status of
                                    Status.Sent ->
                                        Ui.messageWithSpinner
                                            ("Téléchargement et transcodage en cours de  \n " ++ filename)

                                    Status.Error () ->
                                        Ui.errorModal "Echec du transcodage de la video. Merci de nous contacter"

                                    Status.Success () ->
                                        Ui.successModal "Upload et transcodage de la video réussis"

                                    _ ->
                                        Element.none

                            else
                                Element.none

                        Nothing ->
                            Element.none

                messageReplace =
                    case replaceSlideForm.ractiveSlideId of
                        Just x ->
                            if x == slide.id then
                                case replaceSlideForm.status of
                                    Status.Sent ->
                                        Ui.messageWithSpinner
                                            "Remplacement de la planche en cours"

                                    Status.Error () ->
                                        Ui.errorModal "Echec du remplacment de la planche. Merci de nous contacter"

                                    Status.Success () ->
                                        Ui.successModal "Remplacement de la planche réussis"

                                    _ ->
                                        Element.none

                            else
                                Element.none

                        Nothing ->
                            Element.none

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
                        [ Ui.imageButton (Just extraResourceMsg) ""
                        , Ui.fontButton (Just promptMsg) ""
                        , Ui.trashButton (Just deleteExtraMsg) ""
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
                            Element.newTabLink [] { url = record, label = Ui.movieButton Nothing "" }

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



--Element.el
--    (Element.htmlAttribute (Html.Attributes.id slideId) :: dropAttributes ++ ghostAttributes)
--    (Element.column
--        Attributes.genericDesignSlideViewAttributes
--        [ Element.el
--            (Element.height
--                (Element.shrink
--                    |> Element.maximum 40
--                    |> Element.minimum 20
--                )
--                :: Element.width Element.fill
--                :: eventLessAttributes
--                ++ dragAttributes
--            )
--          <|
--            Element.el
--                [ Font.size 22
--                , Element.centerX
--                , Font.color Colors.artEvening
--                ]
--                Element.none
--        , messageExtra
--        , messageReplace
--        , Element.row
--            [ Element.spacingXY 2 0 ]
--            [ genrericDesignSlide1stColumnView (eventLessAttributes ++ dragAttributes) slide gosIndex
--            , secondColumn
--            ]
--        ]
--    )


tabEl : Preparation.Tab -> Preparation.Tab -> Element Core.Msg
tabEl tab selectedTab =
    let
        isSelected =
            tab == selectedTab

        paddingOffset =
            if isSelected then
                0

            else
                2

        borderWidths =
            if isSelected then
                { left = 2, top = 2, right = 2, bottom = 0 }

            else
                { bottom = 2, top = 0, left = 0, right = 0 }

        corners =
            if isSelected then
                { topLeft = 6, topRight = 6, bottomLeft = 0, bottomRight = 0 }

            else
                { topLeft = 0, topRight = 0, bottomLeft = 0, bottomRight = 0 }
    in
    Element.el
        [ Border.widthEach borderWidths
        , Border.roundEach corners
        , Border.color Colors.grey
        , Element.mapAttribute Core.LoggedInMsg <|
            Element.mapAttribute LoggedIn.PreparationMsg <|
                Events.onClick (Preparation.UserSelectedTab tab)
        ]
    <|
        Element.el
            [ Element.centerX
            , Element.centerY
            , Element.paddingEach { left = 30, right = 30, top = 10 + paddingOffset, bottom = 10 - paddingOffset }
            ]
        <|
            Element.text <|
                case tab of
                    Preparation.First ->
                        "First"

                    Preparation.Second ->
                        "Second"

                    Preparation.Third ->
                        "Third"


genrericDesignSlide1stColumnView : List (Element.Attribute Core.Msg) -> Api.Slide -> Int -> Element Core.Msg
genrericDesignSlide1stColumnView eventLessAttributes slide gosIndex =
    let
        media =
            case slide.extra of
                Just asset ->
                    Element.html <|
                        htmlVideo asset.asset_path

                Nothing ->
                    viewSlideImage slide.asset.asset_path

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
                    Preparation.UploadExtraResourceMsg <|
                        Preparation.DeleteExtraResource slide.id

        inFront =
            Element.el [ Element.width Element.fill ]
                (Element.row [ Element.padding 10, Element.spacing 10, Element.alignRight ]
                    [ Ui.fontButton (Just promptMsg) ""
                    , Ui.trashButton (Just deleteExtraMsg) ""
                    ]
                )
    in
    Element.el
        (Element.inFront inFront
            :: Element.width Element.fill
            :: eventLessAttributes
        )
        media


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



-- genrericDesignSlide2ndColumnView : Core.Global -> List (Element.Attribute Core.Msg) -> Api.Slide -> Preparation.UploadExtraResourceForm -> Int -> Preparation.ReplaceSlideForm -> Element Core.Msg
-- genrericDesignSlide2ndColumnView global eventLessAttributes slide extraResourceForm gosIndex replaceSlideForm =
--     let
--         promptMsg : Core.Msg
--         promptMsg =
--             Core.LoggedInMsg <|
--                 LoggedIn.PreparationMsg <|
--                     Preparation.EditPromptMsg <|
--                         Preparation.EditPromptOpenDialog slide.id slide.prompt
--
--         deleteExtraMsg : Core.Msg
--         deleteExtraMsg =
--             Core.LoggedInMsg <|
--                 LoggedIn.PreparationMsg <|
--                     Preparation.UploadExtraResourceMsg <|
--                         Preparation.DeleteExtraResource slide.id
--
--         extra =
--             case slide.extra of
--                 Just asset ->
--                     Element.column
--                         [ Element.centerX, Font.center, Element.spacingXY 4 4 ]
--                         [ Element.el [] <|
--                             Element.text asset.name
--                         , Ui.primaryButton
--                             (Just deleteExtraMsg)
--                             "Supprimer la \n ressource vidéo "
--                         ]
--
--                 Nothing ->
--                     Element.column [ Font.size 14, Element.spacing 4 ]
--                         [ Element.column []
--                             [ Element.row []
--                                 [ Ui.trashButton (Just (Preparation.SlideDelete gosIndex slide.id)) ""
--                                     |> Element.map LoggedIn.PreparationMsg
--                                     |> Element.map Core.LoggedInMsg
--                                 , Element.el [ Element.spacingXY 2 4 ] <|
--                                     replaceSlideView replaceSlideForm
--                                         gosIndex
--                                         slide.id
--                                 ]
--                             , Element.el
--                                 [ Element.spacingXY 2 4 ]
--                               <|
--                                 uploadExtraResourceView extraResourceForm slide.id
--                             ]
--                         ]
--
--         prompt =
--             [ Element.el
--                 [ Font.size 14
--                 , Element.centerX
--                 ]
--                 (Element.text "Prompteur")
--             , Element.el
--                 [ Border.rounded 5
--                 , Border.width 2
--                 , Border.color Colors.grey
--                 , Background.color Colors.black
--                 , Element.centerX
--                 , Element.scrollbarY
--                 , Element.height (Element.px 150)
--                 , Element.width (Element.px 150)
--                 , Element.padding 5
--                 , Font.size 12
--                 , Font.color Colors.white
--                 ]
--                 (Element.text slide.prompt)
--             , Element.row []
--                 [ Ui.editButton (Just promptMsg) "Modifier"
--                 , Ui.clearButton Nothing "Effacer"
--                 ]
--             ]
--
--         rows =
--             if global.beta then
--                 extra :: prompt
--
--             else
--                 [ extra ]
--     in
--     Element.column
--         (Element.alignTop
--             :: Element.centerX
--             :: Element.spacing 4
--             :: Element.padding 4
--             :: Element.width
--                 (Element.shrink
--                     |> Element.maximum 300
--                     |> Element.minimum 210
--                 )
--             :: eventLessAttributes
--         )
--         rows


viewSlideImage : String -> Element Core.Msg
viewSlideImage url =
    Element.image
        [ Element.width Element.fill ]
        { src = url, description = "One desc" }



-- configPromptModal : Preparation.EditPrompt -> Dialog.Config Preparation.EditPromptMsg
-- configPromptModal editPromptContent =
--     { closeMessage = Just Preparation.EditPromptCloseDialog
--     , maskAttributes = []
--     , containerAttributes =
--         [ Background.color Colors.white
--         , Border.rounded 5
--         , Element.centerX
--         , Element.padding 10
--         , Element.spacing 20
--         , Element.width (Element.px 600)
--         ]
--     , headerAttributes = [ Font.size 24, Element.padding 5 ]
--     , bodyAttributes = [ Background.color Colors.grey, Element.padding 20, Element.width Element.fill ]
--     , footerAttributes = []
--     , header = Just (Element.text "PROMPTER")
--     , body = Just (bodyPromptModal editPromptContent)
--     , footer = Nothing
--     }


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
    Element.row
        [ Element.spacing 20
        , Element.centerX
        ]
        [ selectFileButton model
        , fileNameElement form.file
        , uploadButton model
        ]



-- uploadExtraResourceView : Preparation.UploadExtraResourceForm -> Int -> Element Core.Msg
-- uploadExtraResourceView form slideId =
--     let
--         text =
--             "Ressource additionelle:"
--
--         buttonSelect =
--             Element.map Core.LoggedInMsg <|
--                 Element.map LoggedIn.PreparationMsg <|
--                     Element.map Preparation.UploadExtraResourceMsg <|
--                         Ui.simpleButton (Just <| Preparation.UploadExtraResourceSelectFileRequested slideId) "Choisir :"
--
--         buttonSubmit =
--             Element.map Core.LoggedInMsg <|
--                 Element.map LoggedIn.PreparationMsg <|
--                     Element.map Preparation.UploadExtraResourceMsg <|
--                         Ui.primaryButton (Just <| Preparation.UploadExtraResourceFormSubmitted slideId) "Envoyer la ressource"
--
--         filename =
--             case form.activeSlideId of
--                 Just x ->
--                     if x == slideId then
--                         fileNameElement form.file
--
--                     else
--                         Element.text "Pas de fichier choisis"
--
--                 Nothing ->
--                     fileNameElement form.file
--     in
--     Element.column
--         [ Element.padding 5
--         , Element.spacing 5
--         ]
--         [ Element.text text
--         , Element.column
--             [ Element.spacing 5
--             , Element.centerX
--             ]
--             [ buttonSelect
--             , filename
--             , buttonSubmit
--             ]
--         ]


replaceSlideView : Preparation.ReplaceSlideForm -> Int -> Int -> Element Core.Msg
replaceSlideView form gosIndex slideId =
    let
        text =
            "Modifier slide"

        buttonSelect =
            Element.map Core.LoggedInMsg <|
                Element.map LoggedIn.PreparationMsg <|
                    Element.map Preparation.ReplaceSlideMsg <|
                        Ui.simpleButton (Just Preparation.ReplaceSlideSelectFileRequested) "Choisir :"

        buttonSubmit =
            Element.map Core.LoggedInMsg <|
                Element.map LoggedIn.PreparationMsg <|
                    Element.map Preparation.ReplaceSlideMsg <|
                        Ui.primaryButton (Just Preparation.ReplaceSlideFormSubmitted) "Envoyer la ressource"

        buttonShow =
            Element.map Core.LoggedInMsg <|
                Element.map LoggedIn.PreparationMsg <|
                    Element.map Preparation.ReplaceSlideMsg <|
                        Ui.primaryButton (Just <| Preparation.ReplaceSlideShowForm gosIndex slideId) "Modifier la planche"

        filename =
            case form.ractiveSlideId of
                Just x ->
                    if x == slideId then
                        fileNameElement form.file

                    else
                        Element.text "Pas de fichier choisis"

                Nothing ->
                    fileNameElement form.file
    in
    if form.hide then
        buttonShow

    else
        case form.ractiveSlideId of
            Just x ->
                if x == slideId then
                    Element.column
                        [ Element.padding 5
                        , Element.spacing 5
                        ]
                        [ Element.text text
                        , Element.column
                            [ Element.spacing 5
                            , Element.centerX
                            ]
                            [ buttonSelect
                            , filename
                            , buttonSubmit
                            ]
                        ]

                else
                    buttonShow

            Nothing ->
                buttonShow


fileNameElement : Maybe File -> Element Core.Msg
fileNameElement file =
    Element.text <|
        case file of
            Nothing ->
                ""

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
