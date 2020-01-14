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
    | LoggedIn Session


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
            ( LoggedIn s, Cmd.none )



-- MESSAGE


type Msg
    = Noop
    | LoginClicked
    | LoginContentUsernameChanged String
    | LoginContentPasswordChanged String
    | LoginSubmitted
    | LoginSuccess Session
    | LogOutClicked
    | LogOutSuccess
    | SignUpClicked
    | SignUpContentUsernameChanged String
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

        ( LoginContentUsernameChanged newUsername, Login content ) ->
            ( Login { content | username = newUsername }, Cmd.none )

        ( LoginContentPasswordChanged newPassword, Login content ) ->
            ( Login { content | password = newPassword }, Cmd.none )

        ( LoginSubmitted, Login content ) ->
            ( model, loginCommand content )

        ( LoginSuccess s, Home ) ->
            ( LoggedIn s, Cmd.none )

        ( LoginSuccess s, Login _ ) ->
            ( LoggedIn s, Cmd.none )

        ( SignUpContentUsernameChanged newUsername, SignUp content ) ->
            ( SignUp { content | username = newUsername }, Cmd.none )

        ( SignUpContentPasswordChanged newPassword, SignUp content ) ->
            ( SignUp { content | password = newPassword }, Cmd.none )

        ( SignUpContentEmailChanged newEmail, SignUp content ) ->
            ( SignUp { content | email = newEmail }, Cmd.none )

        ( SignUpSubmitted, SignUp content ) ->
            ( model, signUpCommand content )

        _ ->
            ( model, Cmd.none )



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
            LoginSuccess a


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
    Element.column
        [ Element.width Element.fill
        ]
        [ topBar model, content ]


homeView : Element Msg
homeView =
    Element.text "Home"


loginView : LoginContent -> Element Msg
loginView { username, password } =
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


loggedInView : Session -> Element Msg
loggedInView session =
    Element.text ("Welcome " ++ session.username)


topBar : Model -> Element Msg
topBar model =
    Element.row
        [ Background.color Colors.royalBlue
        , Element.width
            Element.fill
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
