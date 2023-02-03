module Settings.Types exposing (..)

{-| This module contains everything required for the settings view.
-}

import RemoteData exposing (WebData)


{-| The different tabs on which the settings page can be.
-}
type Model
    = Info InfoModel


{-| Initializes a model.
-}
init : Model
init =
    Info { newEmail = "", data = RemoteData.NotAsked }


{-| The data required for the info tab.
-}
type alias InfoModel =
    { newEmail : String
    , data : WebData ()
    }


{-| This type contains the different messages that can happen on the settings page.
-}
type Msg
    = InfoNewEmailChanged String
    | InfoNewEmailConfirm
    | InfoNewEmailDataChanged (WebData ())
