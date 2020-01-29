module Status exposing (..)

import Http


type Status t e
    = NotSent
    | Sent
    | Success t
    | Error e
