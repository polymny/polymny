module Api.Capsule exposing (..)

{-| This module contains all the functions to deal with the API of capsules.
-}

import Api.Utils as Api
import App.Types as App
import Data.Capsule as Data
import File
import FileValue
import Http
import NewCapsule.Types as NewCapsule


{-| Uploads a slideshow to the server, creating a new capsule.
-}
uploadSlideShow : String -> FileValue.File -> File.File -> Cmd App.Msg
uploadSlideShow project fileValue file =
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
        , resultToMsg = \x -> App.NewCapsuleMsg (NewCapsule.SlideUpload x)
        }
