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
            case model.capsuleUpdate of
                RemoteData.NotAsked ->
                    Element.none

                RemoteData.Loading _ ->
                    makeBorder Colors.yellow (Element.text "Saving")

                RemoteData.Failure _ ->
                    makeBorder Colors.yellow (Element.text "Error")

                RemoteData.Success () ->
                    makeBorder Colors.green1 (Element.text "Success")
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
    in
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
                |> Element.row [ Ui.wf, Ui.id ("gos-" ++ String.fromInt head.totalGosId) ]


{-| Displays a slide.
-}
slideView : Config -> User -> Preparation.Model -> Bool -> Preparation.Slide -> Maybe Preparation.Slide -> Element App.Msg
slideView config user model ghost default s =
    case ( s, Maybe.andThen .slide s ) of
        ( Just slide, Just dataSlide ) ->
            let
                inFrontLabel =
                    Strings.dataCapsuleGrain config.clientState.lang 1
                        ++ " "
                        ++ String.fromInt (slide.gosId + 1)
                        ++ " / "
                        ++ Strings.dataCapsuleSlide config.clientState.lang 1
                        ++ " "
                        ++ String.fromInt (slide.slideId + 1)
                        |> Element.text
                        |> Element.el [ Ui.p 5, Ui.rbr 5, Background.color Colors.greyBorder ]
                        |> Utils.tern ghost Element.none

                inFrontButtons =
                    Element.row [ Ui.s 10, Ui.p 10, Ui.at, Ui.ar ]
                        [ Ui.primaryIcon []
                            { icon = Icons.delete
                            , tooltip = Strings.actionsDeleteSlide config.clientState.lang
                            , action = Ui.Msg (App.PreparationMsg (Preparation.DeleteSlide Utils.Confirm dataSlide))
                            }
                        ]
            in
            Element.el
                (Ui.wf
                    :: Ui.pl 20
                    :: Ui.id ("slide-" ++ String.fromInt slide.totalSlideId)
                    :: Element.inFront inFrontButtons
                    :: []
                )
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
        |> List.map (Element.mapAttribute (\x -> App.PreparationMsg (Preparation.DnD x)))


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
