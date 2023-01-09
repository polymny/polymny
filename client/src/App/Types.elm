module App.Types exposing
    ( Model, Page(..), getCapsule, Msg(..), onUrlRequest
    , Error(..), errorToString
    )

{-| This module contains the model and messages of our application.


# The model

@docs Model, Page, getCapsule, Msg, onUrlRequest


# Error management

@docs Error, errorToString

-}

import Acquisition.Types as Acquisition
import Browser
import Config exposing (Config)
import Data.Capsule as Data exposing (Capsule)
import Data.User as Data exposing (User)
import Home.Types as Home
import Json.Decode as Decode
import NewCapsule.Types as NewCapsule
import Preparation.Types as Preparation
import Url


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
    = Home
    | NewCapsule NewCapsule.Model
    | Preparation Preparation.Model
    | Acquisition Acquisition.Model


{-| Tries to get the capsule from a specific page. Returns nothing if the page does not correspond to a specific
capsule.
-}
getCapsule : Page -> Maybe Capsule
getCapsule page =
    case page of
        Preparation m ->
            Just m.capsule

        Acquisition m ->
            Just m.capsule

        _ ->
            Nothing


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
    | ConfigMsg Config.Msg
    | OnUrlChange Url.Url
    | InternalUrl Url.Url
    | ExternalUrl String


{-| Converts an URL request msg to an App.Msg.
-}
onUrlRequest : Browser.UrlRequest -> Msg
onUrlRequest url =
    case url of
        Browser.Internal u ->
            InternalUrl u

        Browser.External u ->
            ExternalUrl u
