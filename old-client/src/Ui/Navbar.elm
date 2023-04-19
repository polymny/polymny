module Ui.Navbar exposing (navbar)

import Capsule
import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import FontAwesome as Fa
import Lang exposing (Lang)
import Route exposing (Route)
import Ui.Colors as Colors
import Ui.Utils as Ui
import User exposing (User)


link : List (Element.Attribute Core.Msg) -> { route : Route, label : Element Core.Msg } -> Element Core.Msg
link attr { route, label } =
    Ui.link
        (Element.mouseOver [ Background.color Colors.navbarOver ] :: Font.color Colors.white :: Element.padding 13 :: attr)
        { route = route, label = label }


logoutButton : Lang -> Element Core.Msg
logoutButton lang =
    Ui.button
        [ Background.color Colors.white
        , Font.color Colors.greyDarker
        , Font.bold
        , Element.padding 12
        , Border.rounded 50
        , Element.mouseOver [ Font.color Colors.link ]
        ]
        { onPress = Just Core.LogoutClicked, label = Element.text (Lang.logout lang) }


navbar : Core.Global -> Maybe User -> Maybe Core.Page -> Element Core.Msg
navbar global user page =
    let
        lang =
            global.lang

        capsule =
            case page of
                Just (Core.Preparation c) ->
                    Just c.capsule

                Just (Core.Acquisition c) ->
                    Just c.capsule

                Just (Core.Production c) ->
                    Just c.capsule

                Just (Core.Publication c) ->
                    Just c.capsule

                Just (Core.CapsuleSettings c) ->
                    Just c.capsule

                _ ->
                    Nothing

        title =
            case capsule of
                Just c ->
                    Element.text (Ui.shrink 20 c.project ++ " / " ++ Ui.shrink 20 c.name)

                _ ->
                    Element.none

        makeLink : { route : Route, label : Element Core.Msg } -> Element Core.Msg
        makeLink { route, label } =
            let
                pageRoute : Maybe Route
                pageRoute =
                    Maybe.map Core.routeFromPage page

                sameTab : Bool
                sameTab =
                    case pageRoute of
                        Just x ->
                            Route.sameTab x route

                        _ ->
                            False
            in
            if sameTab then
                Element.el
                    [ Ui.hf
                    , Font.color Colors.blackBis
                    , Background.color Colors.whiteBis
                    , Element.padding 5
                    ]
                    (Element.el [ Element.centerY ] label)

            else
                link [ Ui.hf, Element.padding 5 ] { route = route, label = Element.el [ Element.centerY ] label }

        buttons =
            case ( page, capsule ) of
                ( Just (Core.Admin _), _ ) ->
                    Element.row [ Ui.hf, Element.spacing 10 ]
                        [ makeLink { route = Route.Admin Route.Dashboard, label = Element.text (Lang.dashboard lang) }
                        , makeLink { route = Route.Admin (Route.Users 0), label = Element.text (Lang.users lang) }
                        , makeLink { route = Route.Admin (Route.Capsules 0), label = Element.text (Lang.capsules lang) }
                        ]

                ( _, Just c ) ->
                    let
                        gosId =
                            Capsule.firstNonRecordedGos c |> Maybe.withDefault 0
                    in
                    Element.row [ Ui.hf, Element.spacing 10 ]
                        [ makeLink { route = Route.Preparation c.id Nothing, label = Element.text (Lang.prepare lang) }
                        , makeLink { route = Route.Acquisition c.id gosId, label = Element.text (Lang.record lang) }
                        , makeLink { route = Route.Production c.id 0, label = Element.text (Lang.produce lang) }
                        , makeLink { route = Route.Publication c.id, label = Element.text (Lang.publish lang) }
                        , if Maybe.withDefault False (Maybe.map User.isPremium user) then
                            makeLink { route = Route.CapsuleSettings c.id, label = Element.text (Lang.settings lang) }

                          else
                            Element.none
                        ]

                _ ->
                    Element.none

        settings =
            Ui.iconLink [] { route = Route.Settings, icon = Fa.cog, text = Nothing, tooltip = Nothing }

        unreadNotifications =
            Maybe.map .notifications user
                |> Maybe.withDefault []
                |> List.filter (\x -> not x.read)
                |> List.length

        unreadNotificationsInFront =
            let
                size =
                    10
            in
            if unreadNotifications > 0 then
                Element.el
                    [ Element.alignRight
                    , Element.alignBottom
                    , Background.color Colors.danger
                    , Element.width (Element.px size)
                    , Element.height (Element.px size)
                    , Border.rounded (size // 2)
                    , Font.size 8
                    ]
                    (Element.el
                        [ Element.centerX, Element.centerY ]
                        (Element.text (String.fromInt unreadNotifications))
                    )

            else
                Element.none

        notificationIcon =
            Ui.iconButton [ Font.color Colors.white, Element.inFront unreadNotificationsInFront ]
                { icon = Fa.bell
                , onPress = Just Core.ToggleNotificationPanel
                , text = Nothing
                , tooltip = Nothing
                }

        adminIcon =
            if (user |> Maybe.map .plan |> Maybe.withDefault User.Free) == User.Admin then
                Ui.iconLink []
                    { route = Route.Admin Route.Dashboard
                    , icon = Fa.wrench
                    , text = Nothing
                    , tooltip = Nothing
                    }

            else
                Element.none
    in
    Element.row
        (Ui.wf
            :: Background.color Colors.navbar
            :: Font.color Colors.white
            :: Element.spacing 50
            :: Font.size 20
            :: (case user of
                    Just u ->
                        [ Element.below (notificationPanel global u) ]

                    _ ->
                        []
               )
        )
        [ link
            [ Font.bold, Font.size 27 ]
            { route = Route.Home
            , label =
                Element.row [ Element.spacing 10 ]
                    [ Element.image [ Element.height (Element.px 30) ] { src = "/dist/logo.png", description = "Polymny" }
                    , Element.text "Polymny"
                    ]
            }
        , title
        , buttons
        , Element.row [ Element.alignRight, Element.paddingXY 10 0, Element.spacing 10 ]
            (case user of
                Just u ->
                    [ notificationIcon, adminIcon, settings, Element.text u.username, logoutButton lang ]

                _ ->
                    []
            )
        ]


notificationPanel : Core.Global -> User -> Element Core.Msg
notificationPanel global user =
    let
        notifications =
            if List.isEmpty user.notifications then
                [ Element.paragraph [] [ Element.text "Vous n'avez aucune notification." ] ]

            else
                List.indexedMap notificationView user.notifications

        header =
            Element.row
                [ Ui.wf
                , Element.paddingEach
                    { top = 0
                    , bottom = 10
                    , left = 0
                    , right = 0
                    }
                , Font.size 16
                , Font.bold
                ]
                [ Element.text "Notifications"
                , Ui.button [ Element.alignRight ]
                    { label = Element.text "x"
                    , onPress = Just Core.ToggleNotificationPanel
                    }
                ]
    in
    if global.notificationPanelVisible then
        Element.row [ Ui.wf, Element.paddingXY 10 0 ]
            [ Element.el [ Element.width (Element.fillPortion 3) ] Element.none
            , Element.column
                [ Background.color Colors.light
                , Font.color Colors.black
                , Border.width 1
                , Border.color Colors.black
                , Border.rounded 10
                , Element.padding 10
                , Element.alignRight
                , Element.height (Element.maximum 400 Element.fill)
                , Element.scrollbarY
                ]
                (header :: notifications)
            ]

    else
        Element.none


notificationView : Int -> User.Notification -> Element Core.Msg
notificationView _ notification =
    let
        ( icon, fontStyle ) =
            if notification.read then
                ( Element.el [ Font.color Colors.grey ] (Element.text "●"), Font.regular )

            else
                ( Element.el [ Font.color Colors.navbar ] (Element.text "⬤"), Font.bold )

        label =
            Element.row
                [ Font.size 16
                , Element.spacing 5
                , Ui.wf
                , Border.widthEach { top = 1, bottom = 0, left = 0, right = 0 }
                , Border.color Colors.black
                , Element.paddingXY 0 5
                ]
                [ icon
                , Ui.button
                    [ Ui.wf ]
                    { label =
                        Element.column
                            [ Ui.wf
                            , Element.padding 5
                            , Element.spacing 5
                            ]
                            [ Element.paragraph [ fontStyle ] [ Element.text notification.title ]
                            , Element.paragraph [ fontStyle ] [ Element.text notification.content ]
                            ]
                    , onPress = Just (Core.MarkNotificationAsRead notification)
                    }
                , Ui.button [] { label = Element.text "x", onPress = Just (Core.DeleteNotification notification) }
                ]
    in
    label
