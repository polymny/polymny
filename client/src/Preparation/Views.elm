module Preparation.Views exposing (view)

{-| The main view for the preparation page.

@docs view

-}

import App.Types as App
import Config exposing (Config)
import Data.Capsule as Data
import Data.User exposing (User)
import DnDList
import DnDList.Groups
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Lang exposing (Lang)
import List.Extra
import Material.Icons as Icons
import Preparation.Types as Preparation
import RemoteData
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Utils as Ui
import Utils


{-| The view function for the preparation page.
-}
view : Config -> User -> Preparation.Model -> ( Element App.Msg, Element App.Msg )
view config user model =
    let
        lang =
            config.clientState.lang

        inFront : Element App.Msg
        inFront =
            maybeDragSlide model.slideModel model.slides
                |> Maybe.map (\x -> slideView config user model True x (Just x))
                |> Maybe.withDefault Element.none

        makeBorder : Element.Color -> Element App.Msg -> Element App.Msg
        makeBorder c elt =
            elt
                |> Element.el [ Ui.p 10, Background.color c, Ui.r 10 ]
                |> Element.el [ Ui.ab, Ui.ar, Ui.p 10 ]

        popup : Element App.Msg
        popup =
            case ( ( model.deleteSlide, model.changeSlideForm ), ( model.editPrompt, model.capsuleUpdate ) ) of
                ( ( Just s, _ ), _ ) ->
                    deleteSlideConfirmPopup lang model s

                ( ( _, Just f ), _ ) ->
                    selectPageNumberPopup lang model f

                ( _, ( Just s, _ ) ) ->
                    promptPopup lang model s

                _ ->
                    Element.none

        -- ( _, RemoteData.Loading _ ) ->
        --     makeBorder Colors.yellow (Element.text "Saving")
        -- ( _, RemoteData.Failure _ ) ->
        --     makeBorder Colors.yellow (Element.text "Error")
        -- ( _, RemoteData.Success () ) ->
        --     makeBorder Colors.green1 (Element.text "Success")
    in
    ( model.slides
        |> List.Extra.gatherWith (\a b -> a.totalGosId == b.totalGosId)
        |> filterConsecutiveVirtualGos
        |> List.map (gosView config user model)
        |> Element.column [ Element.spacing 10, Ui.wf, Ui.hf, Element.inFront inFront ]
    , popup
    )


{-| Displays a grain.
-}
gosView : Config -> User -> Preparation.Model -> ( Preparation.Slide, List Preparation.Slide ) -> Element App.Msg
gosView config user model ( head, gos ) =
    let
        isDragging =
            maybeDragSlide model.slideModel model.slides /= Nothing

        last =
            neListLast ( head, gos )

        addSlide =
            case ( head.slide, gos ) of
                ( Nothing, [] ) ->
                    -- Virtual gos, the button will create a new gos
                    Ui.primaryIcon [ Ui.cy ]
                        { icon = Icons.add
                        , action = mkUiExtra (Preparation.Select (Preparation.AddGos (head.totalGosId // 2)))
                        , tooltip = Strings.stepsPreparationCreateGrain config.clientState.lang
                        }

                _ ->
                    -- Real gos, the button will add a slide at the end of the gos
                    Ui.primaryIcon [ Ui.cy ]
                        { icon = Icons.add
                        , action = mkUiExtra (Preparation.Select (Preparation.AddSlide head.gosId))
                        , tooltip = Strings.stepsPreparationAddSlide config.clientState.lang
                        }

        content =
            case ( head.slide, gos, isDragging ) of
                ( Nothing, [], False ) ->
                    -- Virtual gos
                    Element.none
                        |> Element.el [ Ui.wf, Ui.bt 1, Border.color Colors.greyBorder ]
                        |> Element.el
                            (Ui.wf
                                :: Ui.p 20
                                :: Ui.id ("slide-" ++ String.fromInt head.totalSlideId)
                                :: slideStyle model.slideModel head.totalSlideId Drop
                            )
                        |> Element.el [ Ui.wf, Ui.id ("gos-" ++ String.fromInt head.totalGosId) ]

                ( Nothing, [], True ) ->
                    -- Virtual gos
                    Element.none
                        |> Element.el [ Ui.wf, Ui.p 15 ]
                        |> Element.el [ Ui.wf, Ui.bt 1, Border.color (Colors.grey 6), Background.color (Colors.grey 6) ]
                        |> Element.el
                            (Ui.wf
                                :: Ui.p 5
                                :: Ui.id ("slide-" ++ String.fromInt head.totalSlideId)
                                :: slideStyle model.slideModel head.totalSlideId Drop
                            )
                        |> Element.el [ Ui.wf, Ui.id ("gos-" ++ String.fromInt head.totalGosId) ]

                _ ->
                    (head :: gos)
                        |> List.filter (\x -> x.slide /= Nothing)
                        |> Utils.regroupFixed config.clientConfig.zoomLevel
                        |> List.map (List.map (slideView config user model False last))
                        |> List.map (Element.row [ Ui.wf ])
                        |> Element.column [ Ui.wf, Ui.s 10, Ui.id ("gos-" ++ String.fromInt head.totalGosId) ]
    in
    Element.row [ Ui.s 10, Ui.wf, Ui.pr 20 ] [ content, addSlide ]


{-| Displays a slide.
-}
slideView : Config -> User -> Preparation.Model -> Bool -> Preparation.Slide -> Maybe Preparation.Slide -> Element App.Msg
slideView config user model ghost default s =
    let
        lang =
            config.clientState.lang
    in
    case ( s, Maybe.andThen .slide s ) of
        ( Just slide, Just dataSlide ) ->
            let
                inFrontLabel =
                    Strings.dataCapsuleGrain lang 1
                        ++ " "
                        ++ String.fromInt (slide.gosId + 1)
                        ++ " / "
                        ++ Strings.dataCapsuleSlide lang 1
                        ++ " "
                        ++ String.fromInt (slide.slideId + 1)
                        |> Element.text
                        |> Element.el [ Ui.p 5, Ui.rbr 5, Background.color Colors.greyBorder ]
                        |> Utils.tern ghost Element.none

                inFrontButtons =
                    Element.row [ Ui.s 10, Ui.p 10, Ui.at, Ui.ar ]
                        [ Ui.primaryIcon []
                            { icon = Icons.speaker_notes
                            , tooltip = Strings.actionsEditPrompt lang
                            , action = mkUiMsg (Preparation.EditPrompt dataSlide)
                            }
                        , Ui.primaryIcon []
                            { icon = Icons.image
                            , tooltip = Strings.stepsPreparationReplaceSlideOrAddExternalResource lang
                            , action = mkUiExtra (Preparation.Select (Preparation.ReplaceSlide dataSlide))
                            }
                        , Ui.primaryIcon []
                            { icon = Icons.delete
                            , tooltip = Strings.actionsDeleteSlide lang
                            , action = mkUiMsg (Preparation.DeleteSlide Utils.Request dataSlide)
                            }
                        ]
            in
            Element.el
                [ Ui.wf
                , Ui.pl 20
                , Ui.id ("slide-" ++ String.fromInt slide.totalSlideId)
                , Element.inFront inFrontButtons
                ]
                (Element.image
                    (Ui.wf
                        :: Ui.b 1
                        :: Border.color Colors.greyBorder
                        :: Element.inFront inFrontLabel
                        :: slideStyle model.slideModel slide.totalSlideId Drag
                        ++ slideStyle model.slideModel slide.totalSlideId Drop
                        ++ Utils.tern ghost (slideStyle model.slideModel slide.totalSlideId Ghost) []
                    )
                    { src = Data.slidePath model.capsule dataSlide
                    , description = ""
                    }
                )

        ( Just _, _ ) ->
            Element.none

        _ ->
            Element.el (Ui.wf :: Ui.hf :: Ui.pl 20 :: slideStyle model.slideModel default.totalSlideId Drop) Element.none


{-| Popup to confirm the slide deletion.
-}
deleteSlideConfirmPopup : Lang -> Preparation.Model -> Data.Slide -> Element App.Msg
deleteSlideConfirmPopup lang model s =
    Element.column [ Ui.wf, Ui.hf ]
        [ Element.paragraph [ Ui.wf, Ui.cy, Font.center ]
            [ Element.text (Lang.question Strings.actionsConfirmDeleteSlide lang) ]
        , Element.row [ Ui.ab, Ui.ar, Ui.s 10 ]
            [ Ui.secondary []
                { action = mkUiMsg (Preparation.DeleteSlide Utils.Cancel s)
                , label = Strings.uiCancel lang
                }
            , Ui.primary []
                { action = mkUiMsg (Preparation.DeleteSlide Utils.Confirm s)
                , label = Strings.uiConfirm lang
                }
            ]
        ]
        |> Ui.popup 1 (Strings.actionsDeleteSlide lang)


{-| Popup to input prompt texts.
-}
promptPopup : Lang -> Preparation.Model -> Data.Slide -> Element App.Msg
promptPopup lang model slide =
    Element.row [ Ui.wf, Ui.hf, Ui.s 10 ]
        [ Element.column [ Ui.wf, Ui.cy ]
            [ Element.image [ Ui.wf ]
                { description = Strings.dataCapsuleSlide lang 1
                , src = Data.slidePath model.capsule slide
                }
            ]
        , Element.column [ Ui.wf, Ui.hf, Ui.s 10 ]
            [ Input.multiline [ Ui.wf, Ui.hf ]
                { label = Input.labelHidden (Strings.actionsEditPrompt lang)
                , onChange = \x -> mkMsg (Preparation.PromptChanged Utils.Request { slide | prompt = x })
                , placeholder = Nothing
                , text = slide.prompt
                , spellcheck = False
                }
            , Element.row [ Ui.ar, Ui.s 10 ]
                [ Ui.secondary []
                    { label = Strings.uiCancel lang
                    , action = mkUiMsg (Preparation.PromptChanged Utils.Cancel slide)
                    }
                , Ui.primary []
                    { label = Strings.uiConfirm lang
                    , action = mkUiMsg (Preparation.PromptChanged Utils.Confirm slide)
                    }
                ]
            ]
        ]
        |> Ui.popup 5 (Strings.actionsEditPrompt lang)


{-| Popup to select the page number when uploading a slide.
-}
selectPageNumberPopup : Lang -> Preparation.Model -> Preparation.ChangeSlideForm -> Element App.Msg
selectPageNumberPopup lang model f =
    let
        page =
            case String.toInt f.page of
                Just x ->
                    if x > 0 then
                        Just x

                    else
                        Nothing

                _ ->
                    Nothing

        title =
            case f.slide of
                Preparation.ReplaceSlide _ ->
                    Strings.stepsPreparationReplaceSlideOrAddExternalResource

                Preparation.AddSlide _ ->
                    Strings.stepsPreparationAddSlide

                Preparation.AddGos _ ->
                    Strings.stepsPreparationCreateGrain

        textLabel =
            Lang.question Strings.stepsPreparationWhichPage lang

        textInput =
            Input.text [ Ui.wf, Ui.cy ]
                { label = Input.labelAbove [] (Element.text textLabel)
                , onChange = \x -> mkExtra (Preparation.PageChanged x)
                , placeholder = Nothing
                , text = f.page
                }

        errorMsg =
            case model.changeSlide of
                RemoteData.Failure _ ->
                    Element.paragraph [ Ui.wf, Ui.cy ]
                        [ Element.text (Lang.question Strings.stepsPreparationMaybePageNumberIsIncorrect lang) ]

                _ ->
                    Element.none

        buttonBar =
            Element.row [ Ui.ab, Ui.ar, Ui.s 10 ]
                (case model.changeSlide of
                    RemoteData.Loading _ ->
                        [ Ui.primaryGeneric [] { action = Ui.None, label = Ui.spinningSpinner [] 24 } ]

                    _ ->
                        [ Ui.secondary []
                            { action = mkUiExtra Preparation.PageCancel
                            , label = Strings.uiCancel lang
                            }
                        , case page of
                            Just p ->
                                Ui.primary []
                                    { action = mkUiExtra (Preparation.Selected f.slide f.file (Just p))
                                    , label = Strings.uiConfirm lang
                                    }

                            _ ->
                                Element.text (Strings.stepsPreparationInsertNumberGreaterThanZero lang)
                        ]
                )
    in
    Element.column [ Ui.wf, Ui.hf ]
        [ textInput
        , errorMsg
        , buttonBar
        ]
        |> Ui.popup 1 (title lang)


{-| Finds whether a slide is being dragged.
-}
maybeDragSlide : DnDList.Groups.Model -> List Preparation.Slide -> Maybe Preparation.Slide
maybeDragSlide model slides =
    Preparation.slideSystem.info model
        |> Maybe.andThen (\{ dragIndex } -> slides |> List.drop dragIndex |> List.head)


{-| A helper type to help us deal with the DnD events.
-}
type DragOptions
    = Drag
    | Drop
    | Ghost
    | None


{-| A function that gives the corresponding attributes for slides.
-}
slideStyle : DnDList.Groups.Model -> Int -> DragOptions -> List (Element.Attribute App.Msg)
slideStyle model totalSlideId options =
    (case options of
        Drag ->
            Preparation.slideSystem.dragEvents totalSlideId ("slide-" ++ String.fromInt totalSlideId)

        Drop ->
            Preparation.slideSystem.dropEvents totalSlideId ("slide-" ++ String.fromInt totalSlideId)

        Ghost ->
            Preparation.slideSystem.ghostStyles model

        None ->
            []
    )
        |> List.map Element.htmlAttribute
        |> List.map (Element.mapAttribute mkDnD)


{-| An alias to easily describe non empty lists.
-}
type alias NeList a =
    ( a, List a )


{-| A helper to remove consecutive virtual gos.
-}
filterConsecutiveVirtualGos : List (NeList Preparation.Slide) -> List (NeList Preparation.Slide)
filterConsecutiveVirtualGos input =
    filterConsecutiveVirtualGosAux [] input |> List.reverse


{-| Auxilary function to help write filterConsecutiveVirtualGos.
-}
filterConsecutiveVirtualGosAux : List (NeList Preparation.Slide) -> List (NeList Preparation.Slide) -> List (NeList Preparation.Slide)
filterConsecutiveVirtualGosAux acc input =
    case input of
        [] ->
            acc

        h :: [] ->
            h :: acc

        ( h1, [] ) :: ( h2, [] ) :: t ->
            if h1.slide == Nothing && h2.slide == Nothing then
                filterConsecutiveVirtualGosAux acc (( h2, [] ) :: t)

            else
                filterConsecutiveVirtualGosAux (( h1, [] ) :: acc) (( h2, [] ) :: t)

        h1 :: h2 :: t ->
            filterConsecutiveVirtualGosAux (h1 :: acc) (h2 :: t)


{-| Gets the last element of a non empty list.
-}
neListLast : NeList a -> a
neListLast ( h, t ) =
    case t of
        [] ->
            h

        h1 :: t1 ->
            neListLast ( h1, t1 )


{-| Easily creates a preparation msg.
-}
mkMsg : Preparation.Msg -> App.Msg
mkMsg msg =
    App.PreparationMsg msg


{-| Easily creates a dnd msg.
-}
mkDnD : Preparation.DnDMsg -> App.Msg
mkDnD msg =
    App.PreparationMsg (Preparation.DnD msg)


{-| Easily creates a extra msg.
-}
mkExtra : Preparation.ExtraMsg -> App.Msg
mkExtra msg =
    App.PreparationMsg (Preparation.Extra msg)


{-| Easily creates the Ui.Msg for preparation msg.
-}
mkUiMsg : Preparation.Msg -> Ui.Action App.Msg
mkUiMsg msg =
    mkMsg msg |> Ui.Msg


{-| Easily creates the Ui.Msg for dnd msg.
-}
mkUiDnD : Preparation.DnDMsg -> Ui.Action App.Msg
mkUiDnD msg =
    mkDnD msg |> Ui.Msg


{-| Easily creates the Ui.Msg for extra msg.
-}
mkUiExtra : Preparation.ExtraMsg -> Ui.Action App.Msg
mkUiExtra msg =
    mkExtra msg |> Ui.Msg
