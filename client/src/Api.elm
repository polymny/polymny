module Api exposing (..)

import Admin.Types as Admin
import Capsule exposing (Capsule)
import Core.Types as Core
import File exposing (File)
import FileValue
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Log
import RemoteData
import User


requestWithMethodAndTracker : String -> Maybe String -> { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
requestWithMethodAndTracker method tracker { url, body, expect } =
    Http.request
        { method = method
        , headers = [ Http.header "Accept" "application/json" ]
        , url = url
        , body = body
        , expect = expect
        , timeout = Nothing
        , tracker = tracker
        }


requestWithMethod : String -> { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
requestWithMethod method param =
    requestWithMethodAndTracker method Nothing param


get : { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
get =
    requestWithMethod "GET"


post : { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
post =
    requestWithMethod "POST"


postWithTracker : String -> { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
postWithTracker tracker =
    requestWithMethodAndTracker "POST" (Just tracker)


put : { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
put =
    requestWithMethod "PUT"


delete : { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
delete =
    requestWithMethod "DELETE"


login : (Result Http.Error () -> msg) -> { a | username : String, password : String } -> Cmd msg
login resultToMsg { username, password } =
    post
        { url = "/api/login"
        , expect = Http.expectWhatever resultToMsg
        , body = Http.jsonBody (Encode.object [ ( "username", Encode.string username ), ( "password", Encode.string password ) ])
        }


logout : (Result Http.Error () -> msg) -> Cmd msg
logout resultToMsg =
    post
        { url = "/api/logout"
        , expect = Http.expectWhatever resultToMsg
        , body = Http.emptyBody
        }


requestNewPassword : (Result Http.Error () -> msg) -> { a | email : String } -> Cmd msg
requestNewPassword resultToMsg { email } =
    post
        { url = "/api/request-new-password"
        , expect = Http.expectWhatever resultToMsg
        , body = Http.jsonBody (Encode.object [ ( "email", Encode.string email ) ])
        }


changePassword : (Result Http.Error () -> msg) -> { a | username : String, currentPassword : String, newPassword : String } -> Cmd msg
changePassword resultToMsg { username, currentPassword, newPassword } =
    post
        { url = "/api/change-password"
        , expect = Http.expectWhatever resultToMsg
        , body =
            Encode.object
                [ ( "username_and_old_password", Encode.list Encode.string [ username, currentPassword ] )
                , ( "new_password", Encode.string newPassword )
                ]
                |> Http.jsonBody
        }


changePasswordFromKey : (Result Http.Error () -> msg) -> { a | key : String, newPassword : String } -> Cmd msg
changePasswordFromKey resultToMsg { key, newPassword } =
    post
        { url = "/api/change-password"
        , expect = Http.expectWhatever resultToMsg
        , body = Http.jsonBody (Encode.object [ ( "key", Encode.string key ), ( "new_password", Encode.string newPassword ) ])
        }


changeEmail : (Result Http.Error () -> msg) -> { a | newEmail : String } -> Cmd msg
changeEmail resultToMsg { newEmail } =
    post
        { url = "/api/request-change-email"
        , expect = Http.expectWhatever resultToMsg
        , body =
            Encode.object
                [ ( "new_email", Encode.string newEmail )
                ]
                |> Http.jsonBody
        }


signUp : (Result Http.Error () -> msg) -> { a | username : String, email : String, password : String, registerNewsletter : Bool } -> Cmd msg
signUp resultToMsg { username, email, password, registerNewsletter } =
    post
        { url = "/api/new-user"
        , expect = Http.expectWhatever resultToMsg
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "username", Encode.string username )
                    , ( "email", Encode.string email )
                    , ( "password", Encode.string password )
                    , ( "subscribed", Encode.bool registerNewsletter )
                    ]
                )
        }


deleteUser : (Result Http.Error () -> msg) -> String -> Cmd msg
deleteUser resultToMsg password =
    delete
        { url = "/api/delete-user"
        , expect = Http.expectWhatever resultToMsg
        , body = Http.jsonBody (Encode.object [ ( "current_password", Encode.string password ) ])
        }


getCapsule : (Result Http.Error Capsule -> msg) -> String -> Cmd msg
getCapsule resultToMsg id =
    get
        { url = "/api/capsule/" ++ id
        , expect = Http.expectJson resultToMsg Capsule.decode
        , body = Http.emptyBody
        }


uploadSlideShow : String -> FileValue.File -> Cmd Core.Msg
uploadSlideShow project file =
    let
        name =
            file.name
                |> String.split "."
                |> List.reverse
                |> List.drop 1
                |> List.reverse
                |> String.join "."

        realFile =
            Decode.decodeValue File.decoder file.value

        resultToMsg result =
            case result of
                Ok o ->
                    Core.SlideUploadResponded (RemoteData.Success o)

                Err e ->
                    Core.SlideUploadResponded (RemoteData.Failure e)
    in
    case realFile of
        Ok f ->
            post
                { url = "/api/new-capsule/" ++ project ++ "/" ++ name ++ "/"
                , expect = Http.expectJson resultToMsg Capsule.decode
                , body = Http.fileBody f
                }

        _ ->
            Cmd.none


updateCapsule : Core.Msg -> Capsule -> Cmd Core.Msg
updateCapsule resultToMsg capsule =
    post
        { url = "/api/update-capsule/"
        , expect = Http.expectWhatever (ignoreError (\_ -> resultToMsg))
        , body = Http.jsonBody (Capsule.encode capsule)
        }


deleteProject : Core.Msg -> String -> Cmd Core.Msg
deleteProject resultToMsg project =
    delete
        { url = "/api/project/" ++ project
        , expect = Http.expectWhatever (ignoreError (\_ -> resultToMsg))
        , body = Http.emptyBody
        }


deleteCapsule : (Result Http.Error () -> msg) -> String -> Cmd msg
deleteCapsule resultToMsg id =
    delete
        { url = "/api/capsule/" ++ id
        , expect = Http.expectWhatever resultToMsg
        , body = Http.emptyBody
        }


replaceSlide : (Capsule -> Core.Msg) -> Core.Msg -> String -> String -> Int -> File -> ( String, Cmd Core.Msg )
replaceSlide resultToMsg errorMsg capsuleId uuid page file =
    let
        tracker =
            "toto"
    in
    ( tracker
    , postWithTracker tracker
        { url = "/api/replace-slide/" ++ capsuleId ++ "/" ++ uuid ++ "/" ++ String.fromInt (page - 1)
        , expect =
            Http.expectJson
                (\x ->
                    case x of
                        Ok o ->
                            resultToMsg o

                        _ ->
                            errorMsg
                )
                Capsule.decode
        , body = Http.fileBody file
        }
    )


addSlide : (Capsule -> Core.Msg) -> Core.Msg -> String -> Int -> Int -> File -> ( String, Cmd Core.Msg )
addSlide resultToMsg errorMsg capsuleId gosId page file =
    let
        tracker =
            "toto"
    in
    ( tracker
    , postWithTracker tracker
        { url = "/api/add-slide/" ++ capsuleId ++ "/" ++ String.fromInt gosId ++ "/" ++ String.fromInt (page - 1)
        , expect =
            Http.expectJson
                (\x ->
                    case x of
                        Ok o ->
                            resultToMsg o

                        _ ->
                            errorMsg
                )
                Capsule.decode
        , body = Http.fileBody file
        }
    )


addGos : (Capsule -> Core.Msg) -> Core.Msg -> String -> Int -> Int -> File -> ( String, Cmd Core.Msg )
addGos resultToMsg errorMsg capsuleId gosId page file =
    let
        tracker =
            "toto"
    in
    ( tracker
    , postWithTracker tracker
        { url = "/api/add-gos/" ++ capsuleId ++ "/" ++ String.fromInt gosId ++ "/" ++ String.fromInt (page - 1)
        , expect =
            Http.expectJson
                (\x ->
                    case x of
                        Ok o ->
                            resultToMsg o

                        _ ->
                            errorMsg
                )
                Capsule.decode
        , body = Http.fileBody file
        }
    )


produceVideo : Core.Msg -> Capsule -> Cmd Core.Msg
produceVideo resultToMsg { id } =
    post
        { url = "/api/produce/" ++ id
        , expect = Http.expectWhatever (ignoreError (\_ -> resultToMsg))
        , body = Http.emptyBody
        }


produceGos : Core.Msg -> Capsule -> Int -> Cmd Core.Msg
produceGos resultToMsg { id } gosId =
    post
        { url = "/api/produce-gos/" ++ id ++ "/" ++ String.fromInt gosId
        , expect = Http.expectWhatever (ignoreError (\_ -> resultToMsg))
        , body = Http.emptyBody
        }


cancelProduction : Core.Msg -> Capsule -> Cmd Core.Msg
cancelProduction resultToMsg { id } =
    post
        { url = "/api/cancel-production/" ++ id
        , expect = Http.expectWhatever (ignoreError (\_ -> resultToMsg))
        , body = Http.emptyBody
        }


publishVideo : Core.Msg -> Capsule -> Cmd Core.Msg
publishVideo resultToMsg { id } =
    post
        { url = "/api/publish/" ++ id
        , expect = Http.expectWhatever (ignoreError (\_ -> resultToMsg))
        , body = Http.emptyBody
        }


cancelPublication : Core.Msg -> Capsule -> Cmd Core.Msg
cancelPublication resultToMsg { id } =
    post
        { url = "/api/cancel-publication/" ++ id
        , expect = Http.expectWhatever (ignoreError (\_ -> resultToMsg))
        , body = Http.emptyBody
        }


unpublishVideo : Core.Msg -> Capsule -> Cmd Core.Msg
unpublishVideo resultToMsg { id } =
    post
        { url = "/api/unpublish/" ++ id
        , expect = Http.expectWhatever (ignoreError (\_ -> resultToMsg))
        , body = Http.emptyBody
        }


cancelVideoUpload : Core.Msg -> Capsule -> Cmd Core.Msg
cancelVideoUpload resultToMsg { id } =
    post
        { url = "/api/cancel-video-upload/" ++ id
        , expect = Http.expectWhatever (ignoreError (\_ -> resultToMsg))
        , body = Http.emptyBody
        }


invite : Core.Msg -> Core.Msg -> Capsule -> String -> Capsule.Role -> Cmd Core.Msg
invite onSuccess onError { id } username role =
    post
        { url = "/api/invite/" ++ id
        , expect =
            Http.expectWhatever
                (\x ->
                    case x of
                        Ok _ ->
                            onSuccess

                        _ ->
                            onError
                )
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "username", Encode.string username )
                    , ( "role", Capsule.encodeRole role |> Encode.string )
                    ]
                )
        }


changeRole : Core.Msg -> Core.Msg -> Capsule -> String -> Capsule.Role -> Cmd Core.Msg
changeRole onSuccess onError { id } username role =
    post
        { url = "/api/change-role/" ++ id
        , expect =
            Http.expectWhatever
                (\x ->
                    case x of
                        Ok _ ->
                            onSuccess

                        _ ->
                            onError
                )
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "username", Encode.string username )
                    , ( "role", Capsule.encodeRole role |> Encode.string )
                    ]
                )
        }


deinvite : Core.Msg -> Core.Msg -> Capsule -> String -> Cmd Core.Msg
deinvite onSuccess onError { id } username =
    post
        { url = "/api/deinvite/" ++ id
        , expect =
            Http.expectWhatever
                (\x ->
                    case x of
                        Ok _ ->
                            onSuccess

                        _ ->
                            onError
                )
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "username", Encode.string username )
                    ]
                )
        }


markNotificationAsRead : Core.Msg -> User.Notification -> Cmd Core.Msg
markNotificationAsRead resultToMsg notif =
    post
        { url = "/api/mark-as-read/" ++ String.fromInt notif.id
        , expect = Http.expectWhatever (ignoreError (\_ -> resultToMsg))
        , body = Http.emptyBody
        }


deleteNotification : Core.Msg -> User.Notification -> Cmd Core.Msg
deleteNotification resultToMsg notif =
    delete
        { url = "/api/notification/" ++ String.fromInt notif.id
        , expect = Http.expectWhatever (ignoreError (\_ -> resultToMsg))
        , body = Http.emptyBody
        }


ignoreError : (a -> Core.Msg) -> Result Http.Error a -> Core.Msg
ignoreError convert value =
    case value of
        Err e ->
            let
                _ =
                    Log.debug "error" e
            in
            Core.Noop

        Ok o ->
            convert o


dashboard : (Result Http.Error String -> msg) -> Cmd msg
dashboard resultToMsg =
    get
        { url = "/api/admin/dashboard"
        , expect = Http.expectJson resultToMsg (Decode.field "stats" Decode.string)
        , body = Http.emptyBody
        }


adminUsers : (Result Http.Error (List Admin.User) -> msg) -> Int -> Cmd msg
adminUsers resultToMsg pagination =
    get
        { url = "/api/admin/users/" ++ String.fromInt pagination
        , expect = Http.expectJson resultToMsg (Decode.list Admin.decodeUser)
        , body = Http.emptyBody
        }


adminSearchUsers : (Result Http.Error (List Admin.User) -> msg) -> { a | usernameSearch : Maybe String, emailSearch : Maybe String } -> Cmd msg
adminSearchUsers resultToMsg { usernameSearch, emailSearch } =
    let
        query =
            [ Maybe.map (\x -> "username=" ++ x) usernameSearch
            , Maybe.map (\x -> "email=" ++ x) emailSearch
            ]
                |> List.filterMap (\x -> x)
                |> String.join "&"
    in
    get
        { url = "/api/admin/searchusers?" ++ query
        , expect = Http.expectJson resultToMsg (Decode.list Admin.decodeUser)
        , body = Http.emptyBody
        }


adminUser : (Result Http.Error Admin.User -> msg) -> Int -> Cmd msg
adminUser resultToMsg id =
    get
        { url = "/api/admin/user/" ++ String.fromInt id
        , expect = Http.expectJson resultToMsg Admin.decodeUser
        , body = Http.emptyBody
        }


adminDeleteUser : (Result Http.Error () -> msg) -> Int -> Cmd msg
adminDeleteUser resultToMsg id =
    delete
        { url = "/api/admin/user/" ++ String.fromInt id
        , expect = Http.expectWhatever resultToMsg
        , body = Http.emptyBody
        }


adminCapsules : (Result Http.Error (List Capsule) -> msg) -> Int -> Cmd msg
adminCapsules resultToMsg pagination =
    get
        { url = "/api/admin/capsules/" ++ String.fromInt pagination
        , expect = Http.expectJson resultToMsg (Decode.list Capsule.decode)
        , body = Http.emptyBody
        }


adminSearchCapsules : (Result Http.Error (List Capsule) -> msg) -> { a | capsuleSearch : Maybe String, projectSearch : Maybe String } -> Cmd msg
adminSearchCapsules resultToMsg { capsuleSearch, projectSearch } =
    let
        query =
            [ Maybe.map (\x -> "capsule=" ++ x) capsuleSearch
            , Maybe.map (\x -> "project=" ++ x) projectSearch
            ]
                |> List.filterMap (\x -> x)
                |> String.join "&"
    in
    get
        { url = "/api/admin/searchcapsules?" ++ query
        , expect = Http.expectJson resultToMsg (Decode.list Capsule.decode)
        , body = Http.emptyBody
        }


adminInvite : (Result Http.Error () -> msg) -> { a | inviteUsername : String, inviteEmail : String } -> Cmd msg
adminInvite resultToMsg { inviteUsername, inviteEmail } =
    post
        { url = "/api/admin/invite-user"
        , expect = Http.expectWhatever resultToMsg
        , body =
            Encode.object
                [ ( "username", Encode.string inviteUsername )
                , ( "email", Encode.string inviteEmail )
                ]
                |> Http.jsonBody
        }


adminClearWebsockets : Cmd Core.Msg
adminClearWebsockets =
    get
        { url = "/api/admin/clear-websockets"
        , expect = Http.expectWhatever (\_ -> Core.Noop)
        , body = Http.emptyBody
        }


validateInvitation : (Result Http.Error () -> msg) -> { a | password : String, key : String } -> Cmd msg
validateInvitation resultToMsg { password, key } =
    post
        { url = "/api/request-invitation"
        , expect = Http.expectWhatever resultToMsg
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "password", Encode.string password )
                    , ( "key", Encode.string key )
                    ]
                )
        }
