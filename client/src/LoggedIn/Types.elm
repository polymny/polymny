module LoggedIn.Types exposing (Model, Msg(..), Tab(..))

import Acquisition.Types as Acquisition
import Api
import Preparation.Types as Preparation


type alias Model =
    { session : Api.Session
    , tab : Tab
    }


type Tab
    = Home
    | Preparation Preparation.Model
    | Acquisition Acquisition.Model
    | Edition
    | Publication


type Msg
    = PreparationMsg Preparation.Msg
    | AcquisitionMsg Acquisition.Msg
    | EditionMsg
    | PublicationMsg
