module LoggedIn.Types exposing (Model, Msg(..), Tab(..))

import Api
import Preparation.Types as Preparation


type alias Model =
    { session : Api.Session
    , tab : Tab
    }


type Tab
    = Home
    | Preparation Preparation.Model
    | Acquisition
    | Edition
    | Publication


type Msg
    = PreparationMsg Preparation.Msg
    | AcquisitionMsg
    | EditionMsg
    | PublicationMsg
