module Api.User exposing (..)

{-| This module helps us deal with everything user related.
-}

import Api.Utils as Api
import Http


logout : msg -> Cmd msg
logout msg =
    Api.post { url = "/api/logout", body = Http.emptyBody, toMsg = \_ -> msg }
