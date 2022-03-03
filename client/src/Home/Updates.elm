port module Home.Updates exposing
    ( update
    , subs
    )

{-| This module contains the update function of the home page.

@docs update


# Subscriptions

@docs selected

-}

import App.Types as App
import Data.User as Data
import Home.Types as Home
import Json.Decode as Decode
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

        Home.SlideUploadReceived project file ->
            case file.mime of
                "application/pdf" ->
                    let
                        name =
                            file.name
                                |> String.split "."
                                |> List.reverse
                                |> List.drop 1
                                |> List.reverse
                                |> String.join "."
                                |> Debug.log "name"
                    in
                    ( model, Cmd.none )

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
    selected (\_ -> App.Noop)
