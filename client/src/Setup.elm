module Setup exposing (main)

import Api
import Browser
import Colors
import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Html
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
    }


type alias DatabaseForm =
    { status : Status () ()
    , url : String
    , username : String
    , password : String
    , name : String
    }


emptyDatabaseForm : DatabaseForm
emptyDatabaseForm =
    DatabaseForm Status.NotSent "" "" "" ""


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model emptyDatabaseForm, Cmd.none )



-- MESSAGE


type Msg
    = Noop
    | DatabaseMsg DatabaseMsg


type DatabaseMsg
    = DatabaseUrlChanged String
    | DatabaseUsernameChanged String
    | DatabasePasswordChanged String
    | DatabaseNameChanged String



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


updateDatabase : DatabaseMsg -> DatabaseForm -> ( DatabaseForm, Cmd DatabaseMsg )
updateDatabase msg form =
    case msg of
        DatabaseUrlChanged newUrl ->
            ( { form | url = newUrl }, Cmd.none )

        DatabasePasswordChanged newPassword ->
            ( { form | password = newPassword }, Cmd.none )

        DatabaseUsernameChanged newUsername ->
            ( { form | username = newUsername }, Cmd.none )

        DatabaseNameChanged newName ->
            ( { form | name = newName }, Cmd.none )



-- VIEW


view : Model -> Html.Html Msg
view fullModel =
    Element.layout [ Font.size 15 ] (viewContent fullModel)


viewContent : Model -> Element Msg
viewContent model =
    Element.column [ Element.width Element.fill ] [ topBar, content model ]


content : Model -> Element Msg
content { database } =
    Element.column
        [ Element.centerX, Element.padding 10, Element.spacing 10 ]
        (databaseView database)


databaseView : DatabaseForm -> List (Element Msg)
databaseView database =
    [ Element.el [ Element.centerX, Font.bold ] (Element.text "Database configuration")
    , Input.text []
        { label = Input.labelAbove [] (Element.text "Database URL")
        , onChange = \a -> DatabaseMsg (DatabaseUrlChanged a)
        , placeholder = Nothing
        , text = database.url
        }
    , Input.text []
        { label = Input.labelAbove [] (Element.text "Username")
        , onChange = \a -> DatabaseMsg (DatabaseUsernameChanged a)
        , placeholder = Nothing
        , text = database.username
        }
    , Input.currentPassword []
        { label = Input.labelAbove [] (Element.text "Password")
        , onChange = \a -> DatabaseMsg (DatabasePasswordChanged a)
        , placeholder = Nothing
        , text = database.password
        , show = False
        }
    , Input.text []
        { label = Input.labelAbove [] (Element.text "Database name")
        , onChange = \a -> DatabaseMsg (DatabaseNameChanged a)
        , placeholder = Nothing
        , text = database.name
        }
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
