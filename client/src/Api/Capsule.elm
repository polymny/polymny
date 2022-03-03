module Api.Capsule exposing (..)

{-| This module contains all the functions to deal with the API of capsules.
-}

import Api.Utils as Api
import App.Types as App
import File
import FileValue exposing (File)
import Http
import Json.Decode as Decode
import NewCapsule.Types as NewCapsule
import RemoteData


{-| Uploads a slideshow to the server, creating a new capsule.
-}
uploadSlideShow : String -> File -> Cmd App.Msg
uploadSlideShow project file =
    let
        name =
            file.name
                |> String.split "."
                |> List.reverse
                |> List.drop 1
                |> List.reverse
                |> String.join "."

        realFile =
            Decode.decodeValue File.decoder file.value

        resultToMsg result =
            RemoteData.fromResult result
                |> RemoteData.mapError NewCapsule.HttpError
                |> NewCapsule.SlideUpload
                |> App.NewCapsuleMsg
    in
    case realFile of
        Ok f ->
            Api.post
                { url = "/api/new-capsule/" ++ project ++ "/" ++ name ++ "/"
                , expect = Http.expectWhatever resultToMsg
                , body = Http.fileBody f
                }

        _ ->
            Cmd.none
