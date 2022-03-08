module Api.Utils exposing (get, post, put, delete, requestWithMethodAndTracker, requestWithMethod, postWithTracker)

{-| This module contains helper that we can use to manage REST APIs easily.

@docs get, post, put, delete, requestWithMethodAndTracker, requestWithMethod, postWithTracker

-}

import Http
import Json.Decode exposing (Decoder)
import RemoteData exposing (WebData)


{-| A generic function to build HTTP requests.
-}
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


{-| A generic function to build HTTP requests with no tracker.
-}
requestWithMethod :
    String
    -> { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg }
    -> Cmd msg
requestWithMethod method param =
    requestWithMethodAndTracker method Nothing param


{-| Helper function to easily build GET requests.
-}
get : { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg } -> Cmd msg
get =
    requestWithMethod "GET"


{-| Helper function to easily build POST requests.
-}
post : { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg } -> Cmd msg
post =
    requestWithMethod "POST"


{-| Helper function to easily build POST requests with trackers.
-}
postWithTracker : String -> { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg } -> Cmd msg
postWithTracker tracker =
    requestWithMethodAndTracker "POST" (Just tracker)


{-| Helper function to easily build PUT requests.
-}
put : { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg } -> Cmd msg
put =
    requestWithMethod "PUT"


{-| Helper function to easily build DELETE requests.
-}
delete : { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg } -> Cmd msg
delete =
    requestWithMethod "DELETE"
