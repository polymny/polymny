module Core.Views exposing (..)

import Colors
import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Html
import LoggedIn.Types as LoggedIn
import LoggedIn.Views as LoggedIn
import Login.Views as Login
import SignUp.Views as SignUp
import Ui


view : Core.FullModel -> Html.Html Core.Msg
view fullModel =
    Element.layout [ Font.size 15 ] (viewContent fullModel)


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

                Core.LoggedIn { session, page } ->
                    LoggedIn.view global session page

        attributes =
            []
    in
    Element.column (Element.width Element.fill :: attributes) [ topBar model, content ]


homeView : Element Core.Msg
homeView =
    Element.column [ Element.alignTop, Element.padding 10, Element.width Element.fill ] [ Element.text "Home" ]


topBar : Core.Model -> Element Core.Msg
topBar model =
    case model of
        Core.LoggedIn { page } ->
            case page of
                -- Core.ProjectPage { id } ->
                --     Element.row
                --         [ Background.color Colors.primary
                --         , Element.width Element.fill
                --         , Element.spacing 30
                --         ]
                --         [ Element.row
                --             [ Element.alignLeft, Element.padding 10, Element.spacing 10 ]
                --             [ homeButton ]
                --         , Element.row
                --             [ Element.alignLeft, Element.padding 10, Element.spacing 10 ]
                --             (if isLoggedIn model then
                --                 [ newCapsuleButton id ]
                --              else
                --                 []
                --             )
                --         , Element.row [ Element.alignRight, Element.padding 10, Element.spacing 10 ]
                --             (if isLoggedIn model then
                --                 [ logoutButton ]
                --              else
                --                 [ loginButton, signUpButton ]
                --             )
                --         ]
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
    -- Ui.textButton (Just (LoggedInMsg (NewCapsuleClicked id))) "New capsule"
    Ui.textButton Nothing "New capsule"


loginButton : Element Core.Msg
loginButton =
    Ui.simpleButton (Just Core.LoginClicked) "Log in"


logoutButton : Element Core.Msg
logoutButton =
    Ui.simpleButton (Just Core.LogoutClicked) "Log out"


signUpButton : Element Core.Msg
signUpButton =
    Ui.successButton Nothing "Sign up"


selectFileButton : Element Core.Msg
selectFileButton =
    -- Element.map LoggedInMsg <|
    --     Element.map UploadSlideShowMsg <|
    --         Ui.simpleButton (Just UploadSlideShowSelectFileRequested) "Select file"
    Ui.simpleButton Nothing "Select file"


uploadButton : Element Core.Msg
uploadButton =
    -- Element.map LoggedInMsg <|
    --     Element.map UploadSlideShowMsg <|
    --         Ui.primaryButton (Just UploadSlideShowFormSubmitted) "Upload"
    Ui.primaryButton Nothing "Upload"
