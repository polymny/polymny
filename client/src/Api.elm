module Api exposing (..)

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


login : (Result Http.Error a -> msg) -> Decoder a -> LoginContent b -> Cmd msg
login resultToMsg decoder content =
    Http.post
        { url = "/api/login"
        , expect = Http.expectJson resultToMsg decoder
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


newProject : (Result Http.Error () -> msg) -> NewProjectContent a -> Cmd msg
newProject resultToMsg content =
    Http.post
        { url = "/api/new-project"
        , expect = Http.expectWhatever resultToMsg
        , body = stringBody (encodeNewProjectContent content)
        }
