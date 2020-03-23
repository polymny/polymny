module Api exposing
    ( Capsule
    , Project
    , Session
    , capsulesFromProjectId
    , createProject
    , decodeCapsule
    , decodeCapsules
    , decodeProject
    , decodeSession
    , logOut
    , login
    , newCapsule
    , newProject
    , signUp
    , testDatabase
    )

import Http
import Json.Decode as Decode exposing (Decoder)


encode : List ( String, String ) -> String
encode strings =
    String.join "&" (List.map (\( x, y ) -> x ++ "=" ++ y) strings)


stringBody : String -> Http.Body
stringBody string =
    Http.stringBody
        "application/x-www-form-urlencoded"
        string



-- Api types


type alias Project =
    { id : Int
    , name : String
    , lastVisited : Int
    , capsules : List Capsule
    }


createProject : Int -> String -> Int -> Project
createProject id name lastVisited =
    Project id name lastVisited []


type alias Capsule =
    { id : Int
    , name : String
    , title : String
    , description : String
    }


decodeCapsule : Decoder Capsule
decodeCapsule =
    Decode.map4 Capsule
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.string)


decodeCapsules : Decoder (List Capsule)
decodeCapsules =
    Decode.list decodeCapsule


withCapsules : List Capsule -> Int -> String -> Int -> Project
withCapsules capsules id name lastVisited =
    Project id name lastVisited capsules


decodeProject : List Capsule -> Decoder Project
decodeProject capsules =
    Decode.map3 (withCapsules capsules)
        (Decode.field "id" Decode.int)
        (Decode.field "project_name" Decode.string)
        (Decode.field "last_visited" Decode.int)


type alias Session =
    { username : String
    , projects : List Project
    }


decodeSession : Decoder Session
decodeSession =
    Decode.map2 Session
        (Decode.field "username" Decode.string)
        (Decode.field "projects" (Decode.list (decodeProject [])))



-- Sign up form


type alias SignUpContent a =
    { a
        | username : String
        , password : String
        , email : String
    }


encodeSignUpContent : SignUpContent a -> String
encodeSignUpContent { username, password, email } =
    encode
        [ ( "username", username )
        , ( "password", password )
        , ( "email", email )
        ]


signUp : (Result Http.Error () -> msg) -> SignUpContent a -> Cmd msg
signUp responseToMsg content =
    Http.post
        { url = "/api/new-user/"
        , expect = Http.expectWhatever responseToMsg
        , body = stringBody (encodeSignUpContent content)
        }



-- Log in form


type alias LoginContent a =
    { a
        | username : String
        , password : String
    }


encodeLoginContent : LoginContent a -> String
encodeLoginContent { username, password } =
    encode
        [ ( "username", username )
        , ( "password", password )
        ]


login : (Result Http.Error Session -> msg) -> LoginContent b -> Cmd msg
login resultToMsg content =
    Http.post
        { url = "/api/login"
        , expect = Http.expectJson resultToMsg decodeSession
        , body = stringBody (encodeLoginContent content)
        }


logOut : (Result Http.Error () -> msg) -> Cmd msg
logOut resultToMsg =
    Http.post
        { url = "/api/logout"
        , expect = Http.expectWhatever resultToMsg
        , body = Http.emptyBody
        }



-- New project form


type alias NewProjectContent a =
    { a
        | name : String
    }


encodeNewProjectContent : NewProjectContent a -> String
encodeNewProjectContent { name } =
    encode
        [ ( "project_name", name )
        ]


newProject : (Result Http.Error Project -> msg) -> NewProjectContent a -> Cmd msg
newProject resultToMsg content =
    Http.post
        { url = "/api/new-project"
        , expect = Http.expectJson resultToMsg (decodeProject [])
        , body = stringBody (encodeNewProjectContent content)
        }



-- Project page


capsulesFromProjectId : (Result Http.Error (List Capsule) -> msg) -> Int -> Cmd msg
capsulesFromProjectId resultToMsg id =
    Http.get
        { url = "/api/project/" ++ String.fromInt id ++ "/capsules"
        , expect = Http.expectJson resultToMsg decodeCapsules
        }



-- New capsule  form


type alias NewCapsuleContent a =
    { a
        | name : String
        , title : String
        , description : String
    }


encodeNewCapsuleContent : Int -> NewCapsuleContent a -> String
encodeNewCapsuleContent projectId { name, title, description } =
    encode
        [ ( "name", name )
        , ( "title", title )
        , ( "description", description )
        , ( "project_id", String.fromInt projectId )
        ]


newCapsule : (Result Http.Error Capsule -> msg) -> Int -> NewCapsuleContent a -> Cmd msg
newCapsule resultToMsg projectId content =
    Http.post
        { url = "/api/new-capsule"
        , expect = Http.expectJson resultToMsg decodeCapsule
        , body = stringBody (encodeNewCapsuleContent projectId content)
        }



-- Setup forms


type alias DatabaseTestContent a =
    { a
        | hostname : String
        , username : String
        , password : String
        , name : String
    }


encodeDatabaseTestContent : DatabaseTestContent a -> String
encodeDatabaseTestContent { hostname, username, password, name } =
    encode
        [ ( "hostname", hostname )
        , ( "username", username )
        , ( "password", password )
        , ( "name", name )
        ]


testDatabase : (Result Http.Error () -> msg) -> DatabaseTestContent a -> Cmd msg
testDatabase resultToMsg content =
    Http.post
        { url = "/api/test-database"
        , expect = Http.expectWhatever resultToMsg
        , body = stringBody (encodeDatabaseTestContent content)
        }
