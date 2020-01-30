module Status exposing (Status(..))


type Status t e
    = NotSent
    | Sent
    | Success t
    | Error e
