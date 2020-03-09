module Setup exposing (main)

import Api
import Browser
import Colors
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Http
import Status exposing (Status)
import Ui


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


type alias Model =
    { database : DatabaseForm
    , mailer : MailerForm
    }


type alias DatabaseForm =
    { status : Status () ()
    , hostname : String
    , username : String
    , password : String
    , name : String
    }


emptyDatabaseForm : DatabaseForm
emptyDatabaseForm =
    DatabaseForm Status.NotSent "" "" "" ""


type alias MailerForm =
    { status : Status () ()
    , enabled : Bool
    , hostname : String
    , username : String
    , password : String
    , destination : String
    }


emptyMailerForm : MailerForm
emptyMailerForm =
    MailerForm Status.NotSent False "" "" "" ""


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model emptyDatabaseForm emptyMailerForm, Cmd.none )



-- MESSAGE


type Msg
    = Noop
    | DatabaseMsg DatabaseMsg
    | MailerMsg MailerMsg


type DatabaseMsg
    = DatabaseUrlChanged String
    | DatabaseUsernameChanged String
    | DatabasePasswordChanged String
    | DatabaseNameChanged String
    | DatabaseSubmit
    | DatabaseTestError
    | DatabaseTestSuccess


type MailerMsg
    = MailerEnabledChanged Bool
    | MailerHostnameChanged String
    | MailerUsernameChanged String
    | MailerPasswordChanged String
    | MailerDestinationChanged String
    | MailerSubmit



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )

        DatabaseMsg dMsg ->
            let
                ( newDb, cmd ) =
                    updateDatabase dMsg model.database
            in
            ( { model | database = newDb }, Cmd.map DatabaseMsg cmd )

        MailerMsg mMsg ->
            let
                ( newMailer, cmd ) =
                    updateMailer mMsg model.mailer
            in
            ( { model | mailer = newMailer }, Cmd.map MailerMsg cmd )


updateDatabase : DatabaseMsg -> DatabaseForm -> ( DatabaseForm, Cmd DatabaseMsg )
updateDatabase msg form =
    case msg of
        DatabaseUrlChanged newHostname ->
            ( { form | hostname = newHostname }, Cmd.none )

        DatabasePasswordChanged newPassword ->
            ( { form | password = newPassword }, Cmd.none )

        DatabaseUsernameChanged newUsername ->
            ( { form | username = newUsername }, Cmd.none )

        DatabaseNameChanged newName ->
            ( { form | name = newName }, Cmd.none )

        DatabaseSubmit ->
            ( { form | status = Status.Sent }, Api.testDatabase databaseResultToMsg form )

        DatabaseTestSuccess ->
            ( { form | status = Status.Success () }, Cmd.none )

        DatabaseTestError ->
            ( { form | status = Status.Error () }, Cmd.none )


updateMailer : MailerMsg -> MailerForm -> ( MailerForm, Cmd MailerMsg )
updateMailer msg form =
    case msg of
        MailerEnabledChanged newEnabled ->
            ( { form | enabled = newEnabled }, Cmd.none )

        MailerHostnameChanged newHostname ->
            ( { form | hostname = newHostname }, Cmd.none )

        MailerUsernameChanged newUsername ->
            ( { form | username = newUsername }, Cmd.none )

        MailerPasswordChanged newPassword ->
            ( { form | password = newPassword }, Cmd.none )

        MailerDestinationChanged newDestination ->
            ( { form | destination = newDestination }, Cmd.none )

        MailerSubmit ->
            ( { form | status = Status.Sent }, Cmd.none )


databaseResultToMsg : Result Http.Error () -> DatabaseMsg
databaseResultToMsg result =
    case result of
        Err _ ->
            DatabaseTestError

        Ok _ ->
            DatabaseTestSuccess



-- VIEW


view : Model -> Html.Html Msg
view fullModel =
    Element.layout [ Font.size 15 ] (viewContent fullModel)


viewContent : Model -> Element Msg
viewContent model =
    Element.column [ Element.width Element.fill ] [ topBar, content model ]


content : Model -> Element Msg
content { database, mailer } =
    let
        bottomBorder =
            { bottom = 1
            , left = 0
            , right = 0
            , top = 0
            }

        attr =
            [ Element.padding 10, Element.spacing 10, Border.widthEach bottomBorder ]
    in
    Element.column [ Element.centerX, Element.padding 10, Element.spacing 10 ]
        [ Element.column attr (databaseView database)
        , Element.column attr (mailerView mailer)
        ]


databaseView : DatabaseForm -> List (Element Msg)
databaseView { status, hostname, username, password, name } =
    let
        msg =
            DatabaseMsg DatabaseSubmit

        submitOnEnter =
            case status of
                Status.Sent ->
                    []

                _ ->
                    [ Ui.onEnter msg ]

        button =
            case status of
                Status.NotSent ->
                    Ui.primaryButton (Just msg) "Test database connection"

                Status.Sent ->
                    Ui.primaryButtonDisabled "Testing database connection..."

                Status.Success _ ->
                    Ui.primaryButton (Just msg) "Connection successful!"

                Status.Error _ ->
                    Ui.primaryButton (Just msg) "Connection failed!"
    in
    [ Element.el [ Element.centerX, Font.bold ] (Element.text "Database configuration")
    , Input.text submitOnEnter
        { label = Input.labelAbove [] (Element.text "Database URL")
        , onChange = \a -> DatabaseMsg (DatabaseUrlChanged a)
        , placeholder = Nothing
        , text = hostname
        }
    , Input.text submitOnEnter
        { label = Input.labelAbove [] (Element.text "Username")
        , onChange = \a -> DatabaseMsg (DatabaseUsernameChanged a)
        , placeholder = Nothing
        , text = username
        }
    , Input.currentPassword submitOnEnter
        { label = Input.labelAbove [] (Element.text "Password")
        , onChange = \a -> DatabaseMsg (DatabasePasswordChanged a)
        , placeholder = Nothing
        , text = password
        , show = False
        }
    , Input.text submitOnEnter
        { label = Input.labelAbove [] (Element.text "Database name")
        , onChange = \a -> DatabaseMsg (DatabaseNameChanged a)
        , placeholder = Nothing
        , text = name
        }
    , button
    ]


mailerView : MailerForm -> List (Element Msg)
mailerView { status, enabled, hostname, username, password, destination } =
    let
        msg =
            MailerMsg MailerSubmit

        createButton =
            if enabled then
                Ui.primaryButton (Just msg)

            else
                Ui.primaryButtonDisabled

        submitOnEnter =
            case status of
                Status.Sent ->
                    []

                _ ->
                    [ Ui.onEnter msg ]

        button =
            case status of
                Status.NotSent ->
                    createButton "Test mailer"

                Status.Sent ->
                    createButton "Testing mailer..."

                Status.Success _ ->
                    createButton "Mail sent successfully!"

                Status.Error _ ->
                    createButton "Mail failed!"

        enableMsg message =
            if enabled then
                message

            else
                Noop

        attr =
            if enabled then
                submitOnEnter

            else
                Background.color Colors.grey :: submitOnEnter
    in
    [ Element.el [ Element.centerX, Font.bold ] (Element.text "Mailer configuration")
    , Input.checkbox []
        { onChange = \x -> MailerMsg (MailerEnabledChanged x)
        , icon = Input.defaultCheckbox
        , checked = enabled
        , label = Input.labelLeft [] (Element.text "Enable mailer")
        }
    , Input.text attr
        { label = Input.labelAbove [] (Element.text "Host")
        , onChange = \a -> enableMsg (MailerMsg (MailerHostnameChanged a))
        , placeholder = Nothing
        , text = hostname
        }
    , Input.text attr
        { label = Input.labelAbove [] (Element.text "Username")
        , onChange = \a -> enableMsg (MailerMsg (MailerUsernameChanged a))
        , placeholder = Nothing
        , text = username
        }
    , Input.currentPassword attr
        { label = Input.labelAbove [] (Element.text "Password")
        , onChange = \a -> enableMsg (MailerMsg (MailerPasswordChanged a))
        , placeholder = Nothing
        , text = password
        , show = False
        }
    , Input.email attr
        { label = Input.labelAbove [] (Element.text "Test email")
        , onChange = \a -> enableMsg (MailerMsg (MailerDestinationChanged a))
        , placeholder = Nothing
        , text = destination
        }
    , button
    ]


topBar : Element Msg
topBar =
    Element.row
        [ Background.color Colors.primary
        , Element.width Element.fill
        , Element.spacing 30
        ]
        [ Element.row
            [ Element.alignLeft, Element.padding 10, Element.spacing 10 ]
            [ homeButton ]
        ]


homeButton : Element Msg
homeButton =
    Element.el [ Font.bold, Font.size 18 ] (Ui.textButton Nothing "Preparation")
