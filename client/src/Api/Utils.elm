module Api.Utils exposing (get, post, put, delete, requestWithMethodAndTracker, postWithTracker)

{-| This module contains helper that we can use to manage REST APIs easily.

@docs get, post, put, delete, requestWithMethodAndTracker, requestWithMethod, postWithTracker

-}

import Http
import Json.Decode exposing (Decoder)
import RemoteData exposing (WebData)


requestWithMethodAndTracker :
    String
    -> Maybe String
    -> { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg }
    -> Cmd msg
requestWithMethodAndTracker method tracker { url, body, decoder, toMsg } =
    Http.request
        { method = method
        , headers = [ Http.header "Accept" "application/json" ]
        , url = url
        , body = body
        , expect = Http.expectJson (\x -> toMsg (RemoteData.fromResult x)) decoder
        , timeout = Nothing
        , tracker = tracker
        }


requestWithMethod :
    String
    -> { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg }
    -> Cmd msg
requestWithMethod method param =
    requestWithMethodAndTracker method Nothing param


get : { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg } -> Cmd msg
get =
    requestWithMethod "GET"


post : { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg } -> Cmd msg
post =
    requestWithMethod "POST"


postWithTracker : String -> { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg } -> Cmd msg
postWithTracker tracker =
    requestWithMethodAndTracker "POST" (Just tracker)


put : { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg } -> Cmd msg
put =
    requestWithMethod "PUT"


delete : { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg } -> Cmd msg
delete =
    requestWithMethod "DELETE"
