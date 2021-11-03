module Ui.LeftColumn exposing (leftColumn)

import Capsule exposing (Capsule)
import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import FontAwesome as Fa
import Html
import Html.Attributes
import Lang
import Route
import Ui.Colors as Colors
import Ui.Utils as Ui


leftColumn : Core.Model -> Capsule -> Element Core.Msg
leftColumn model capsule =
    let
        selectedGos =
            case model.page of
                Core.Acquisition c ->
                    Just c.gos

                Core.Production c ->
                    Just c.gos

                _ ->
                    Nothing
    in
    Element.column
        [ Ui.wf
        , Ui.hf
        , Background.color Colors.whiteTer
        , Border.widthEach { left = 0, right = 1, top = 0, bottom = 0 }
        , Border.color Colors.greyLighter
        , Element.padding 10
        , Element.spacing 10
        ]
        (List.indexedMap (gosView model capsule selectedGos) capsule.structure)


gosView : Core.Model -> Capsule -> Maybe Int -> Int -> Capsule.Gos -> Element Core.Msg
gosView model capsule selected id gos =
    case gos.slides of
        h :: _ ->
            let
                inFront =
                    Element.column [ Ui.wf, Ui.hf ]
                        [ Element.row [ Element.spacing 10, Ui.wf ]
                            [ Ui.link [ Ui.wf, Ui.hf ] { label = Element.none, route = Core.routeFromPage model.page |> Route.goToGos id }
                            , Element.row [ Element.padding 10 ]
                                [ case gos.record of
                                    Just record ->
                                        Ui.iconLink
                                            [ Element.padding 5
                                            , Border.rounded 5
                                            , Background.color Colors.greyLighter
                                            , Font.color Colors.navbar
                                            ]
                                            { route = Route.Custom (Capsule.assetPath capsule (record.uuid ++ ".webm"))
                                            , text = Nothing
                                            , tooltip = Just (Lang.watchRecord model.global.lang)
                                            , icon = Fa.film
                                            }

                                    _ ->
                                        Element.none
                                , Ui.iconLink
                                    [ Element.padding 5
                                    , Border.rounded 5
                                    , Background.color Colors.greyLighter
                                    , Font.color Colors.navbar
                                    ]
                                    { route = Route.Acquisition capsule.id id
                                    , text = Nothing
                                    , tooltip = Just (Lang.recordGos model.global.lang)
                                    , icon = Fa.camera
                                    }
                                ]
                            ]
                        , Ui.link [ Ui.wf, Ui.hf ] { label = Element.none, route = Core.routeFromPage model.page |> Route.goToGos id }
                        ]

                info =
                    Element.el
                        [ Element.alignLeft
                        , Element.alignTop
                        , Element.padding 5
                        , Background.color Colors.greyLighter
                        , Border.roundEach { topLeft = 0, topRight = 0, bottomLeft = 0, bottomRight = 10 }
                        ]
                        (Element.text (Lang.grain model.global.lang ++ " " ++ String.fromInt (id + 1)))
            in
            case List.map .extra gos.slides of
                (Just path) :: [] ->
                    Element.el
                        (Ui.wf
                            :: Element.inFront inFront
                            :: Element.inFront info
                            :: Border.width 1
                            :: Border.color Colors.greyLighter
                            :: Border.width 5
                            :: (if selected == Just id then
                                    [ Border.color Colors.navbar ]

                                else
                                    []
                               )
                        )
                        (Element.html
                            (Html.video
                                [ Html.Attributes.controls False, Html.Attributes.class "wf" ]
                                [ Html.source [ Html.Attributes.src (Capsule.assetPath capsule (path ++ ".mp4")) ] [] ]
                            )
                        )

                _ ->
                    Element.image
                        (Ui.wf
                            :: Element.inFront inFront
                            :: Element.inFront info
                            :: Border.width 1
                            :: Border.color Colors.greyLighter
                            :: Border.width 5
                            :: (if selected == Just id then
                                    [ Border.color Colors.navbar ]

                                else
                                    []
                               )
                        )
                        { src = Capsule.slidePath capsule h, description = "" }

        _ ->
            Element.text "oops"
