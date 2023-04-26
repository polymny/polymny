module NewCapsule.Views exposing (..)

import Capsule exposing (Capsule)
import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Lang
import NewCapsule.Types as NewCapsule
import RemoteData
import Route
import Ui.Colors as Colors
import Ui.Utils as Ui
import User exposing (User)


view : Core.Global -> User -> NewCapsule.Model -> ( Element Core.Msg, Maybe (Element Core.Msg) )
view global user model =
    let
        projectField =
            if model.showProject then
                Input.text []
                    { label = Input.labelAbove [] (Element.text (Lang.projectName global.lang))
                    , onChange = \x -> Core.NewCapsuleMsg (NewCapsule.ProjectChanged x)
                    , text = model.project
                    , placeholder = Nothing
                    }

            else
                Element.none

        capsuleField =
            Input.text []
                { label = Input.labelAbove [] (Element.text (Lang.capsuleName global.lang))
                , onChange = \x -> Core.NewCapsuleMsg (NewCapsule.NameChanged x)
                , text = model.name
                , placeholder = Nothing
                }

        slidesLabel =
            Element.column [ Element.spacing 5 ]
                [ Element.text (Lang.slidesGroup global.lang)
                , Element.el [ Font.size 10 ] (Element.text (Lang.slidesGroupSubtext global.lang))
                ]

        buttons =
            Element.row [ Element.width Element.fill ]
                [ Element.row [ Element.alignLeft ]
                    [ case model.capsule of
                        RemoteData.Success _ ->
                            Ui.simpleButton
                                { onPress = Just (Core.NewCapsuleMsg NewCapsule.Cancel)
                                , label = Element.text (Lang.cancel global.lang)
                                }

                        _ ->
                            Element.none
                    ]
                , case model.capsule of
                    RemoteData.Success _ ->
                        Element.row [ Element.spacing 10, Element.alignRight ]
                            [ Ui.simpleButton
                                { onPress = Just (Core.NewCapsuleMsg NewCapsule.GoToPreparation)
                                , label = Element.text (Lang.prepareSlides global.lang)
                                }
                            , Ui.primaryButton
                                { onPress = Just (Core.NewCapsuleMsg NewCapsule.GoToAcquisition)
                                , label = Element.text (Lang.startRecording global.lang)
                                }
                            ]

                    _ ->
                        Element.none
                ]

        form =
            Element.column
                [ Element.spacing 10, Ui.wf, Ui.hf ]
                [ projectField, capsuleField, slidesLabel, gosView global user model, buttons ]

        errorPopup =
            case model.capsule of
                RemoteData.Failure _ ->
                    Just
                        (Element.row
                            [ Ui.wf, Ui.hf, Background.color Colors.darkTransparent ]
                            [ Element.el [ Ui.wf, Ui.hf ] Element.none
                            , Element.column [ Ui.wf, Ui.hf ]
                                [ Element.el [ Ui.wf, Ui.hf ] Element.none
                                , Element.column [ Ui.wf, Ui.hf ]
                                    [ Element.el [ Ui.wf, Font.color Colors.white, Element.padding 10, Background.color Colors.navbar ]
                                        (Element.el [ Element.centerX, Font.bold ] (Element.text (Lang.error global.lang)))
                                    , Element.column [ Ui.wf, Ui.hf, Background.color Colors.whiteBis ]
                                        [ Element.paragraph [ Font.center, Element.centerX, Element.centerY ]
                                            [ Element.text (Lang.errorUploadingPdf global.lang) ]
                                        , Element.el [ Element.alignBottom, Element.alignRight, Element.padding 10 ]
                                            (Ui.primaryLink { route = Route.Home, label = Element.text (Lang.confirm global.lang) })
                                        ]
                                    ]
                                , Element.el [ Ui.hf ] Element.none
                                ]
                            , Element.el [ Ui.wf, Ui.hf ] Element.none
                            ]
                        )

                _ ->
                    Nothing
    in
    ( Element.row [ Ui.wf, Ui.hf, Element.padding 10 ]
        [ Element.el [ Ui.wfp 1, Ui.hf ] Element.none
        , Element.el [ Ui.wfp 8, Ui.hf ] form
        , Element.el [ Ui.wfp 1, Ui.hf ] Element.none
        ]
    , errorPopup
    )



-- gosView global user model


gosView : Core.Global -> User -> NewCapsule.Model -> Element Core.Msg
gosView _ _ model =
    case model.capsule of
        RemoteData.Success ( capsule, s ) ->
            let
                slides : List (List (Maybe Slide))
                slides =
                    regroupSlides 5 (List.indexedMap (\x y -> ( x, y )) s)

                elements : List (List (Element Core.Msg))
                elements =
                    List.map (\( x, y ) -> buildSlides capsule x y) (prepare slides)
            in
            Element.column
                [ Element.width Element.fill, Element.spacing 10 ]
                (List.map (\x -> Element.row [ Element.width Element.fill ] x) elements)

        _ ->
            Element.el [ Element.padding 10, Element.centerX ] Ui.spinner


type alias Slide =
    ( Int, ( Int, Capsule.Slide ) )


regroupSlides : Int -> List Slide -> List (List (Maybe Slide))
regroupSlides number list =
    case regroupSlidesAux number [] list of
        [] ->
            []

        h :: t ->
            ((List.map Just h ++ List.repeat (number - List.length h) Nothing)
                :: List.map (\x -> List.map Just x) t
            )
                |> List.reverse


regroupSlidesAux : Int -> List (List Slide) -> List Slide -> List (List Slide)
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


prepare : List (List (Maybe Slide)) -> List ( Maybe Slide, List (Maybe Slide) )
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


buildSlides : Capsule -> Maybe Slide -> List (Maybe Slide) -> List (Element Core.Msg)
buildSlides capsule nextSlide input =
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
                    viewSlide capsule (Just ( index1, ( gos1, slide1 ) ))

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
                                        , onPress = Just (Core.NewCapsuleMsg (NewCapsule.SlideClicked index2))
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
                        , onPress = Just (Core.NewCapsuleMsg (NewCapsule.SlideClicked index2))
                        }
            in
            viewSlide capsule (Just ( index1, ( gos1, slide1 ) ))
                :: delimiter
                :: buildSlides capsule nextSlide (Just ( index2, ( gos2, slide2 ) ) :: t)

        (Just ( index1, ( gos1, slide1 ) )) :: Nothing :: t ->
            viewSlide capsule (Just ( index1, ( gos1, slide1 ) ))
                :: emptyPadding
                :: emptyFilling
                :: emptyPadding
                :: buildSlides capsule nextSlide t

        Nothing :: t ->
            emptyFilling
                :: emptyPadding
                :: buildSlides capsule nextSlide t


viewSlide : Capsule -> Maybe Slide -> Element Core.Msg
viewSlide capsule slide =
    case slide of
        Nothing ->
            Element.el [ Element.width Element.fill ] Element.none

        Just ( _, ( _, s ) ) ->
            Element.image
                [ Border.color Colors.grey, Border.width 1, Element.width Element.fill ]
                { description = "", src = Capsule.assetPath capsule (s.uuid ++ ".png") }
