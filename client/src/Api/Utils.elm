module Api.Utils exposing
    ( get, post, put, delete, requestWithMethodAndTracker, postWithTracker
    , getJson, postJson
    )

{-| This module contains helper that we can use to manage REST APIs easily.

@docs get, post, put, delete, requestWithMethodAndTracker, requestWithMethod, postWithTracker

-}

import Http
import Json.Decode as Decode exposing (Decoder)
import RemoteData exposing (RemoteData)


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


getJson : { url : String, body : Http.Body, decoder : Decoder a, resultToMsg : RemoteData Http.Error a -> msg } -> Cmd msg
getJson { url, body, decoder, resultToMsg } =
    get
        { url = url
        , body = body
        , expect = Http.expectJson (\x -> resultToMsg (RemoteData.fromResult x)) decoder
        }


post : { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
post =
    requestWithMethod "POST"


postJson : { url : String, body : Http.Body, decoder : Decoder a, resultToMsg : RemoteData Http.Error a -> msg } -> Cmd msg
postJson { url, body, decoder, resultToMsg } =
    post
        { url = url
        , body = body
        , expect = Http.expectJson (\x -> resultToMsg (RemoteData.fromResult x)) decoder
        }


postWithTracker : String -> { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
postWithTracker tracker =
    requestWithMethodAndTracker "POST" (Just tracker)


put : { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
put =
    requestWithMethod "PUT"


delete : { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
delete =
    requestWithMethod "DELETE"
