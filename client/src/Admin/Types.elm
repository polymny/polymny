module Admin.Types exposing (..)

import Capsule exposing (Capsule)
import Json.Decode as Decode exposing (Decoder)
import Status exposing (Status)
import User as UserMod


type alias User =
    { id : Int
    , activated : Bool
    , newsletterSubscribed : Bool
    , inner : UserMod.User
    }


fromRealUser : Int -> Bool -> Bool -> UserMod.User -> User
fromRealUser id activated newsletterSubscribed inner =
    { id = id
    , activated = activated
    , newsletterSubscribed = newsletterSubscribed
    , inner = inner
    }


decodeUser : Decoder User
decodeUser =
    Decode.map4 fromRealUser
        (Decode.field "id" Decode.int)
        (Decode.field "activated" Decode.bool)
        (Decode.field "newsletter_subscribed" Decode.bool)
        (UserMod.decode ( UserMod.LastModified, False ))


type alias DashboardData =
    { users : List User
    , capsules : List Capsule
    }


decodeDashboard : Decoder DashboardData
decodeDashboard =
    Decode.map2 DashboardData
        (Decode.field "users" (Decode.list decodeUser))
        (Decode.field "capsules" (Decode.list Capsule.decode))


type Page
    = Dashboard
    | UsersPage Int
    | UserPage User
    | CapsulesPage Int


type alias Model =
    { page : Page
    , users : List User
    , capsules : List Capsule
    , stats : String
    , usernameSearch : Maybe String
    , emailSearch : Maybe String
    , usernameSearchStatus : Status
    , capsuleSearch : Maybe String
    , projectSearch : Maybe String
    , capsuleSearchStatus : Status
    , inviteUsername : String
    , inviteEmail : String
    , inviteUserStatus : Status
    }


initModel : Page -> Model
initModel page =
    { page = page
    , users = []
    , capsules = []
    , stats = "dummy stats"
    , usernameSearch = Nothing
    , emailSearch = Nothing
    , usernameSearchStatus = Status.NotSent
    , capsuleSearch = Nothing
    , projectSearch = Nothing
    , capsuleSearchStatus = Status.NotSent
    , inviteUsername = ""
    , inviteEmail = ""
    , inviteUserStatus = Status.NotSent
    }


type Msg
    = ToggleFold String
    | UsernameSearchChanged String
    | EmailSearchChanged String
    | UserSearchSubmitted
    | UserSearchSuccess (List User)
    | UserSearchFailed
    | CapsuleSearchChanged String
    | ProjectSearchChanged String
    | CapsuleSearchSubmitted
    | CapsuleSearchSuccess (List Capsule)
    | CapsuleSearchFailed
    | InviteUsernameChanged String
    | InviteEmailChanged String
    | InviteUserConfirm
    | InviteUserSuccess
    | InviteUserFailed
    | RequestDeleteUser User
    | DeleteUser User
    | ClearWebockets
