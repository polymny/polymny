module Setup exposing (main)

import Api
import Browser
import Browser.Navigation
import Core.Types as Core
import Core.Utils as Core
import Core.Views as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Http
import Json.Decode as Decode
import Status exposing (Status)
import Ui.Attributes as Attributes
import Ui.Colors as Colors
import Ui.Ui as Ui
import Url


main : Program Decode.Value FullModel Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        , onUrlChange = always Noop
        , onUrlRequest = always Noop
        }



-- MODEL


type FullModel
    = Configuring Core.Global Model
    | Finished Core.Global


type alias Model =
    { status : Status () ()
    , database : DatabaseForm
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
    , requireMailConfirmation : Bool
    , hostname : String
    , username : String
    , password : String
    , recipient : String
    }


emptyMailerForm : MailerForm
emptyMailerForm =
    MailerForm Status.NotSent True True "" "" "" ""


init : Decode.Value -> Url.Url -> Browser.Navigation.Key -> ( FullModel, Cmd Msg )
init flags url key =
    let
        global =
            Core.globalFromFlags flags key
    in
    ( Configuring global (Model Status.NotSent emptyDatabaseForm emptyMailerForm), Cmd.none )



-- MESSAGE


type Msg
    = Noop
    | DatabaseMsg DatabaseMsg
    | MailerMsg MailerMsg
    | SubmitConfiguration
    | SubmissionFailed
    | SubmissionSuccessful


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
    | MailerRequireMailConfirmationChanged Bool
    | MailerHostnameChanged String
    | MailerUsernameChanged String
    | MailerPasswordChanged String
    | MailerRecipientChanged String
    | MailerSubmit
    | MailerTestError
    | MailerTestSuccess



-- UPDATE


update : Msg -> FullModel -> ( FullModel, Cmd Msg )
update msg fullModel =
    case ( fullModel, msg ) of
        ( Configuring global model, Noop ) ->
            ( Configuring global model, Cmd.none )

        ( Configuring global model, DatabaseMsg dMsg ) ->
            let
                ( newDb, cmd ) =
                    updateDatabase dMsg model.database
            in
            ( Configuring global { model | database = newDb }, Cmd.map DatabaseMsg cmd )

        ( Configuring global model, MailerMsg mMsg ) ->
            let
                ( newMailer, cmd ) =
                    updateMailer mMsg model.mailer
            in
            ( Configuring global { model | mailer = newMailer }, Cmd.map MailerMsg cmd )

        ( Configuring global model, SubmitConfiguration ) ->
            ( Configuring global { model | status = Status.Sent }, Api.setupConfig submitResultToMsg model.database model.mailer )

        ( Configuring global model, SubmissionFailed ) ->
            ( Configuring global { model | status = Status.Error () }, Cmd.none )

        ( Configuring global _, SubmissionSuccessful ) ->
            ( Finished global, Cmd.none )

        ( Finished global, _ ) ->
            ( Finished global, Cmd.none )


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

        MailerRequireMailConfirmationChanged new ->
            ( { form | requireMailConfirmation = new }, Cmd.none )

        MailerHostnameChanged newHostname ->
            ( { form | hostname = newHostname }, Cmd.none )

        MailerUsernameChanged newUsername ->
            ( { form | username = newUsername }, Cmd.none )

        MailerPasswordChanged newPassword ->
            ( { form | password = newPassword }, Cmd.none )

        MailerRecipientChanged newRecipient ->
            ( { form | recipient = newRecipient }, Cmd.none )

        MailerSubmit ->
            ( { form | status = Status.Sent }, Api.testMailer mailerResultToMsg form )

        MailerTestSuccess ->
            ( { form | status = Status.Success () }, Cmd.none )

        MailerTestError ->
            ( { form | status = Status.Error () }, Cmd.none )


databaseResultToMsg : Result Http.Error () -> DatabaseMsg
databaseResultToMsg result =
    case result of
        Err _ ->
            DatabaseTestError

        Ok _ ->
            DatabaseTestSuccess


mailerResultToMsg : Result Http.Error () -> MailerMsg
mailerResultToMsg result =
    case result of
        Err _ ->
            MailerTestError

        Ok _ ->
            MailerTestSuccess


submitResultToMsg : Result Http.Error () -> Msg
submitResultToMsg result =
    case result of
        Err _ ->
            SubmissionFailed

        Ok _ ->
            SubmissionSuccessful



-- VIEW


view : FullModel -> Browser.Document Msg
view fullModel =
    { title = "Polymny"
    , body = [ Element.layout Attributes.fullModelAttributes (viewContent fullModel) ]
    }


viewContent : FullModel -> Element Msg
viewContent model =
    let
        global =
            case model of
                Configuring g _ ->
                    g

                Finished g ->
                    g

        m =
            Core.Home Core.HomeAbout

        top =
            Core.topBar global m |> Element.map (always Noop)
    in
    Element.column
        (Element.height Element.fill
            :: Element.scrollbarY
            :: Element.width Element.fill
            :: Background.color Colors.light
            :: []
        )
        [ top, content model ]


content : FullModel -> Element Msg
content fullModel =
    case fullModel of
        Configuring global model ->
            configuringContent model

        Finished global ->
            Element.column [ Element.centerX ]
                [ Element.el [ Font.bold ] (Element.text "Congratulations")
                , Element.text "Your server is now configured, you can restart it to launch the application"
                ]


configuringContent : Model -> Element Msg
configuringContent { database, mailer } =
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
        , Ui.primaryButton (Just SubmitConfiguration) "Set configuration"
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
mailerView { status, enabled, hostname, username, password, recipient, requireMailConfirmation } =
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
    , Input.checkbox []
        { onChange = \x -> MailerMsg (MailerRequireMailConfirmationChanged x)
        , icon = Input.defaultCheckbox
        , checked = requireMailConfirmation
        , label = Input.labelLeft [] (Element.text "Require email confirmation")
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
        { label = Input.labelAbove [] (Element.text "Recipient of the test email")
        , onChange = \a -> enableMsg (MailerMsg (MailerRecipientChanged a))
        , placeholder = Nothing
        , text = recipient
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
