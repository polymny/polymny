module Api.Utils exposing
    ( requestWithMethodAndTracker, requestWithMethodAndTrackerJson, requestWithMethod, requestWithMethodJson
    , get, post, put, delete
    , getJson, postJson, putJson, deleteJson
    , postWithTracker, postWithTrackerJson
    )

{-| This module contains helper that we can use to manage REST APIs easily.


# Generic functions

@docs requestWithMethodAndTracker, requestWithMethodAndTrackerJson, requestWithMethod, requestWithMethodJson


# Classical functions

@docs get, post, put, delete


# Classic functions with JSON data in response

@docs getJson, postJson, putJson, deleteJson


# With trackers

@docs postWithTracker, postWithTrackerJson

-}

import Http
import Json.Decode exposing (Decoder)
import RemoteData exposing (WebData)


{-| A generic function to build HTTP requests.
-}
requestWithMethodAndTracker :
    String
    -> Maybe String
    -> { url : String, body : Http.Body, toMsg : WebData () -> msg }
    -> Cmd msg
requestWithMethodAndTracker method tracker { url, body, toMsg } =
    Http.request
        { method = method
        , headers = [ Http.header "Accept" "application/json" ]
        , url = url
        , body = body
        , expect = Http.expectWhatever (\x -> toMsg (RemoteData.fromResult x))
        , timeout = Nothing
        , tracker = tracker
        }


{-| A generic function to build HTTP requests that expects JSON data in the response.
-}
requestWithMethodAndTrackerJson :
    String
    -> Maybe String
    -> { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg }
    -> Cmd msg
requestWithMethodAndTrackerJson method tracker { url, body, decoder, toMsg } =
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
    -> { url : String, body : Http.Body, toMsg : WebData () -> msg }
    -> Cmd msg
requestWithMethod method param =
    requestWithMethodAndTracker method Nothing param


{-| Helper function to easily build GET requests.
-}
get : { url : String, body : Http.Body, toMsg : WebData () -> msg } -> Cmd msg
get =
    requestWithMethod "GET"


{-| Helper function to easily build POST requests.
-}
post : { url : String, body : Http.Body, toMsg : WebData () -> msg } -> Cmd msg
post =
    requestWithMethod "POST"


{-| Helper function to easily build POST requests with trackers.
-}
postWithTracker : String -> { url : String, body : Http.Body, toMsg : WebData () -> msg } -> Cmd msg
postWithTracker tracker =
    requestWithMethodAndTracker "POST" (Just tracker)


{-| Helper function to easily build PUT requests.
-}
put : { url : String, body : Http.Body, toMsg : WebData () -> msg } -> Cmd msg
put =
    requestWithMethod "PUT"


{-| Helper function to easily build DELETE requests.
-}
delete : { url : String, body : Http.Body, toMsg : WebData () -> msg } -> Cmd msg
delete =
    requestWithMethod "DELETE"


{-| A generic function to build HTTP requests with no tracker that expects JSON data in the response.
-}
requestWithMethodJson :
    String
    -> { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg }
    -> Cmd msg
requestWithMethodJson method param =
    requestWithMethodAndTrackerJson method Nothing param


{-| Helper function to easily build GET requests that expects JSON data in the response.
-}
getJson : { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg } -> Cmd msg
getJson =
    requestWithMethodJson "GET"


{-| Helper function to easily build POST requests that expects JSON data in the response.
-}
postJson : { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg } -> Cmd msg
postJson =
    requestWithMethodJson "POST"


{-| Helper function to easily build POST requests with trackers that expects JSON data in the response.
-}
postWithTrackerJson : String -> { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg } -> Cmd msg
postWithTrackerJson tracker =
    requestWithMethodAndTrackerJson "POST" (Just tracker)


{-| Helper function to easily build PUT requests that expects JSON data in the response.
-}
putJson : { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg } -> Cmd msg
putJson =
    requestWithMethodJson "PUT"


{-| Helper function to easily build DELETE requests that expects JSON data in the response.
-}
deleteJson : { url : String, body : Http.Body, decoder : Decoder a, toMsg : WebData a -> msg } -> Cmd msg
deleteJson =
    requestWithMethodJson "DELETE"
