module Home.Updates exposing (update)

{-| This module contains the update function of the home page.
-}

import App.Types as App
import Data.User as Data
import Home.Types as Home


{-| The update function of the home view.
-}
update : Home.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    case msg of
        Home.Toggle p ->
            ( { model | user = Data.toggleProject p model.user }, Cmd.none )
