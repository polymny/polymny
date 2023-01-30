module Api.Capsule exposing (uploadSlideShow, updateCapsule, addSlide, addGos, replaceSlide, produceCapsule)

{-| This module contains all the functions to deal with the API of capsules.

@docs uploadSlideShow, updateCapsule, addSlide, addGos, replaceSlide, produceCapsule

-}

import Api.Utils as Api
import Data.Capsule as Data
import File exposing (File)
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
    Api.postJson
        { url = "/api/new-capsule/" ++ project ++ "/" ++ name ++ "/"
        , body = Http.fileBody file
        , decoder = Data.decodeCapsule
        , toMsg = toMsg
        }


{-| Updates a caspule on the server.
-}
updateCapsule : Data.Capsule -> (WebData () -> msg) -> Cmd msg
updateCapsule capsule toMsg =
    Api.post
        { url = "/api/update-capsule/"
        , body = Http.jsonBody (Data.encodeCapsule capsule)
        , toMsg = toMsg
        }


{-| Adds a slide to a gos.
-}
addSlide : Data.Capsule -> Int -> Int -> File -> (WebData Data.Capsule -> msg) -> Cmd msg
addSlide capsule gos page file toMsg =
    Api.postWithTrackerJson "toto"
        { url = "/api/add-slide/" ++ capsule.id ++ "/" ++ String.fromInt gos ++ "/" ++ String.fromInt (page - 1)
        , body = Http.fileBody file
        , decoder = Data.decodeCapsule
        , toMsg = toMsg
        }


{-| Adds a gos to a structure.
-}
addGos : Data.Capsule -> Int -> Int -> File -> (WebData Data.Capsule -> msg) -> Cmd msg
addGos capsule gos page file toMsg =
    Api.postWithTrackerJson "toto"
        { url = "/api/add-gos/" ++ capsule.id ++ "/" ++ String.fromInt gos ++ "/" ++ String.fromInt (page - 1)
        , body = Http.fileBody file
        , decoder = Data.decodeCapsule
        , toMsg = toMsg
        }


{-| Replaces a slide.
-}
replaceSlide : Data.Capsule -> Data.Slide -> Int -> File -> (WebData Data.Capsule -> msg) -> Cmd msg
replaceSlide capsule slide page file toMsg =
    Api.postWithTrackerJson "toto"
        { url = "/api/replace-slide/" ++ capsule.id ++ "/" ++ slide.uuid ++ "/" ++ String.fromInt (page - 1)
        , body = Http.fileBody file
        , decoder = Data.decodeCapsule
        , toMsg = toMsg
        }


{-| Triggers the production of a capsule.
-}
produceCapsule : Data.Capsule -> (WebData () -> msg) -> Cmd msg
produceCapsule capsule toMsg =
    Api.post
        { url = "/api/produce/" ++ capsule.id
        , body = Http.emptyBody
        , toMsg = toMsg
        }
