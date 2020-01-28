module Main exposing (..)

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


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \x -> Sub.none
        }



-- MODEL


urlEncode : List ( String, String ) -> String
urlEncode strings =
    String.join "&" (List.map (\( x, y ) -> x ++ "=" ++ y) strings)


type alias SignUpContent =
    { username : String
    , password : String
    , email : String
    }


emptySignUpContent : SignUpContent
emptySignUpContent =
    SignUpContent "" "" ""


urlEncodeSignUpContent : SignUpContent -> String
urlEncodeSignUpContent { username, password, email } =
    urlEncode
        [ ( "username", username )
        , ( "password", password )
        , ( "email", email )
        ]


type alias LoginContent =
    { username : String
    , password : String
    }


emptyLoginContent : LoginContent
emptyLoginContent =
    LoginContent "" ""


urlEncodeLoginContent { username, password } =
    urlEncode
        [ ( "username", username )
        , ( "password", password )
        ]


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
            ( model, logOutCommand )

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
            ( Login content, loginCommand content )

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
            ( content, signUpCommand content )



-- COMMANDS


signUpCommand : SignUpContent -> Cmd Msg
signUpCommand content =
    Http.post
        { url = "/api/new-user/"
        , expect = Http.expectWhatever (\x -> Noop)
        , body =
            Http.stringBody
                "application/x-www-form-urlencoded"
                (urlEncodeSignUpContent content)
        }


resultToMsg result =
    case result of
        Err e ->
            Noop

        Ok a ->
            LoginMsg (LoginSuccess a)


loginCommand : LoginContent -> Cmd Msg
loginCommand content =
    Http.post
        { url = "/api/login"
        , expect = Http.expectJson resultToMsg decodeSession
        , body =
            Http.stringBody
                "application/x-www-form-urlencoded"
                (urlEncodeLoginContent content)
        }


logOutCommand : Cmd Msg
logOutCommand =
    Http.post
        { url = "/api/logout"
        , expect = Http.expectWhatever (\x -> LogOutSuccess)
        , body = Http.emptyBody
        }



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
loginView { username, password } =
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
            , Input.button
                [ Element.centerX
                , Element.padding 10
                , Background.color Colors.royalBlue
                , Border.rounded 3
                ]
                { onPress = Just LoginSubmitted
                , label = Element.text "Submit"
                }
            ]


signUpView : SignUpContent -> Element Msg
signUpView { username, password, email } =
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
            , Input.button
                [ Element.centerX
                , Element.padding 10
                , Background.color Colors.royalBlue
                , Border.rounded 3
                ]
                { onPress = Just SignUpSubmitted
                , label = Element.text "Submit"
                }
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
    Input.button
        (Background.color (Element.rgb255 255 255 255)
            :: Font.color (Element.rgb255 0 0 0)
            :: defaultAttributes
        )
        { onPress = Just LoginClicked, label = Element.text "Log in" }


logOutButton : Element Msg
logOutButton =
    Input.button
        (Background.color (Element.rgb255 255 255 255)
            :: Font.color (Element.rgb255 0 0 0)
            :: defaultAttributes
        )
        { onPress = Just LogOutClicked, label = Element.text "Log out" }


signUpButton : Element Msg
signUpButton =
    Input.button
        (Font.color (Element.rgb255 255 255 255)
            :: Background.color Colors.limeGreen
            :: defaultAttributes
        )
        { onPress = Just SignUpClicked, label = Element.text "Sign up" }
