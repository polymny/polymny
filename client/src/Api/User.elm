module Api.User exposing (..)

{-| This module helps us deal with everything user related.
-}

import Api.Utils as Api
import Data.Capsule exposing (Capsule)
import Data.Types as Data
import Data.User as Data exposing (User)
import Http
import Json.Encode as Encode
import RemoteData exposing (WebData)


{-| Login with username and password.
-}
login : String -> Data.SortBy -> String -> String -> (WebData User -> msg) -> Cmd msg
login root sortBy username password toMsg =
    Api.postJson
        { url = root ++ "/api/login"
        , body =
            Http.jsonBody <|
                Encode.object
                    [ ( "username", Encode.string username )
                    , ( "password", Encode.string password )
                    ]
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
requestNewPassword : String -> String -> (WebData () -> msg) -> Cmd msg
requestNewPassword root email toMsg =
    Api.post
        { url = root ++ "/api/request-new-password"
        , toMsg = toMsg
        , body = Http.jsonBody <| Encode.object [ ( "email", Encode.string email ) ]
        }


{-| Tells the server to change the password after a forgotten password.
-}
resetPassword : Data.SortBy -> String -> String -> (WebData User -> msg) -> Cmd msg
resetPassword sortBy key newPassword toMsg =
    Api.postJson
        { url = "/api/change-password"
        , body =
            Http.jsonBody <|
                Encode.object
                    [ ( "key", Encode.string key )
                    , ( "new_password", Encode.string newPassword )
                    ]
        , toMsg = toMsg
        , decoder = Data.decodeUser sortBy
        }


{-| Changes the password of the user.
-}
changePassword : User -> String -> String -> (WebData () -> msg) -> Cmd msg
changePassword user oldPassword newPassword toMsg =
    Api.post
        { url = "/api/change-password"
        , body =
            Http.jsonBody <|
                Encode.object
                    [ ( "username_and_old_password", Encode.list Encode.string [ user.username, oldPassword ] )
                    , ( "new_password", Encode.string newPassword )
                    ]
        , toMsg = toMsg
        }


{-| Creates a new Polymny account.
-}
signUp : String -> { a | username : String, email : String, password : String, signUpForNewsletter : Bool } -> (WebData () -> msg) -> Cmd msg
signUp root { username, email, password, signUpForNewsletter } toMsg =
    Api.post
        { url = root ++ "/api/new-user"
        , body =
            Http.jsonBody <|
                Encode.object
                    [ ( "username", Encode.string username )
                    , ( "email", Encode.string email )
                    , ( "password", Encode.string password )
                    , ( "subscribed", Encode.bool signUpForNewsletter )
                    ]
        , toMsg = toMsg
        }


{-| Requests to change the email of a user.
-}
changeEmail : String -> (WebData () -> msg) -> Cmd msg
changeEmail newEmail toMsg =
    Api.post
        { url = "/api/request-change-email"
        , body = Http.jsonBody <| Encode.object [ ( "new_email", Encode.string newEmail ) ]
        , toMsg = toMsg
        }


{-| Requests to delete your account.
-}
deleteAccount : String -> (WebData () -> msg) -> Cmd msg
deleteAccount password toMsg =
    Api.delete
        { url = "/api/delete-user"
        , body = Http.jsonBody <| Encode.object [ ( "current_password", Encode.string password ) ]
        , toMsg = toMsg
        }


{-| Requests to delete a capsule.
-}
deleteCapsule : Capsule -> (WebData () -> msg) -> Cmd msg
deleteCapsule capsule toMsg =
    let
        capsuleId =
            capsule.id

        isOwner =
            capsule.role == Data.Owner
    in
    if isOwner then
        Api.delete
            { url = "/api/capsule/" ++ capsuleId
            , body = Http.emptyBody
            , toMsg = toMsg
            }

    else
        Api.post
            { url = "/api/leave/" ++ capsuleId
            , body = Http.emptyBody
            , toMsg = toMsg
            }

{-| Requests to delete a project.
-}
deleteProject : String -> (WebData () -> msg) -> Cmd msg
deleteProject projectId toMsg =
    Api.delete
        { url = "/api/project/" ++ projectId
        , body = Http.emptyBody
        , toMsg = toMsg
        }