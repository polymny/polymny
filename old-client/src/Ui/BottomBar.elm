module Ui.BottomBar exposing (bottomBar)

import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Lang exposing (Lang)
import Route exposing (Route)
import Ui.Colors as Colors
import Ui.Utils as Ui
import User exposing (User)


linkButton : List (Element.Attribute msg) -> { onPress : Maybe msg, label : Element msg } -> Element msg
linkButton attr { onPress, label } =
    Ui.linkButton (Element.mouseOver [ Font.color Colors.white ] :: attr) { onPress = onPress, label = label }


newTabLink : List (Element.Attribute msg) -> { route : Route, label : Element msg } -> Element msg
newTabLink attr { route, label } =
    Ui.newTabLink (Element.mouseOver [ Font.color Colors.white ] :: attr) { route = route, label = label }


bottomBar : (Lang -> msg) -> Core.Global -> Core.Page -> Maybe User -> Element msg
bottomBar langMsg global page user =
    Element.row
        [ Font.color Colors.white
        , Font.size 16
        , Ui.wf
        , Background.color Colors.dark
        , Element.padding 15
        , Element.spacing 10
        ]
        [ newTabLink []
            { route = Route.Custom "mailto:contacter@polymny.studio"
            , label = Element.text "contacter@polymny.studio"
            }
        , Element.row
            [ Element.alignRight
            , Element.spacing 20
            ]
            [ let
                pagePath =
                    case Core.routeFromPage page of
                        Route.Preparation c _ ->
                            "/capsule/preparation/" ++ c ++ "/"

                        Route.Acquisition c id ->
                            "/capsule/acquisition/" ++ c ++ "/" ++ String.fromInt (id + 1) ++ "/"

                        Route.Production c id ->
                            "/capsule/production/" ++ c ++ "/" ++ String.fromInt (id + 1) ++ "/"

                        Route.Publication id ->
                            "/capsule/publication/" ++ id ++ "/"

                        Route.CapsuleSettings c ->
                            "/capsule/preparation/" ++ c ++ "/"

                        Route.Settings ->
                            "/profile/"

                        _ ->
                            ""
              in
              Ui.link []
                { label = Element.el [ Element.mouseOver [ Font.color Colors.whiteBis ] ] <| Element.text <| Lang.goToNewClient global.lang
                , route = Route.Custom <| global.root ++ pagePath
                }
            , newTabLink []
                { route = Route.Custom "https://github.com/polymny/polymny/blob/master/LICENSE"
                , label = Element.text "License GNU Affero V3"
                }
            , case global.home of
                Just home ->
                    newTabLink []
                        { route = Route.Custom (home ++ "/cgu/")
                        , label = Element.text (Lang.conditions global.lang)
                        }

                _ ->
                    Element.none
            , newTabLink []
                { route = Route.Custom "https://github.com/polymny/polymny/"
                , label = Element.text (Lang.source global.lang)
                }
            , linkButton []
                { onPress = Just (langMsg (Lang.other global.lang)), label = Element.text (Lang.view global.lang) }
            , Lang.version global.lang ++ " " ++ global.version |> Element.text
            , case global.commit of
                Just c ->
                    Lang.commit global.lang ++ " " ++ c |> Element.text

                _ ->
                    Element.none
            ]
        ]
