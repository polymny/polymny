module Api.Capsule exposing (uploadSlideShow, updateCapsule)

{-| This module contains all the functions to deal with the API of capsules.

@docs uploadSlideShow, updateCapsule

-}

import Api.Utils as Api
import Data.Capsule as Data
import File
import FileValue
import Http
import RemoteData exposing (WebData)


{-| Uploads a slideshow to the server, creating a new capsule.
-}
uploadSlideShow :
    { project : String, fileValue : FileValue.File, file : File.File, toMsg : WebData Data.Capsule -> msg }
    -> Cmd msg
uploadSlideShow { project, fileValue, file, toMsg } =
    let
        name =
            fileValue.name
                |> String.split "."
                |> List.reverse
                |> List.drop 1
                |> List.reverse
                |> String.join "."
    in
    Api.post
        { url = "/api/new-capsule/" ++ project ++ "/" ++ name ++ "/"
        , body = Http.fileBody file
        , decoder = Data.decodeCapsule
        , toMsg = toMsg
        }


{-| Updates a caspule on the server.
-}
updateCapsule : Data.Capsule -> (WebData Data.Capsule -> msg) -> Cmd msg
updateCapsule capsule toMsg =
    Api.post
        { url = "/api/update-capsule/"
        , body = Http.jsonBody (Data.encodeCapsule capsule)
        , decoder = Data.decodeCapsule
        , toMsg = toMsg
        }
