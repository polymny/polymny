module Main exposing (..)

import Api
import Browser
import Colors
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Html
import Http
import Json.Decode as Decode exposing (Decoder)
import Status exposing (Status)
import Ui


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \x -> Sub.none
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


type alias Session =
    { username : String
    }


decodeSession : Decoder Session
decodeSession =
    Decode.map Session (Decode.field "username" Decode.string)


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
        Err e ->
            ( Home, Cmd.none )

        Ok s ->
            ( LoggedIn (LoggedInModel s LoggedInHome), Cmd.none )



-- MESSAGE


type Msg
    = Noop
    | LoginClicked
    | SignUpClicked
    | LogOutClicked
    | LogOutSuccess
    | LoginMsg LoginMsg
    | SignUpMsg SignUpMsg


type LoginMsg
    = LoginContentUsernameChanged String
    | LoginContentPasswordChanged String
    | LoginSubmitted
    | LoginSuccess Session


type SignUpMsg
    = SignUpContentUsernameChanged String
    | SignUpContentPasswordChanged String
    | SignUpContentEmailChanged String
    | SignUpSubmitted



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( Noop, m ) ->
            ( m, Cmd.none )

        ( LoginClicked, _ ) ->
            ( Login emptyLoginContent, Cmd.none )

        ( LogOutClicked, _ ) ->
            ( model, Api.logOut (\x -> LogOutSuccess) )

        ( LogOutSuccess, _ ) ->
            ( Home, Cmd.none )

        ( SignUpClicked, _ ) ->
            ( SignUp emptySignUpContent, Cmd.none )

        ( LoginMsg loginMsg, Login content ) ->
            updateLogin loginMsg content

        ( SignUpMsg signUpMsg, SignUp content ) ->
            updateSignUp signUpMsg content |> Tuple.mapFirst SignUp

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
            , Api.signUp (\x -> Noop) content
            )



-- COMMANDS


resultToMsg result =
    case result of
        Err e ->
            Noop

        Ok a ->
            LoginMsg (LoginSuccess a)



-- VIEW


defaultAttributes =
    [ Border.rounded 3
    , Element.padding 10
    ]


view : Model -> Html.Html Msg
view model =
    Element.layout [] (viewContent model)


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
    Element.text "Home"


loginView : LoginContent -> Element Msg
loginView { username, password, status } =
    let
        submitButton =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "Logging in..."

                _ ->
                    Ui.primaryButton (Just LoginSubmitted) "Login"
    in
    Element.map LoginMsg <|
        Element.column [ Element.centerX, Element.padding 10, Element.spacing 10 ]
            [ Element.row [ Element.centerX ] [ Element.text "Login" ]
            , Input.text []
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


signUpView : SignUpContent -> Element Msg
signUpView { username, password, email, status } =
    let
        submitButton =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "Submit"

                _ ->
                    Ui.primaryButton (Just SignUpSubmitted) "Submit"
    in
    Element.map SignUpMsg <|
        Element.column [ Element.centerX, Element.padding 10, Element.spacing 10 ]
            [ Element.row [ Element.centerX ] [ Element.text "Sign up" ]
            , Input.text []
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


loggedInView : LoggedInModel -> Element Msg
loggedInView { session, page } =
    let
        mainPage =
            case page of
                LoggedInHome ->
                    loggedInHomeView session

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
    Element.text ("Welcome " ++ session.username ++ "!")


topBar : Model -> Element Msg
topBar model =
    Element.row
        [ Background.color Colors.royalBlue
        , Element.width Element.fill
        , Element.spacing 30
        ]
        [ titleButton
        , Element.row [ Element.alignRight, Element.padding 10, Element.spacing 10 ]
            (if isLoggedIn model then
                [ logOutButton ]

             else
                [ loginButton, signUpButton ]
            )
        ]


titleButton : Element Msg
titleButton =
    Element.el
        (Font.color (Element.rgb255 255 255 255)
            :: defaultAttributes
        )
        (Element.text "Home")


loginButton : Element Msg
loginButton =
    Ui.simpleButton (Just LoginClicked) "Log in"


logOutButton : Element Msg
logOutButton =
    Ui.simpleButton (Just LogOutClicked) "Log out"


signUpButton : Element Msg
signUpButton =
    Ui.successButton (Just SignUpClicked) "Sign up"
