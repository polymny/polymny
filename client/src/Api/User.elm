module Api.User exposing (..)

{-| This module helps us deal with everything user related.
-}

import Api.Utils as Api
import Data.Types as Data
import Data.User as Data exposing (User)
import Http
import Json.Encode as Encode
import RemoteData exposing (WebData)


{-| Login with username and password.
-}
login : Data.SortBy -> String -> String -> (WebData User -> msg) -> Cmd msg
login sortBy username password toMsg =
    Api.postJson
        { url = "/api/login"
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "username", Encode.string username )
                    , ( "password", Encode.string password )
                    ]
                )
        , toMsg = toMsg
        , decoder = Data.decodeUser sortBy
        }


{-| Logs out the current user.
-}
logout : msg -> Cmd msg
logout msg =
    Api.post { url = "/api/logout", body = Http.emptyBody, toMsg = \_ -> msg }


{-| Asks the server to authenticate via email to reset a forgotten password.
-}
requestNewPassword : String -> (WebData () -> msg) -> Cmd msg
requestNewPassword email toMsg =
    Api.post
        { url = "/api/request-new-password"
        , toMsg = toMsg
        , body = Http.jsonBody <| Encode.object [ ( "email", Encode.string email ) ]
        }
