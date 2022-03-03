module Api.Utils exposing (get, post, put, delete, requestWithMethodAndTracker, postWithTracker)

{-| This module contains helper that we can use to manage REST APIs easily.

@docs get, post, put, delete, requestWithMethodAndTracker, requestWithMethod, postWithTracker

-}

import Http


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
