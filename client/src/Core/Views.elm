module Core.Views exposing (subscriptions, view)

import Capsule.Types as Capsule
import Capsule.Views as Capsule
import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Html
import LoggedIn.Types as LoggedIn
import LoggedIn.Views as LoggedIn
import Login.Views as Login
import Preparation.Types as Preparation
import SignUp.Views as SignUp
import Ui.Attributes as Attributes
import Ui.Colors as Colors
import Ui.Ui as Ui


subscriptions : Core.FullModel -> Sub Core.Msg
subscriptions { model } =
    case model of
        Core.LoggedIn { tab } ->
            case tab of
                LoggedIn.Preparation preparationModel ->
                    case preparationModel of
                        Preparation.Capsule { slideModel, gosModel } ->
                            Sub.map
                                (\x ->
                                    Core.LoggedInMsg (LoggedIn.PreparationMsg (Preparation.CapsuleMsg (Capsule.DnD x)))
                                )
                                (Sub.batch
                                    [ Capsule.slideSystem.subscriptions slideModel
                                    , Capsule.gosSystem.subscriptions gosModel
                                    ]
                                )

                        _ ->
                            Sub.none

                _ ->
                    Sub.none

        _ ->
            Sub.none


view : Core.FullModel -> Html.Html Core.Msg
view fullModel =
    Element.layout Attributes.fullModelAttributes (viewContent fullModel)


viewContent : Core.FullModel -> Element Core.Msg
viewContent { global, model } =
    let
        content =
            case model of
                Core.Home ->
                    homeView

                Core.Login loginModel ->
                    Login.view loginModel

                Core.SignUp signUpModel ->
                    SignUp.view signUpModel

                Core.LoggedIn { session, tab } ->
                    LoggedIn.view global session tab

        attributes =
            case model of
                Core.LoggedIn { tab } ->
                    case tab of
                        LoggedIn.Preparation preparationModel ->
                            case preparationModel of
                                Preparation.Capsule { slides, slideModel, gosModel } ->
                                    [ Element.inFront (Capsule.gosGhostView gosModel slideModel (List.concat slides))
                                    , Element.inFront (Capsule.slideGhostView slideModel (List.concat slides))
                                    ]

                                _ ->
                                    []

                        _ ->
                            []

                _ ->
                    []
    in
    Element.column (Element.width Element.fill :: attributes) [ topBar model, content ]


homeView : Element Core.Msg
homeView =
    Element.column [ Element.alignTop, Element.padding 10, Element.width Element.fill ] [ Element.text "Home" ]


topBar : Core.Model -> Element Core.Msg
topBar model =
    case model of
        Core.LoggedIn { tab } ->
            case tab of
                LoggedIn.Preparation preparationModel ->
                    case preparationModel of
                        Preparation.Project { id } ->
                            Element.row
                                [ Background.color Colors.primary
                                , Element.width Element.fill
                                , Element.spacing 30
                                ]
                                [ Element.row
                                    [ Element.alignLeft, Element.padding 10, Element.spacing 10 ]
                                    [ homeButton ]
                                , Element.row
                                    [ Element.alignLeft, Element.padding 10, Element.spacing 10 ]
                                    (if Core.isLoggedIn model then
                                        [ newProjectButton, newCapsuleButton id ]

                                     else
                                        []
                                    )
                                , Element.row [ Element.alignRight, Element.padding 10, Element.spacing 10 ]
                                    (if Core.isLoggedIn model then
                                        [ logoutButton ]

                                     else
                                        [ loginButton, signUpButton ]
                                    )
                                ]

                        _ ->
                            nonFull model

                _ ->
                    nonFull model

        _ ->
            nonFull model


nonFull : Core.Model -> Element Core.Msg
nonFull model =
    Element.row
        [ Background.color Colors.primary
        , Element.width Element.fill
        , Element.spacing 30
        ]
        [ Element.row
            [ Element.alignLeft, Element.padding 10, Element.spacing 10 ]
            [ homeButton ]
        , Element.row
            [ Element.alignLeft, Element.padding 10, Element.spacing 10 ]
            (if Core.isLoggedIn model then
                [ newProjectButton ]

             else
                []
            )
        , Element.row [ Element.alignRight, Element.padding 10, Element.spacing 10 ]
            (if Core.isLoggedIn model then
                [ logoutButton ]

             else
                [ loginButton, signUpButton ]
            )
        ]


homeButton : Element Core.Msg
homeButton =
    Element.el [ Font.bold, Font.size 18 ] (Ui.textButton (Just Core.HomeClicked) "Preparation")


newProjectButton : Element Core.Msg
newProjectButton =
    Ui.textButton (Just Core.NewProjectClicked) "New project"


newCapsuleButton : Int -> Element Core.Msg
newCapsuleButton id =
    Ui.textButton (Just (Core.NewCapsuleClicked id)) "New capsule"


loginButton : Element Core.Msg
loginButton =
    Ui.simpleButton (Just Core.LoginClicked) "Log in"


logoutButton : Element Core.Msg
logoutButton =
    Ui.simpleButton (Just Core.LogoutClicked) "Log out"


signUpButton : Element Core.Msg
signUpButton =
    Ui.successButton Nothing "Sign up"
