module App.Types exposing
    ( Model, Page(..), Msg(..), onUrlRequest
    , Error(..), errorToString
    , MaybeModel(..), MaybeMsg(..), WebSocketMsg(..), toMaybe
    )

{-| This module contains the model and messages of our application.


# The model

@docs Model, Page, getCapsule, Msg, onUrlRequest


# Error management

@docs Error, errorToString, unwrapRemoteData, unwrapResult

-}

import Acquisition.Types as Acquisition
import Browser
import Collaboration.Types as Collaboration
import Config exposing (Config)
import Data.Capsule as Data
import Data.User as Data exposing (User)
import Home.Types as Home
import Json.Decode as Decode
import NewCapsule.Types as NewCapsule
import Options.Types as Options
import Preparation.Types as Preparation
import Production.Types as Production
import Profile.Types as Profile
import Publication.Types as Publication
import Unlogged.Types as Unlogged
import Url


{-| This type helps us deal with errors at the startup of the application.
-}
type MaybeModel
    = Error Error
    | Unlogged Unlogged.Model
    | Logged Model


{-| Extracts the logged model from a maybe model.
-}
toMaybe : MaybeModel -> Maybe Model
toMaybe model =
    case model of
        Logged m ->
            Just m

        _ ->
            Nothing


{-| Type of messages that occur on maybe models.
-}
type MaybeMsg
    = LoggedMsg Msg
    | UnloggedMsg Unlogged.Msg


{-| This type contains all the model of the application.
-}
type alias Model =
    { config : Config
    , page : Page
    , user : User
    }


{-| This type represents the different pages on which a user can be on the application.
-}
type Page
    = Home Home.Model
    | NewCapsule NewCapsule.Model
    | Preparation (Preparation.Model String)
    | Acquisition (Acquisition.Model String Int)
    | Production (Production.Model String Int)
    | Publication (Publication.Model String)
    | Options (Options.Model String)
    | Collaboration (Collaboration.Model String)
    | Profile Profile.Model


{-| This type represents the errors that can occur when the page starts.
-}
type Error
    = DecodeError Decode.Error


{-| Convers the error to a string.
-}
errorToString : Error -> String
errorToString error =
    case error of
        DecodeError e ->
            "Error decoding JSON: " ++ Decode.errorToString e


{-| This type represents the different messages that can be sent in the application.
-}
type Msg
    = Noop
    | HomeMsg Home.Msg
    | NewCapsuleMsg NewCapsule.Msg
    | PreparationMsg Preparation.Msg
    | AcquisitionMsg Acquisition.Msg
    | ProductionMsg Production.Msg
    | PublicationMsg Publication.Msg
    | OptionsMsg Options.Msg
    | CollaborationMsg Collaboration.Msg
    | ProfileMsg Profile.Msg
    | ConfigMsg Config.Msg
    | WebSocketMsg WebSocketMsg
    | OnUrlChange Url.Url
    | InternalUrl Url.Url
    | ExternalUrl String
    | CopyString String
    | Logout
    | LoggedOut


{-| This type contains the different types of web socket messages that can be received from server.

For progresses messages, the String indicates the id of the capsule, the float is the progress (between 0 and 1), and
the bool indicates whether the task is finished.

-}
type WebSocketMsg
    = CapsuleUpdated Data.Capsule
    | ProductionProgress String Float Bool
    | PublicationProgress String Float Bool
    | ExtraRecordProgress String String Float Bool


{-| Converts an URL request msg to an App.Msg.
-}
onUrlRequest : Browser.UrlRequest -> Msg
onUrlRequest url =
    case url of
        Browser.Internal u ->
            InternalUrl u

        Browser.External u ->
            ExternalUrl u
