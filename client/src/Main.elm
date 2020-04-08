module Main exposing (main)

import Api
import Browser
import Colors
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import File exposing (File)
import File.Select as Select
import Html
import Json.Decode as Decode
import Lorem
import Status exposing (Status)
import Task
import Time
import TimeUtils
import Ui


main : Program Decode.Value FullModel Msg
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


type alias UploadForm =
    { file : Maybe File
    }


emptyUploadForm : UploadForm
emptyUploadForm =
    UploadForm Nothing


type alias NewCapsuleContent =
    { status : Status () ()
    , name : String
    , title : String
    , description : String
    }


emptyNewCapsuleContent : NewCapsuleContent
emptyNewCapsuleContent =
    NewCapsuleContent Status.NotSent "" "" ""


type alias Global =
    { zone : Time.Zone
    }


type alias FullModel =
    { global : Global
    , model : Model
    }


type Model
    = Home
    | Login LoginContent
    | SignUp SignUpContent
    | LoggedIn LoggedInModel


type alias LoggedInModel =
    { session : Api.Session
    , page : LoggedInPage
    }


type LoggedInPage
    = LoggedInHome
    | LoggedInNewProject NewProjectContent
    | LoggedInNewCapsule Int NewCapsuleContent
    | ProjectPage Api.Project
    | CapsulePage Api.CapsuleDetails UploadForm


isLoggedIn : Model -> Bool
isLoggedIn model =
    case model of
        LoggedIn _ ->
            True

        _ ->
            False


init : Decode.Value -> ( FullModel, Cmd Msg )
init flags =
    let
        global =
            { zone = Time.utc }

        initialCommand =
            Task.perform TimeZoneChange Time.here
    in
    ( FullModel global (modelFromFlags flags), initialCommand )


modelFromFlags : Decode.Value -> Model
modelFromFlags flags =
    case Decode.decodeValue (Decode.field "page" Decode.string) flags of
        Ok "index" ->
            case Decode.decodeValue Api.decodeSession flags of
                Ok session ->
                    LoggedIn { session = session, page = LoggedInHome }

                Err _ ->
                    Home

        Ok "capsule" ->
            case ( Decode.decodeValue Api.decodeSession flags, Decode.decodeValue Api.decodeCapsuleDetails flags ) of
                ( Ok session, Ok capsule ) ->
                    LoggedIn (LoggedInModel session (CapsulePage capsule emptyUploadForm))

                ( _, _ ) ->
                    Home

        Ok ok ->
            let
                _ =
                    debug "Unknown page" ok
            in
            Home

        Err err ->
            let
                _ =
                    debug "Error" err
            in
            Home



-- MESSAGE


type Msg
    = Noop
    | TimeZoneChange Time.Zone
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
    | LoginSuccess Api.Session
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
    | NewCapsuleClicked Int
    | NewCapsuleMsg NewCapsuleMsg
    | ProjectClicked Api.Project
    | CapsulesReceived Api.Project (List Api.Capsule)
    | CapsuleClicked Api.Capsule
    | CapsuleReceived Api.CapsuleDetails
    | UploadSlideShowMsg UploadSlideShowMsg


type NewProjectMsg
    = NewProjectNameChanged String
    | NewProjectSubmitted
    | NewProjectSuccess Api.Project


type NewCapsuleMsg
    = NewCapsuleNameChanged String
    | NewCapsuleTitleChanged String
    | NewCapsuleDescriptionChanged String
    | NewCapsuleSubmitted
    | NewCapsuleSuccess Api.Capsule


type UploadSlideShowMsg
    = UploadSlideShowSelectFileRequested
    | UploadSlideShowFileReady File
    | UploadSlideShowFormSubmitted



-- UPDATE


update : Msg -> FullModel -> ( FullModel, Cmd Msg )
update msg { global, model } =
    case ( msg, model ) of
        ( Noop, _ ) ->
            ( FullModel global model, Cmd.none )

        ( TimeZoneChange newTimeZone, _ ) ->
            ( { global = { global | zone = newTimeZone }, model = model }, Cmd.none )

        ( HomeClicked, LoggedIn { session } ) ->
            ( FullModel global (LoggedIn { session = session, page = LoggedInHome }), Cmd.none )

        ( HomeClicked, _ ) ->
            ( FullModel global Home, Cmd.none )

        ( LoginClicked, _ ) ->
            ( FullModel global (Login emptyLoginContent), Cmd.none )

        ( LogOutClicked, _ ) ->
            ( FullModel global model, Api.logOut (\_ -> LogOutSuccess) )

        ( LogOutSuccess, _ ) ->
            ( FullModel global Home, Cmd.none )

        ( SignUpClicked, _ ) ->
            ( FullModel global (SignUp emptySignUpContent), Cmd.none )

        ( LoginMsg loginMsg, Login content ) ->
            let
                ( m, cmd ) =
                    updateLogin loginMsg content
            in
            ( FullModel global m, cmd )

        ( SignUpMsg signUpMsg, SignUp content ) ->
            let
                ( m, cmd ) =
                    updateSignUp signUpMsg content |> Tuple.mapFirst SignUp
            in
            ( FullModel global m, cmd )

        ( LoggedInMsg loggedInMsg, LoggedIn loggedInModel ) ->
            let
                ( newModel, cmd ) =
                    updateLoggedIn loggedInMsg loggedInModel
            in
            ( FullModel global (LoggedIn newModel), cmd )

        _ ->
            ( FullModel global model, Cmd.none )


updateLogin : LoginMsg -> LoginContent -> ( Model, Cmd Msg )
updateLogin loginMsg content =
    case loginMsg of
        LoginContentUsernameChanged newUsername ->
            ( Login { content | username = newUsername }, Cmd.none )

        LoginContentPasswordChanged newPassword ->
            ( Login { content | password = newPassword }, Cmd.none )

        LoginSubmitted ->
            ( Login { content | status = Status.Sent }
            , Api.login resultToMsg1 content
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

        ( NewCapsuleClicked projectId, _ ) ->
            ( { session = session
              , page = LoggedInNewCapsule projectId emptyNewCapsuleContent
              }
            , Cmd.none
            )

        ( NewProjectMsg newProjectMsg, LoggedInNewProject content ) ->
            let
                ( newSession, newModel, newCmd ) =
                    updateNewProjectMsg newProjectMsg session content
            in
            ( { session = newSession, page = LoggedInNewProject newModel }, newCmd )

        ( NewCapsuleMsg newCapsuleMsg, LoggedInNewCapsule projectId content ) ->
            let
                ( newSession, newModel, newCmd ) =
                    updateNewCapsuleMsg newCapsuleMsg session projectId content
            in
            ( { session = newSession, page = LoggedInNewCapsule projectId newModel }, newCmd )

        ( UploadSlideShowMsg newUploadSlideShowMsg, CapsulePage capsule form ) ->
            let
                ( newSession, newModel, newCmd ) =
                    updateUploadSlideShow newUploadSlideShowMsg session form capsule.capsule.id
            in
            ( { session = newSession, page = CapsulePage capsule newModel }, newCmd )

        ( ProjectClicked project, _ ) ->
            ( LoggedInModel session page, Api.capsulesFromProjectId (resultToMsg3 project) project.id )

        ( CapsulesReceived project newCapsules, _ ) ->
            ( LoggedInModel session (ProjectPage { project | capsules = newCapsules }), Cmd.none )

        ( CapsuleClicked capsule, _ ) ->
            ( LoggedInModel session page, Api.capsuleFromId resultToMsg5 capsule.id )

        ( CapsuleReceived capsule, _ ) ->
            ( LoggedInModel session (CapsulePage capsule emptyUploadForm), Cmd.none )

        ( _, _ ) ->
            ( { session = session, page = page }, Cmd.none )


updateNewProjectMsg : NewProjectMsg -> Api.Session -> NewProjectContent -> ( Api.Session, NewProjectContent, Cmd Msg )
updateNewProjectMsg msg session content =
    case msg of
        NewProjectNameChanged newProjectName ->
            ( session, { content | name = newProjectName }, Cmd.none )

        NewProjectSubmitted ->
            ( session
            , { content | status = Status.Sent }
            , Api.newProject resultToMsg2 content
            )

        NewProjectSuccess project ->
            ( { session | projects = project :: session.projects }
            , { content | status = Status.Success () }
            , Cmd.none
            )


updateNewCapsuleMsg : NewCapsuleMsg -> Api.Session -> Int -> NewCapsuleContent -> ( Api.Session, NewCapsuleContent, Cmd Msg )
updateNewCapsuleMsg msg session projectId content =
    case msg of
        NewCapsuleNameChanged newCapsuleName ->
            ( session, { content | name = newCapsuleName }, Cmd.none )

        NewCapsuleTitleChanged newTitleName ->
            ( session, { content | title = newTitleName }, Cmd.none )

        NewCapsuleDescriptionChanged newDescriptionName ->
            ( session, { content | description = newDescriptionName }, Cmd.none )

        NewCapsuleSubmitted ->
            ( session
            , { content | status = Status.Sent }
            , Api.newCapsule resultToMsg4 projectId content
            )

        NewCapsuleSuccess _ ->
            ( session
            , { content | status = Status.Success () }
            , Cmd.none
            )


updateUploadSlideShow : UploadSlideShowMsg -> Api.Session -> UploadForm -> Int -> ( Api.Session, UploadForm, Cmd Msg )
updateUploadSlideShow msg session model capsuleId =
    case ( msg, model ) of
        ( UploadSlideShowSelectFileRequested, form ) ->
            ( session
            , model
            , Select.file
                [ "application/pdf" ]
                (\x -> LoggedInMsg (UploadSlideShowMsg (UploadSlideShowFileReady x)))
            )

        ( UploadSlideShowFileReady file, form ) ->
            ( session
            , { form | file = Just file }
            , Cmd.none
            )

        ( UploadSlideShowFormSubmitted, form ) ->
            case form.file of
                Nothing ->
                    ( session, form, Cmd.none )

                Just file ->
                    ( session, form, Api.capsuleUploadSlideShow resultToMsg5 capsuleId file )



-- COMMANDS


resultToMsg : (x -> Msg) -> (e -> Msg) -> Result e x -> Msg
resultToMsg ifSuccess ifError result =
    case result of
        Ok x ->
            ifSuccess x

        Err e ->
            let
                err =
                    debug "Error" e
            in
            ifError err


resultToMsg1 : Result e Api.Session -> Msg
resultToMsg1 result =
    resultToMsg (\x -> LoginMsg (LoginSuccess x)) (\_ -> LoginMsg LoginFailed) result


resultToMsg2 : Result e Api.Project -> Msg
resultToMsg2 result =
    resultToMsg (\x -> LoggedInMsg <| NewProjectMsg <| NewProjectSuccess <| x) (\_ -> Noop) result


resultToMsg3 : Api.Project -> Result e (List Api.Capsule) -> Msg
resultToMsg3 project result =
    resultToMsg (\x -> LoggedInMsg <| CapsulesReceived project x) (\_ -> Noop) result


resultToMsg4 : Result e Api.Capsule -> Msg
resultToMsg4 result =
    resultToMsg (\x -> LoggedInMsg <| NewCapsuleMsg <| NewCapsuleSuccess <| x) (\_ -> Noop) result


resultToMsg5 : Result e Api.CapsuleDetails -> Msg
resultToMsg5 result =
    resultToMsg (\x -> LoggedInMsg <| CapsuleReceived x) (\_ -> Noop) result



-- VIEW


view : FullModel -> Html.Html Msg
view fullModel =
    Element.layout [ Font.size 15 ] (viewContent fullModel)


viewContent : FullModel -> Element Msg
viewContent { global, model } =
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
                    loggedInView global s
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
        submitOnEnter =
            case status of
                Status.Sent ->
                    []

                Status.Success () ->
                    []

                _ ->
                    [ Ui.onEnter LoginSubmitted ]

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
            [ Input.username submitOnEnter
                { label = Input.labelAbove [] (Element.text "Username")
                , onChange = LoginContentUsernameChanged
                , placeholder = Nothing
                , text = username
                }
            , Input.currentPassword submitOnEnter
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
        submitOnEnter =
            case status of
                Status.Sent ->
                    []

                Status.Success () ->
                    []

                _ ->
                    [ Ui.onEnter SignUpSubmitted ]

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
            [ Input.username submitOnEnter
                { label = Input.labelAbove [] (Element.text "Username")
                , onChange = SignUpContentUsernameChanged
                , placeholder = Nothing
                , text = username
                }
            , Input.email submitOnEnter
                { label = Input.labelAbove [] (Element.text "Email")
                , onChange = SignUpContentEmailChanged
                , placeholder = Nothing
                , text = email
                }
            , Input.currentPassword submitOnEnter
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


loggedInView : Global -> LoggedInModel -> Element Msg
loggedInView global { session, page } =
    let
        mainPage =
            case page of
                LoggedInHome ->
                    loggedInHomeView global session

                LoggedInNewProject content ->
                    loggedInNewProjectView session content

                ProjectPage project ->
                    projectPageView session project

                LoggedInNewCapsule _ content ->
                    loggedInNewCapsuleView session content

                CapsulePage capsuleDetails form ->
                    capsulePageView session capsuleDetails form

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


loggedInHomeView : Global -> Api.Session -> Element Msg
loggedInHomeView global session =
    Element.column []
        [ welcomeHeading session.username
        , projectsView global session.projects
        ]


welcomeHeading : String -> Element Msg
welcomeHeading name =
    Element.el [ Font.size 20, Element.padding 10 ] (Element.text ("Welcome " ++ name ++ "!"))


loggedInNewProjectView : Api.Session -> NewProjectContent -> Element Msg
loggedInNewProjectView _ { status, name } =
    let
        submitOnEnter =
            case status of
                Status.Sent ->
                    []

                Status.Success () ->
                    []

                _ ->
                    [ Ui.onEnter NewProjectSubmitted ]

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
            [ Input.text submitOnEnter
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


loggedInNewCapsuleView : Api.Session -> NewCapsuleContent -> Element Msg
loggedInNewCapsuleView _ { status, name, title, description } =
    let
        submitOnEnter =
            case status of
                Status.Sent ->
                    []

                Status.Success () ->
                    []

                _ ->
                    [ Ui.onEnter NewCapsuleSubmitted ]

        submitButton =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "Creating capsule..."

                Status.Success () ->
                    Ui.primaryButtonDisabled "Capsule created!"

                _ ->
                    Ui.primaryButton (Just NewCapsuleSubmitted) "Create capsule"

        message =
            case status of
                Status.Error () ->
                    Just (Ui.errorModal "Capsule creation failed")

                Status.Success () ->
                    Just (Ui.successModal "Capsule created!")

                _ ->
                    Nothing

        header =
            Element.row [ Element.centerX ] [ Element.text "New capsule" ]

        fields =
            [ Input.text submitOnEnter
                { label = Input.labelAbove [] (Element.text "Capsule name")
                , onChange = NewCapsuleNameChanged
                , placeholder = Nothing
                , text = name
                }
            , Input.text submitOnEnter
                { label = Input.labelAbove [] (Element.text "Capsule Title")
                , onChange = NewCapsuleTitleChanged
                , placeholder = Nothing
                , text = title
                }
            , Input.text submitOnEnter
                { label = Input.labelAbove [] (Element.text "Capsule description")
                , onChange = NewCapsuleDescriptionChanged
                , placeholder = Nothing
                , text = description
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
        Element.map NewCapsuleMsg <|
            Element.column [ Element.centerX, Element.padding 10, Element.spacing 10 ]
                form


loggedInUploadSlideShowView : Api.Session -> UploadForm -> Element Msg
loggedInUploadSlideShowView session form =
    Element.column
        [ Element.centerX
        , Element.spacing 10
        , Element.padding 10
        , Border.rounded 5
        , Border.width 1
        , Border.color Colors.grey
        ]
        [ Element.text "Choisir une présentation au format PDF"
        , uploadForm form
        ]


uploadForm : UploadForm -> Element Msg
uploadForm form =
    Element.column [ Element.centerX, Element.spacing 20 ]
        [ Element.row
            [ Element.spacing 20
            , Element.centerX
            ]
            [ selectFileButton
            , fileNameElement form.file
            , uploadButton
            ]
        ]


fileNameElement : Maybe File -> Element Msg
fileNameElement file =
    Element.text <|
        case file of
            Nothing ->
                "No file selected"

            Just realFile ->
                File.name realFile


projectsView : Global -> List Api.Project -> Element Msg
projectsView global projects =
    case projects of
        [] ->
            Element.paragraph [ Element.padding 10, Font.size 18 ]
                [ Element.text "You have no projects yet. "
                , Ui.linkButton
                    (Just (LoggedInMsg NewProjectClicked))
                    "Click here to create a new project!"
                ]

        _ ->
            let
                sortedProjects =
                    List.sortBy (\x -> -x.lastVisited) projects
            in
            Element.column [ Element.padding 10 ]
                [ Element.el [ Font.size 18 ] (Element.text "Your projects:")
                , Element.column [ Element.padding 10, Element.spacing 10 ]
                    (List.map (projectView global) sortedProjects)
                ]


projectView : Global -> Api.Project -> Element Msg
projectView global project =
    Element.row [ Element.spacing 10 ]
        [ Ui.linkButton (Just (LoggedInMsg (ProjectClicked project))) project.name
        , Element.text (TimeUtils.timeToString global.zone project.lastVisited)
        ]


projectPageView : Api.Session -> Api.Project -> Element Msg
projectPageView _ project =
    Element.column [ Element.padding 10 ]
        [ Element.el [ Font.size 18 ] (Element.text ("Capsules for project " ++ project.name))
        , Element.column [ Element.padding 10, Element.spacing 10 ]
            (List.map capsuleView project.capsules)
        ]


capsuleView : Api.Capsule -> Element Msg
capsuleView capsule =
    Element.column [ Element.spacing 10 ]
        [ Ui.linkButton (Just (LoggedInMsg (CapsuleClicked capsule))) capsule.name
        , Element.text capsule.title
        , Element.text capsule.description
        ]


designAttributes : List (Element.Attribute msg)
designAttributes =
    [ Element.padding 10
    , Element.width Element.fill
    , Border.rounded 5
    , Border.width 1
    , Border.color Colors.grey
    ]


designGosAttributes : List (Element.Attribute msg)
designGosAttributes =
    [ Element.padding 10
    , Element.width Element.fill
    , Element.alignTop
    , Border.rounded 5
    , Border.width 1
    , Border.color Colors.grey
    , Background.color Colors.grey
    ]


designSlideAttributes : List (Element.Attribute msg)
designSlideAttributes =
    [ Element.padding 10
    , Element.width Element.fill
    , Border.rounded 5
    , Border.width 1
    , Border.color Colors.white
    , Border.dashed
    ]


capsulePageView : Api.Session -> Api.CapsuleDetails -> UploadForm -> Element Msg
capsulePageView session capsuleDetails form =
    Element.row designAttributes
        [ capsuleInfoView session capsuleDetails form
        , Element.column (Element.centerX :: Element.alignTop :: Background.color Colors.dangerLight :: designAttributes)
            [ Element.el [ Element.centerX ] (Element.text "Timeline présentation")
            , Element.row (Element.spacing 50 :: Background.color Colors.dangerDark :: designAttributes)
                (List.map designSlideView capsuleDetails.slides)
            ]
        ]


capsuleInfoView : Api.Session -> Api.CapsuleDetails -> UploadForm -> Element Msg
capsuleInfoView session capsuleDetails form =
    Element.column [ Element.centerX, Element.alignTop, Element.spacing 10, Element.padding 10 ]
        [ Element.column []
            [ Element.el [ Font.size 20 ] (Element.text "Infos sur la capsule")
            , Element.el [ Font.size 14 ] (Element.text ("Loaded capsule is  " ++ capsuleDetails.capsule.name))
            , Element.el [ Font.size 14 ] (Element.text ("Title :   " ++ capsuleDetails.capsule.title))
            , Element.el [ Font.size 14 ] (Element.text ("Desritpion:  " ++ capsuleDetails.capsule.description))
            ]
        , loggedInUploadSlideShowView session form
        ]


designSlideView : Api.Slide -> Element Msg
designSlideView slide =
    Element.row designSlideAttributes
        [ Element.column [ Element.padding 10, Element.spacing 10, Element.alignTop ]
            [ viewSlideImage slide.asset.asset_path
            , Element.paragraph [ Element.padding 10, Font.size 18 ]
                [ Element.text "Additional Resources "
                , Ui.linkButton
                    (Just (LoggedInMsg NewProjectClicked))
                    "Click here to Add aditional"
                ]
            , Element.el [] (Element.text ("DEBUG: slide_id = " ++ String.fromInt slide.id))
            , Element.el [] (Element.text ("DEBUG: Slide position  = " ++ String.fromInt slide.position))
            , Element.el [] (Element.text ("DEBUG: position in gos = " ++ String.fromInt slide.position_in_gos))
            , Element.el [] (Element.text ("DEBUG: gos = " ++ String.fromInt slide.gos))
            , Element.el [ Font.size 8 ] (Element.text (slide.asset.uuid ++ "_" ++ slide.asset.name))
            ]
        , Element.textColumn
            [ Background.color Colors.white
            , Element.alignTop
            , Element.width
                (Element.fill
                    |> Element.maximum 500
                    |> Element.minimum 200
                )
            ]
            [ Element.text "Prompteur:"
            , Element.paragraph [] [ Element.text (Lorem.sentence 20) ]
            , Element.paragraph [] [ Element.text (Lorem.sentence 30) ]
            , Element.paragraph [] [ Element.text (Lorem.sentence 15) ]
            ]
        ]


viewSlideImage : String -> Element Msg
viewSlideImage url =
    Element.image [ Element.width (Element.px 200) ] { src = url, description = "One desc" }


topBar : Model -> Element Msg
topBar model =
    case model of
        LoggedIn { session, page } ->
            case page of
                ProjectPage { id } ->
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
                                [ newCapsuleButton id ]

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

                _ ->
                    nonFull model

        _ ->
            nonFull model


nonFull : Model -> Element Msg
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


newCapsuleButton : Int -> Element Msg
newCapsuleButton id =
    Ui.textButton (Just (LoggedInMsg (NewCapsuleClicked id))) "New capsule"


loginButton : Element Msg
loginButton =
    Ui.simpleButton (Just LoginClicked) "Log in"


logOutButton : Element Msg
logOutButton =
    Ui.simpleButton (Just LogOutClicked) "Log out"


signUpButton : Element Msg
signUpButton =
    Ui.successButton (Just SignUpClicked) "Sign up"


selectFileButton : Element Msg
selectFileButton =
    Element.map LoggedInMsg <|
        Element.map UploadSlideShowMsg <|
            Ui.simpleButton (Just UploadSlideShowSelectFileRequested) "Select file"


uploadButton : Element Msg
uploadButton =
    Element.map LoggedInMsg <|
        Element.map UploadSlideShowMsg <|
            Ui.primaryButton (Just UploadSlideShowFormSubmitted) "Upload"



-- Auxliary function debug


debug : String -> a -> a
debug message value =
    Debug.log message value



-- Release version
-- debug : String -> a -> a
-- debug message value =
--     value
