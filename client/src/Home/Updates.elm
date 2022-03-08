port module Home.Updates exposing
    ( update
    , selected, subs
    )

{-| This module contains the update function of the home page.

@docs update


# Subscriptions

@docs selected, subs

-}

import Api.Capsule as Api
import App.Types as App
import Data.User as Data
import File
import FileValue
import Home.Types as Home
import Json.Decode as Decode
import NewCapsule.Types as NewCapsule
import RemoteData
import Strings
import Utils


{-| The update function of the home view.
-}
update : Home.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case msg of
        Home.Toggle p ->
            ( { model | user = Data.toggleProject p model.user }, Cmd.none )

        Home.SlideUploadClicked ->
            ( model
            , Utils.tern (Data.isPremium model.user) [ "application/pdf", "application/zip" ] [ "application/pdf" ]
                |> select Nothing
            )

        Home.SlideUploadReceived project fileValue file ->
            case fileValue.mime of
                "application/pdf" ->
                    let
                        projectName =
                            project |> Maybe.withDefault (Strings.stepsPreparationNewProject model.config.clientState.lang)

                        name =
                            fileValue.name
                                |> String.split "."
                                |> List.reverse
                                |> List.drop 1
                                |> List.reverse
                                |> String.join "."

                        newPage =
                            RemoteData.Loading Nothing
                                |> NewCapsule.init model.config.clientState.lang project name
                                |> App.NewCapsule
                    in
                    ( { model | page = newPage }
                    , Api.uploadSlideShow
                        { project = projectName
                        , fileValue = fileValue
                        , file = file
                        , toMsg = \x -> App.NewCapsuleMsg (NewCapsule.SlideUpload x)
                        }
                    )

                -- TODO : manage "application/zip"
                _ ->
                    ( model, Cmd.none )


{-| Port to ask to select a file.
-}
select : Maybe Data.Project -> List String -> Cmd msg
select project mimeTypesAllowed =
    selectPort ( Maybe.map .name project, mimeTypesAllowed )


{-| Port to ask to select a file.
-}
port selectPort : ( Maybe String, List String ) -> Cmd msg


{-| Subscription to receive the selected file.
-}
port selected : (( Maybe String, Decode.Value ) -> msg) -> Sub msg


{-| Subscriptions of the page.
-}
subs : App.Model -> Sub App.Msg
subs model =
    selected
        (\( p, x ) ->
            case ( Decode.decodeValue FileValue.decoder x, Decode.decodeValue File.decoder x ) of
                ( Ok y, Ok z ) ->
                    App.HomeMsg (Home.SlideUploadReceived p y z)

                _ ->
                    App.Noop
        )
