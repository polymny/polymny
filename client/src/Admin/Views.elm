module Admin.Views exposing (..)

import Admin.Types as Admin
import Capsule exposing (Capsule)
import Core.HomeView as Home
import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import FontAwesome as Fa
import Lang exposing (diskUsage)
import Route
import Status
import Ui.Colors as Colors
import Ui.Utils as Ui
import User as ModUser
import Utils exposing (checkEmail)


view : Core.Global -> Admin.Model -> ( Element Core.Msg, Maybe (Element Core.Msg) )
view global model =
    let
        page =
            model.page

        ( content, popup ) =
            case page of
                Admin.Dashboard ->
                    ( dashboardView global model.users model.capsules, Nothing )

                Admin.UsersPage p ->
                    ( usersView global model p, Nothing )

                Admin.UserPage u ->
                    userView global u

                Admin.CapsulesPage p ->
                    ( capsulesView global model p, Nothing )
    in
    ( Element.el [ Ui.wf, Ui.hf ] content, popup )


dashboardView : Core.Global -> List Admin.User -> List Capsule -> Element Core.Msg
dashboardView _ _ _ =
    Element.column [ Element.spacing 30, Ui.wf, Ui.hf ]
        [ Element.el [ Font.bold, Font.size 24, Element.centerX, Element.padding 50 ] <| Element.text "Ici on affichera des stats"
        , Element.el [ Element.centerX ] (Ui.primaryButton { onPress = Just (Core.AdminMsg Admin.ClearWebockets), label = Element.text "Clear websockets" })
        ]


shortUsersView : Core.Global -> List Capsule.User -> Element Core.Msg
shortUsersView global users =
    let
        uView u =
            Element.paragraph []
                [ Element.el [] <| Element.text u.username
                , Element.text " : "
                , Element.text (Lang.roleView global.lang u.role)
                ]
    in
    Element.column [ Ui.wf ] (List.map uView users)


usersView : Core.Global -> Admin.Model -> Int -> Element Core.Msg
usersView global model p =
    let
        lang =
            global.lang

        table =
            Element.table [ Ui.wf ]
                { data = model.users
                , columns =
                    [ { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.userId global.lang))
                      , width = Element.fill
                      , view =
                            \u ->
                                Element.el [] <| Element.text <| String.fromInt u.id
                      }
                    , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.username global.lang))
                      , width = Element.fill
                      , view = usernameView global
                      }
                    , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.emailAddress global.lang))
                      , width = Element.fill
                      , view =
                            \u ->
                                Element.el [] <| Element.text u.inner.email
                      }
                    , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.userPlan global.lang))
                      , width = Element.fill
                      , view =
                            \u ->
                                Element.el [] <| Element.text <| ModUser.printPlan u.inner.plan
                      }
                    , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.activatedUser global.lang))
                      , width = Element.fill
                      , view =
                            \u ->
                                Element.el [] <| Element.text <| stringFromBool <| u.activated
                      }
                    , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.nbCapsules global.lang))
                      , width = Element.fill
                      , view =
                            \u ->
                                List.map (\x -> List.length x.capsules) u.inner.projects
                                    |> List.sum
                                    |> String.fromInt
                                    |> Element.text
                                    |> Element.el []
                      }
                    , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.diskUsage global.lang))
                      , width = Element.fill
                      , view =
                            \u ->
                                List.map
                                    (\x ->
                                        x.capsules
                                            |> List.filter (\y -> y.role == Capsule.Owner)
                                            |> List.map .diskUsage
                                            |> List.sum
                                    )
                                    u.inner.projects
                                    |> List.sum
                                    |> String.fromInt
                                    |> Element.text
                                    |> Element.el []
                      }
                    , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.actions global.lang))
                      , width = Element.shrink
                      , view = actionsView global
                      }
                    ]
                }

        msg =
            case model.usernameSearchStatus of
                Status.Sent ->
                    Nothing

                _ ->
                    Just <| Core.AdminMsg Admin.UserSearchSubmitted

        submitOnEnter =
            case msg of
                Just m ->
                    [ Ui.onEnter m ]

                _ ->
                    []

        inputs =
            Element.row [ Ui.wf, Ui.hf, Element.padding 10 ]
                [ Element.el [ Ui.hf, Ui.wfp 1 ] Element.none
                , Element.row [ Element.spacing 20, Ui.hf, Ui.wfp 2 ]
                    [ Input.text submitOnEnter
                        { onChange = \x -> Core.AdminMsg (Admin.UsernameSearchChanged x)
                        , text = Maybe.withDefault "" model.usernameSearch
                        , placeholder = Nothing
                        , label = Input.labelAbove Ui.formTitle (Element.text (Lang.username global.lang))
                        }
                    , Input.text submitOnEnter
                        { onChange = \x -> Core.AdminMsg (Admin.EmailSearchChanged x)
                        , text = Maybe.withDefault "" model.emailSearch
                        , placeholder = Nothing
                        , label = Input.labelAbove Ui.formTitle (Element.text (Lang.emailAddress global.lang))
                        }
                    ]
                , Element.el [ Ui.wf, Ui.wfp 1 ] Element.none
                ]

        buttons =
            Element.row [ Ui.hf, Element.spacing 10 ]
                [ Ui.link [] { route = Route.Admin (Route.Users (p - 1)), label = Element.text (Lang.prev lang) }
                , Element.el [] <| Element.text <| String.fromInt p
                , Ui.link [] { route = Route.Admin (Route.Users (p + 1)), label = Element.text (Lang.next lang) }
                ]
    in
    Element.column [ Ui.wf, Ui.hf, Element.centerX, Element.alignTop ]
        [ inviteUsersView global model
        , Element.row [ Element.width Element.fill, Element.centerX, Element.alignTop ]
            [ Element.el [ Ui.wfp 1 ] Element.none
            , buttons
            , inputs
            , Element.el [ Ui.wfp 1 ] Element.none
            ]
        , Element.el [ Ui.wfp 1, Ui.hf ] Element.none
        , Element.column [ Element.spacing 10, Ui.wfp 6, Ui.hf ]
            [ Element.el [ Ui.wf ] table
            ]
        , Element.el [ Ui.wfp 1 ] Element.none
        ]


capsulesView : Core.Global -> Admin.Model -> Int -> Element Core.Msg
capsulesView global { capsules, capsuleSearch, projectSearch, capsuleSearchStatus } p =
    let
        lang =
            global.lang

        table =
            Element.table [ Ui.wf ]
                { data = capsules
                , columns =
                    [ { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.capsuleId global.lang))
                      , width = Element.fill
                      , view =
                            \c ->
                                Element.el [] <| Element.text <| c.id
                      }
                    , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.capsuleName global.lang))
                      , width = Element.fill
                      , view =
                            \c ->
                                Element.el [] <| Element.text c.name
                      }
                    , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.projectName global.lang))
                      , width = Element.fill
                      , view =
                            \c ->
                                Element.el [] <| Element.text c.project
                      }
                    , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.users global.lang))
                      , width = Element.shrink
                      , view =
                            \c ->
                                shortUsersView global c.users
                      }
                    , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.lastModified global.lang))
                      , width = Element.fill
                      , view =
                            \c ->
                                Home.lastModifiedView global (Home.Capsule c)
                      }
                    , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.diskUsage global.lang))
                      , width = Element.fill
                      , view =
                            \c ->
                                Home.diskUsageView global (Home.Capsule c)
                      }
                    , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.progress global.lang))
                      , width = Element.shrink
                      , view =
                            \c ->
                                Home.progressView global (Home.Capsule c)
                      }
                    , { header = Element.el [ Element.padding 10 ] Element.none
                      , width = Element.fill
                      , view =
                            \c ->
                                Home.progressIconsView global (Home.Capsule c)
                      }
                    , { header = Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.actions global.lang))
                      , width = Element.shrink
                      , view = capsuleActionsView global
                      }
                    ]
                }

        msg =
            case capsuleSearchStatus of
                Status.Sent ->
                    Nothing

                _ ->
                    Just <| Core.AdminMsg Admin.CapsuleSearchSubmitted

        submitOnEnter =
            case msg of
                Just m ->
                    [ Ui.onEnter m ]

                _ ->
                    []

        inputs =
            Element.row [ Ui.wf, Ui.hf, Element.padding 10 ]
                [ Element.el [ Ui.hf, Ui.wfp 1 ] Element.none
                , Element.row [ Element.spacing 20, Ui.hf, Ui.wfp 2 ]
                    [ Input.text submitOnEnter
                        { onChange = \x -> Core.AdminMsg (Admin.CapsuleSearchChanged x)
                        , text = Maybe.withDefault "" capsuleSearch
                        , placeholder = Nothing
                        , label = Input.labelAbove Ui.formTitle (Element.text (Lang.capsuleName global.lang))
                        }
                    , Input.text submitOnEnter
                        { onChange = \x -> Core.AdminMsg (Admin.ProjectSearchChanged x)
                        , text = Maybe.withDefault "" projectSearch
                        , placeholder = Nothing
                        , label = Input.labelAbove Ui.formTitle (Element.text (Lang.projectName global.lang))
                        }
                    ]
                , Element.el [ Ui.wf, Ui.wfp 1 ] Element.none
                ]

        buttons =
            Element.row [ Ui.hf, Element.spacing 10 ]
                [ Ui.link [] { route = Route.Admin (Route.Capsules (p - 1)), label = Element.text (Lang.prev lang) }
                , Element.el [] <| Element.text <| String.fromInt p
                , Ui.link [] { route = Route.Admin (Route.Capsules (p + 1)), label = Element.text (Lang.next lang) }
                ]
    in
    Element.column [ Ui.wf, Ui.hf, Element.centerY ]
        [ Element.row [ Element.width Element.fill, Element.centerY ]
            [ Element.el [ Ui.wfp 1 ] Element.none
            , buttons
            , inputs
            , Element.el [ Ui.wfp 1 ] Element.none
            ]
        , Element.el [ Ui.wfp 1, Ui.hf ] Element.none
        , Element.column [ Element.spacing 10, Ui.wfp 6, Ui.hf ]
            [ Element.el [ Ui.wf ] table
            ]
        , Element.el [ Ui.wfp 1 ] Element.none
        ]


userView : Core.Global -> Admin.User -> ( Element Core.Msg, Maybe (Element Core.Msg) )
userView global u =
    let
        ( element, message ) =
            if not (List.isEmpty u.inner.projects) then
                -- TODO this wont allow admin to change capsule names
                Home.view global u.inner Core.newHomeModel (\x -> Core.AdminMsg (Admin.ToggleFold x))

            else
                ( Element.none, Nothing )
    in
    ( Element.column []
        [ userViewDetails global u
        , element
        ]
    , message
    )


userViewDetails : Core.Global -> Admin.User -> Element Core.Msg
userViewDetails global u =
    Element.row [ Element.alignTop, Element.padding 10, Element.spacing 10 ]
        [ Element.column [ Element.width Element.fill, Element.spacing 5 ]
            [ Element.row []
                [ Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.userId global.lang))
                , Element.el [] <| Element.text <| String.fromInt u.id
                ]
            , Element.row []
                [ Element.el [ Element.padding 10, Font.bold ] (Element.text (Lang.username global.lang))
                , Element.text u.inner.username
                ]
            , Input.email []
                { label = Input.labelLeft [ Element.padding 10, Font.bold ] (Element.text (Lang.emailAddress global.lang))
                , onChange = \_ -> Core.Noop
                , placeholder = Just (Input.placeholder [] (Element.text (Lang.emailAddress global.lang)))
                , text = u.inner.email
                }
            , Input.radio
                [ Element.spacing 10, Element.padding 10 ]
                { onChange = \_ -> Core.Noop
                , selected = Just u.inner.plan
                , label = Input.labelLeft [ Element.padding 10, Font.bold ] (Element.text (Lang.userPlan global.lang))
                , options =
                    [ Input.option ModUser.Free (Element.text <| ModUser.printPlan ModUser.Free)
                    , Input.option ModUser.Admin (Element.text <| ModUser.printPlan ModUser.Admin)
                    ]
                }
            , Input.checkbox []
                { label = Input.labelLeft [ Element.padding 10, Font.bold ] (Element.text (Lang.activatedUser global.lang))
                , onChange = \_ -> Core.Noop
                , checked = u.activated
                , icon = Input.defaultCheckbox
                }
            , Input.checkbox []
                { label = Input.labelLeft [ Element.padding 10, Font.bold ] (Element.text (Lang.newsletter global.lang))
                , onChange = \_ -> Core.Noop
                , checked = u.newsletterSubscribed
                , icon = Input.defaultCheckbox
                }
            ]
        , Element.column [ Element.alignTop ]
            [ Ui.primaryButton
                { onPress = Nothing, label = Element.text (Lang.resetPassword global.lang) }
            ]
        ]


stringFromBool : Bool -> String
stringFromBool value =
    if value then
        "True"

    else
        "False"


iconButton onPress icon text tooltip =
    Ui.iconButton [ Font.color Colors.navbar ]
        { onPress = onPress
        , icon = icon
        , text = text
        , tooltip = Just tooltip
        }


usernameView : Core.Global -> Admin.User -> Element Core.Msg
usernameView global u =
    Ui.link
        (Element.mouseOver [ Background.color Colors.navbarOver ] :: Font.color Colors.black :: Element.padding 13 :: [ Ui.hf, Element.padding 5 ])
        { route = Route.Admin (Route.User u.id), label = Element.text u.inner.username }


actionsView : Core.Global -> Admin.User -> Element Core.Msg
actionsView global user =
    let
        deleteUserMsg =
            Just <| Core.AdminMsg <| Admin.RequestDeleteUser user
    in
    Element.row [ Element.spacing 10, Element.centerY ]
        [ iconButton Nothing Fa.pen Nothing (Lang.editUser global.lang)
        , iconButton deleteUserMsg Fa.trash Nothing (Lang.deleteUser global.lang)
        ]


capsuleActionsView : Core.Global -> Capsule -> Element Core.Msg
capsuleActionsView global capsule =
    Element.row [ Element.spacing 10, Element.centerY ]
        [ iconButton Nothing Fa.pen Nothing (Lang.editUser global.lang)
        , iconButton Nothing Fa.trash Nothing (Lang.deleteUser global.lang)
        ]


inviteUsersView : Core.Global -> Admin.Model -> Element Core.Msg
inviteUsersView global model =
    let
        lang =
            global.lang

        inviteUserModal =
            case ( model.inviteUserStatus, checkEmail model.inviteEmail || model.inviteEmail == "" ) of
                ( _, False ) ->
                    let
                        s =
                            Lang.invalidEmail lang

                        content =
                            (String.left 1 s |> String.toUpper) ++ String.dropLeft 1 s
                    in
                    content |> Element.text |> Ui.p |> Ui.error

                ( Status.Success, _ ) ->
                    Lang.mailSent lang |> Element.text |> Ui.p |> Ui.success

                _ ->
                    Element.none

        inviteUserMsg =
            case ( model.inviteUserStatus, checkEmail model.inviteEmail ) of
                ( Status.Sent, _ ) ->
                    Nothing

                ( _, True ) ->
                    Just (Core.AdminMsg Admin.InviteUserConfirm)

                _ ->
                    Nothing

        submitOnEnter =
            case inviteUserMsg of
                Just m ->
                    [ Ui.onEnter m ]

                _ ->
                    []

        inviteUserForm =
            Element.column [ Element.spacing 10 ]
                [ Element.el Ui.formTitle (Element.text (Lang.inviteUser lang))
                , Input.username submitOnEnter
                    { label = Input.labelLeft [] Element.none
                    , onChange = \x -> Core.AdminMsg (Admin.InviteUsernameChanged x)
                    , placeholder = Just (Input.placeholder [] (Element.text (Lang.username lang)))
                    , text = model.inviteUsername
                    }
                , Input.email submitOnEnter
                    { label = Input.labelAbove Ui.labelAttr (Element.text (Lang.emailAddress lang))
                    , onChange = \x -> Core.AdminMsg (Admin.InviteEmailChanged x)
                    , placeholder = Just (Input.placeholder [] (Element.text (Lang.emailAddress lang)))
                    , text = model.inviteEmail
                    }
                , inviteUserModal
                , Element.el [ Element.centerX ]
                    (case ( model.inviteUserStatus, inviteUserMsg ) of
                        ( Status.Sent, _ ) ->
                            Ui.primaryButton { onPress = Nothing, label = Ui.spinner }

                        ( _, Just _ ) ->
                            Ui.primaryButton { onPress = inviteUserMsg, label = Element.text (Lang.confirm lang) }

                        _ ->
                            Element.none
                    )
                ]
    in
    Element.row [ Ui.wf, Ui.hf, Element.padding 10 ]
        [ Element.el [ Ui.hf, Ui.wfp 1 ] Element.none
        , Element.column [ Element.spacing 20, Ui.hf, Ui.wfp 2 ]
            [ Ui.horizontalDelimiter
            , inviteUserForm
            , Ui.horizontalDelimiter
            ]
        , Element.el [ Ui.wf, Ui.wfp 1 ] Element.none
        ]
