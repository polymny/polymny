module Core.Views exposing (subscriptions, view)

import Acquisition.Ports
import Acquisition.Types as Acquisition
import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Html
import LoggedIn.Types as LoggedIn
import LoggedIn.Views as LoggedIn
import Login.Views as Login
import Preparation.Types as Preparation
import Preparation.Views as Preparation
import SignUp.Views as SignUp
import Ui.Attributes as Attributes
import Ui.Colors as Colors
import Ui.Ui as Ui


subscriptions : Core.FullModel -> Sub Core.Msg
subscriptions { model } =
    case model of
        Core.LoggedIn { tab } ->
            case tab of
                LoggedIn.Preparation { slideModel, gosModel } ->
                    Sub.map
                        (\x ->
                            Core.LoggedInMsg (LoggedIn.PreparationMsg (Preparation.DnD x))
                        )
                        (Sub.batch
                            [ Preparation.slideSystem.subscriptions slideModel
                            , Preparation.gosSystem.subscriptions gosModel
                            ]
                        )

                LoggedIn.Acquisition _ ->
                    Sub.batch
                        [ Acquisition.Ports.newRecord Acquisition.NewRecord
                        , Acquisition.Ports.streamUploaded Acquisition.StreamUploaded
                        , Acquisition.Ports.nextSlideReceived Acquisition.NextSlideReceived
                        , Acquisition.Ports.goToNextSlide (\_ -> Acquisition.NextSlide False)
                        ]
                        |> Sub.map LoggedIn.AcquisitionMsg
                        |> Sub.map Core.LoggedInMsg

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
                        LoggedIn.Preparation { slides, slideModel, gosModel, details } ->
                            [ Element.inFront (Preparation.gosGhostView details gosModel slideModel (List.concat slides))
                            , Element.inFront (Preparation.slideGhostView slideModel (List.concat slides))
                            ]

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
        Core.LoggedIn { session, tab } ->
            Element.row
                [ Background.color Colors.primary
                , Font.color Colors.white
                , Element.width Element.fill
                , Element.spacing 30
                ]
                [ Element.row
                    [ Element.alignLeft, Element.padding 10, Element.spacing 5 ]
                    [ homeButton ]
                , Element.row [ Element.alignRight, Element.padding 10, Element.spacing 10 ]
                    (if Core.isLoggedIn model then
                        [ Element.el [] (Element.text session.username), logoutButton ]

                     else
                        [ loginButton, signUpButton ]
                    )
                ]

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
        , Element.row [ Element.alignRight, Element.padding 10, Element.spacing 10 ]
            (if Core.isLoggedIn model then
                [ logoutButton ]

             else
                [ loginButton, signUpButton ]
            )
        ]


homeButton : Element Core.Msg
homeButton =
    Element.el [ Font.bold, Font.size 18 ] (Ui.homeButton (Just Core.HomeClicked) "")


loginButton : Element Core.Msg
loginButton =
    Ui.topBarButton (Just Core.LoginClicked) "Log in"


logoutButton : Element Core.Msg
logoutButton =
    Ui.topBarButton (Just Core.LogoutClicked) "Log out"


signUpButton : Element Core.Msg
signUpButton =
    Ui.textButton (Just Core.SignUpClicked) "Sign up"
