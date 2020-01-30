module Main exposing (main)

import Api
import Browser
import Colors
import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Html
import Json.Decode as Decode exposing (Decoder)
import Status exposing (Status)
import Ui


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias SignUpContent =
    { status : Status () ()
    , username : String
    , password : String
    , email : String
    }


emptySignUpContent : SignUpContent
emptySignUpContent =
    SignUpContent Status.NotSent "" "" ""


type alias LoginContent =
    { status : Status () ()
    , username : String
    , password : String
    }


emptyLoginContent : LoginContent
emptyLoginContent =
    LoginContent Status.NotSent "" ""


type alias NewProjectContent =
    { status : Status () ()
    , name : String
    }


emptyNewProjectContent : NewProjectContent
emptyNewProjectContent =
    NewProjectContent Status.NotSent ""


type alias Session =
    { username : String
    , projects : List String
    }


decodeSession : Decoder Session
decodeSession =
    Decode.map2 Session
        (Decode.field "username" Decode.string)
        (Decode.field "projects" (Decode.list Decode.string))


type Model
    = Home
    | Login LoginContent
    | SignUp SignUpContent
    | LoggedIn LoggedInModel


type alias LoggedInModel =
    { session : Session
    , page : LoggedInPage
    }


type LoggedInPage
    = LoggedInHome
    | LoggedInNewProject NewProjectContent


isLoggedIn : Model -> Bool
isLoggedIn model =
    case model of
        LoggedIn _ ->
            True

        _ ->
            False


init : Decode.Value -> ( Model, Cmd Msg )
init flags =
    case Decode.decodeValue decodeSession flags of
        Err _ ->
            ( Home, Cmd.none )

        Ok s ->
            ( LoggedIn (LoggedInModel s LoggedInHome), Cmd.none )



-- MESSAGE


type Msg
    = Noop
    | HomeClicked
    | LoginClicked
    | SignUpClicked
    | LogOutClicked
    | LogOutSuccess
    | LoginMsg LoginMsg
    | SignUpMsg SignUpMsg
    | LoggedInMsg LoggedInMsg


type LoginMsg
    = LoginContentUsernameChanged String
    | LoginContentPasswordChanged String
    | LoginSubmitted
    | LoginSuccess Session
    | LoginFailed


type SignUpMsg
    = SignUpContentUsernameChanged String
    | SignUpContentPasswordChanged String
    | SignUpContentEmailChanged String
    | SignUpSubmitted
    | SignUpSuccess


type LoggedInMsg
    = NewProjectClicked
    | NewProjectMsg NewProjectMsg


type NewProjectMsg
    = NewProjectNameChanged String
    | NewProjectSubmitted
    | NewProjectSuccess



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( Noop, m ) ->
            ( m, Cmd.none )

        ( HomeClicked, LoggedIn { session } ) ->
            ( LoggedIn { session = session, page = LoggedInHome }, Cmd.none )

        ( HomeClicked, _ ) ->
            ( Home, Cmd.none )

        ( LoginClicked, _ ) ->
            ( Login emptyLoginContent, Cmd.none )

        ( LogOutClicked, _ ) ->
            ( model, Api.logOut (\_ -> LogOutSuccess) )

        ( LogOutSuccess, _ ) ->
            ( Home, Cmd.none )

        ( SignUpClicked, _ ) ->
            ( SignUp emptySignUpContent, Cmd.none )

        ( LoginMsg loginMsg, Login content ) ->
            updateLogin loginMsg content

        ( SignUpMsg signUpMsg, SignUp content ) ->
            updateSignUp signUpMsg content |> Tuple.mapFirst SignUp

        ( LoggedInMsg loggedInMsg, LoggedIn loggedInModel ) ->
            let
                ( newModel, cmd ) =
                    updateLoggedIn loggedInMsg loggedInModel
            in
            ( LoggedIn newModel, cmd )

        _ ->
            ( model, Cmd.none )


updateLogin : LoginMsg -> LoginContent -> ( Model, Cmd Msg )
updateLogin loginMsg content =
    case loginMsg of
        LoginContentUsernameChanged newUsername ->
            ( Login { content | username = newUsername }, Cmd.none )

        LoginContentPasswordChanged newPassword ->
            ( Login { content | password = newPassword }, Cmd.none )

        LoginSubmitted ->
            ( Login { content | status = Status.Sent }
            , Api.login resultToMsg decodeSession content
            )

        LoginSuccess s ->
            ( LoggedIn (LoggedInModel s LoggedInHome), Cmd.none )

        LoginFailed ->
            ( Login { content | status = Status.Error () }, Cmd.none )


updateSignUp : SignUpMsg -> SignUpContent -> ( SignUpContent, Cmd Msg )
updateSignUp msg content =
    case msg of
        SignUpContentUsernameChanged newUsername ->
            ( { content | username = newUsername }, Cmd.none )

        SignUpContentPasswordChanged newPassword ->
            ( { content | password = newPassword }, Cmd.none )

        SignUpContentEmailChanged newEmail ->
            ( { content | email = newEmail }, Cmd.none )

        SignUpSubmitted ->
            ( { content | status = Status.Sent }
            , Api.signUp (\_ -> SignUpMsg SignUpSuccess) content
            )

        SignUpSuccess ->
            ( { content | status = Status.Success () }, Cmd.none )


updateLoggedIn : LoggedInMsg -> LoggedInModel -> ( LoggedInModel, Cmd Msg )
updateLoggedIn msg { session, page } =
    case ( msg, page ) of
        ( NewProjectClicked, _ ) ->
            ( { session = session
              , page = LoggedInNewProject emptyNewProjectContent
              }
            , Cmd.none
            )

        ( NewProjectMsg newProjectMsg, LoggedInNewProject content ) ->
            let
                ( newSession, newModel, newCmd ) =
                    updateNewProjectMsg newProjectMsg session content
            in
            ( { session = newSession, page = LoggedInNewProject newModel }, newCmd )

        ( _, _ ) ->
            ( { session = session, page = page }, Cmd.none )


updateNewProjectMsg : NewProjectMsg -> Session -> NewProjectContent -> ( Session, NewProjectContent, Cmd Msg )
updateNewProjectMsg msg session content =
    case msg of
        NewProjectNameChanged newProjectName ->
            ( session, { content | name = newProjectName }, Cmd.none )

        NewProjectSubmitted ->
            ( session, { content | status = Status.Sent }, Api.newProject resultToMsg2 content )

        NewProjectSuccess ->
            ( { session | projects = content.name :: session.projects }
            , { content | status = Status.Success () }
            , Cmd.none
            )



-- COMMANDS


resultToMsg : Result e Session -> Msg
resultToMsg result =
    case result of
        Err _ ->
            LoginMsg LoginFailed

        Ok a ->
            LoginMsg (LoginSuccess a)


resultToMsg2 : Result e t -> Msg
resultToMsg2 result =
    case result of
        Err _ ->
            Noop

        Ok _ ->
            LoggedInMsg (NewProjectMsg NewProjectSuccess)



-- VIEW


view : Model -> Html.Html Msg
view model =
    Element.layout [ Font.size 15 ] (viewContent model)


viewContent : Model -> Element Msg
viewContent model =
    let
        content =
            case model of
                Home ->
                    homeView

                Login c ->
                    loginView c

                SignUp c ->
                    signUpView c

                LoggedIn s ->
                    loggedInView s
    in
    Element.column [ Element.width Element.fill ] [ topBar model, content ]


homeView : Element Msg
homeView =
    Element.column
        [ Element.alignTop
        , Element.padding 10
        , Element.width Element.fill
        ]
        [ Element.text "Home" ]


loginView : LoginContent -> Element Msg
loginView { username, password, status } =
    let
        submitButton =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "Logging in..."

                _ ->
                    Ui.primaryButton (Just LoginSubmitted) "Login"

        errorMessage =
            case status of
                Status.Error () ->
                    Just (Ui.errorModal "Login failed")

                _ ->
                    Nothing

        header =
            Element.row [ Element.centerX ] [ Element.text "Login" ]

        fields =
            [ Input.text []
                { label = Input.labelAbove [] (Element.text "Username")
                , onChange = LoginContentUsernameChanged
                , placeholder = Nothing
                , text = username
                }
            , Input.newPassword []
                { label = Input.labelAbove [] (Element.text "Password")
                , onChange = LoginContentPasswordChanged
                , placeholder = Nothing
                , text = password
                , show = False
                }
            , submitButton
            ]

        form =
            case errorMessage of
                Just message ->
                    header :: message :: fields

                Nothing ->
                    header :: fields
    in
    Element.map LoginMsg <|
        Element.column [ Element.centerX, Element.padding 10, Element.spacing 10 ]
            form


signUpView : SignUpContent -> Element Msg
signUpView { username, password, email, status } =
    let
        submitButton =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "Submitting ..."

                Status.Success () ->
                    Ui.primaryButtonDisabled "Submitted!"

                _ ->
                    Ui.primaryButton (Just SignUpSubmitted) "Submit"

        message =
            case status of
                Status.Success () ->
                    Just (Ui.successModal "An email has been sent to your address!")

                Status.Error () ->
                    Just (Ui.errorModal "Sign up failed")

                _ ->
                    Nothing

        header =
            Element.row [ Element.centerX ] [ Element.text "Sign up" ]

        fields =
            [ Input.text []
                { label = Input.labelAbove [] (Element.text "Username")
                , onChange = SignUpContentUsernameChanged
                , placeholder = Nothing
                , text = username
                }
            , Input.email []
                { label = Input.labelAbove [] (Element.text "Email")
                , onChange = SignUpContentEmailChanged
                , placeholder = Nothing
                , text = email
                }
            , Input.newPassword []
                { label = Input.labelAbove [] (Element.text "Password")
                , onChange = SignUpContentPasswordChanged
                , placeholder = Nothing
                , text = password
                , show = False
                }
            , submitButton
            ]

        form =
            case message of
                Just m ->
                    header :: m :: fields

                Nothing ->
                    header :: fields
    in
    Element.map SignUpMsg <|
        Element.column
            [ Element.centerX, Element.padding 10, Element.spacing 10 ]
            form


loggedInView : LoggedInModel -> Element Msg
loggedInView { session, page } =
    let
        mainPage =
            case page of
                LoggedInHome ->
                    loggedInHomeView session

                LoggedInNewProject content ->
                    loggedInNewProjectView session content

        element =
            Element.column
                [ Element.alignTop
                , Element.padding 10
                , Element.width Element.fill
                ]
                [ mainPage ]
    in
    Element.row
        [ Element.height Element.fill
        , Element.width Element.fill
        , Element.spacing 20
        ]
        [ element ]


loggedInHomeView : Session -> Element Msg
loggedInHomeView session =
    Element.column []
        [ welcomeHeading session.username
        , projectsView session.projects
        ]


welcomeHeading : String -> Element Msg
welcomeHeading name =
    Element.el [ Font.size 20, Element.padding 10 ] (Element.text ("Welcome " ++ name ++ "!"))


loggedInNewProjectView : Session -> NewProjectContent -> Element Msg
loggedInNewProjectView _ { status, name } =
    let
        submitButton =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "Creating project..."

                Status.Success () ->
                    Ui.primaryButtonDisabled "Project created!"

                _ ->
                    Ui.primaryButton (Just NewProjectSubmitted) "Create project"

        message =
            case status of
                Status.Error () ->
                    Just (Ui.errorModal "Project creation failed")

                Status.Success () ->
                    Just (Ui.successModal "Project created!")

                _ ->
                    Nothing

        header =
            Element.row [ Element.centerX ] [ Element.text "New project" ]

        fields =
            [ Input.text []
                { label = Input.labelAbove [] (Element.text "Project name")
                , onChange = NewProjectNameChanged
                , placeholder = Nothing
                , text = name
                }
            , submitButton
            ]

        form =
            case message of
                Just m ->
                    header :: m :: fields

                Nothing ->
                    header :: fields
    in
    Element.map LoggedInMsg <|
        Element.map NewProjectMsg <|
            Element.column [ Element.centerX, Element.padding 10, Element.spacing 10 ]
                form


projectsView : List String -> Element Msg
projectsView names =
    case names of
        [] ->
            Element.paragraph [ Element.padding 10, Font.size 18 ]
                [ Element.text "You have no projects yet. "
                , Ui.linkButton
                    (Just (LoggedInMsg NewProjectClicked))
                    "Click here to create a new project!"
                ]

        _ ->
            Element.column [ Element.padding 10 ]
                [ Element.el [ Font.size 18 ] (Element.text "Your projects:")
                , Element.column [ Element.padding 10, Element.spacing 10 ]
                    (List.map projectView names)
                ]


projectView : String -> Element msg
projectView name =
    Element.text name


topBar : Model -> Element Msg
topBar model =
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
            (if isLoggedIn model then
                [ newProjectButton ]

             else
                []
            )
        , Element.row [ Element.alignRight, Element.padding 10, Element.spacing 10 ]
            (if isLoggedIn model then
                [ logOutButton ]

             else
                [ loginButton, signUpButton ]
            )
        ]


homeButton : Element Msg
homeButton =
    Element.el [ Font.bold, Font.size 18 ] (Ui.textButton (Just HomeClicked) "Preparation")


newProjectButton : Element Msg
newProjectButton =
    Ui.textButton (Just (LoggedInMsg NewProjectClicked)) "New project"


loginButton : Element Msg
loginButton =
    Ui.simpleButton (Just LoginClicked) "Log in"


logOutButton : Element Msg
logOutButton =
    Ui.simpleButton (Just LogOutClicked) "Log out"


signUpButton : Element Msg
signUpButton =
    Ui.successButton (Just SignUpClicked) "Sign up"
