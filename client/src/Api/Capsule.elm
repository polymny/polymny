module Api.Capsule exposing (uploadSlideShow, updateCapsule, duplicateCapsule, addSlide, addGos, replaceSlide, produceCapsule, publishCapsule, unpublishCapsule, uploadTrack, deleteRecord)

{-| This module contains all the functions to deal with the API of capsules.

@docs uploadSlideShow, updateCapsule, duplicateCapsule, addSlide, addGos, replaceSlide, produceCapsule, publishCapsule, unpublishCapsule, uploadTrack, deleteRecord

-}

import Api.Utils as Api
import Config
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
addSlide : Data.Capsule -> Int -> Int -> File -> Config.TaskId -> (WebData Data.Capsule -> msg) -> Cmd msg
addSlide capsule gos page file taskId toMsg =
    Api.postWithTrackerJson ("task-track-" ++ String.fromInt taskId)
        { url = "/api/add-slide/" ++ capsule.id ++ "/" ++ String.fromInt gos ++ "/" ++ String.fromInt (page - 1)
        , body = Http.fileBody file
        , decoder = Data.decodeCapsule
        , toMsg = toMsg
        }


{-| Adds a gos to a structure.
-}
addGos : Data.Capsule -> Int -> Int -> File -> Config.TaskId -> (WebData Data.Capsule -> msg) -> Cmd msg
addGos capsule gos page file taskId toMsg =
    Api.postWithTrackerJson ("task-track-" ++ String.fromInt taskId)
        { url = "/api/add-gos/" ++ capsule.id ++ "/" ++ String.fromInt gos ++ "/" ++ String.fromInt (page - 1)
        , body = Http.fileBody file
        , decoder = Data.decodeCapsule
        , toMsg = toMsg
        }


{-| Replaces a slide.
-}
replaceSlide : Data.Capsule -> Data.Slide -> Int -> File -> Config.TaskId -> (WebData Data.Capsule -> msg) -> Cmd msg
replaceSlide capsule slide page file taskId toMsg =
    Api.postWithTrackerJson ("task-track-" ++ String.fromInt taskId)
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


{-| Triggers the publication of a capsule.
-}
publishCapsule : Data.Capsule -> (WebData () -> msg) -> Cmd msg
publishCapsule capsule toMsg =
    Api.post
        { url = "/api/publish/" ++ capsule.id
        , body = Http.emptyBody
        , toMsg = toMsg
        }


{-| Triggers the removal of a publication of a capsule.
-}
unpublishCapsule : Data.Capsule -> (WebData () -> msg) -> Cmd msg
unpublishCapsule capsule toMsg =
    Api.post
        { url = "/api/unpublish/" ++ capsule.id
        , body = Http.emptyBody
        , toMsg = toMsg
        }


{-| Uploads a sound track to the server.
-}
uploadTrack :
    { capsule : Data.Capsule
    , fileValue : FileValue.File
    , file : File.File
    , toMsg : WebData Data.Capsule -> msg
    , taskId : Config.TaskId
    }
    -> Cmd msg
uploadTrack { capsule, fileValue, file, toMsg, taskId } =
    Api.postWithTrackerJson
        ("task-track-" ++ String.fromInt taskId)
        { url = "/api/sound-track/" ++ capsule.id ++ "/" ++ fileValue.name
        , body = Http.fileBody file
        , decoder = Data.decodeCapsule
        , toMsg = toMsg
        }


{-| Delete record from the server.
-}
deleteRecord : Data.Capsule -> Int -> (WebData () -> msg) -> Cmd msg
deleteRecord capsule gosId toMsg =
    Api.delete
        { url = "/api/delete-record/" ++ capsule.id ++ "/" ++ String.fromInt gosId
        , body = Http.emptyBody
        , toMsg = toMsg
        }


{-| Duplicates a capsule.
-}
duplicateCapsule : Data.Capsule -> (WebData Data.Capsule -> msg) -> Cmd msg
duplicateCapsule capsule toMsg =
    Api.postJson
        { url = "/api/duplicate/" ++ capsule.id
        , decoder = Data.decodeCapsule
        , body = Http.emptyBody
        , toMsg = toMsg
        }
