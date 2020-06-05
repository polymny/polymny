module Api exposing
    ( Asset
    , Capsule
    , CapsuleDetails
    , Gos
    , Project
    , Session
    , Slide
    , capsuleFromId
    , capsuleUploadBackground
    , capsuleUploadLogo
    , capsuleUploadSlideShow
    , capsulesFromProjectId
    , createProject
    , decodeCapsule
    , decodeCapsuleDetails
    , decodeCapsules
    , decodeProject
    , decodeSession
    , detailsSortSlides
    , encodeSlideStructure
    , logOut
    , login
    , newCapsule
    , newProject
    , setupConfig
    , signUp
    , testDatabase
    , testMailer
    , updateSlide
    , updateSlideStructure
    )

import Dict exposing (Dict)
import File
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode



-- Api types


type alias Project =
    { id : Int
    , name : String
    , lastVisited : Int
    , capsules : List Capsule
    }


createProject : Int -> String -> Int -> Project
createProject id name lastVisited =
    Project id name lastVisited []


type alias Capsule =
    { id : Int
    , name : String
    , title : String
    , description : String
    }


decodeCapsule : Decoder Capsule
decodeCapsule =
    Decode.map4 Capsule
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.string)


decodeCapsules : Decoder (List Capsule)
decodeCapsules =
    Decode.list decodeCapsule


withCapsules : List Capsule -> Int -> String -> Int -> Project
withCapsules capsules id name lastVisited =
    Project id name lastVisited capsules


decodeProject : List Capsule -> Decoder Project
decodeProject capsules =
    Decode.map3 (withCapsules capsules)
        (Decode.field "id" Decode.int)
        (Decode.field "project_name" Decode.string)
        (Decode.field "last_visited" Decode.int)


type alias Session =
    { username : String
    , projects : List Project
    , active_project : Maybe Project
    }


decodeSession : Decoder Session
decodeSession =
    Decode.map3 Session
        (Decode.field "username" Decode.string)
        (Decode.field "projects" (Decode.list (decodeProject [])))
        (Decode.field "active_project" (Decode.maybe (decodeProject [])))


type alias Asset =
    { id : Int
    , asset_path : String
    , asset_type : String
    , name : String
    , upload_date : Int
    , uuid : String
    }


decodeAsset : Decoder Asset
decodeAsset =
    Decode.map6 Asset
        (Decode.field "id" Decode.int)
        (Decode.field "asset_path" Decode.string)
        (Decode.field "asset_type" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "upload_date" Decode.int)
        (Decode.field "uuid" Decode.string)


type alias Slide =
    { id : Int
    , asset : Asset
    , capsule_id : Int
    , prompt : String
    }


decodeSlide : Decoder Slide
decodeSlide =
    Decode.map4 Slide
        (Decode.field "id" Decode.int)
        (Decode.field "asset" decodeAsset)
        (Decode.field "capsule_id" Decode.int)
        (Decode.field "prompt" Decode.string)


type alias InnerGos =
    { slides : List Int
    , transitions : List Float
    , record : Maybe String
    , locked : Bool
    }


decodeInnerGos : Decoder InnerGos
decodeInnerGos =
    Decode.map4 InnerGos
        (Decode.field "slides" (Decode.list Decode.int))
        (Decode.field "transitions" (Decode.list Decode.float))
        (Decode.field "record_path" (Decode.nullable Decode.string))
        (Decode.field "locked" Decode.bool)


type alias Gos =
    { slides : List Slide
    , transitions : List Float
    , record : Maybe String
    , locked : Bool
    }


type alias InnerCapsuleDetails =
    { capsule : Capsule
    , slides : List Slide
    , projects : List Project
    , slide_show : Maybe Asset
    , background : Maybe Asset
    , logo : Maybe Asset
    , structure : List InnerGos
    }


type alias CapsuleDetails =
    { capsule : Capsule
    , slides : List Slide
    , projects : List Project
    , slide_show : Maybe Asset
    , background : Maybe Asset
    , logo : Maybe Asset
    , structure : List Gos
    }


toGosAux : Dict Int Slide -> List Int -> List (Maybe Slide) -> List (Maybe Slide)
toGosAux slides ids current =
    let
        output =
            case ids of
                [] ->
                    current

                h :: t ->
                    toGosAux slides t (Dict.get h slides :: current)
    in
    output


toGos : Dict Int Slide -> InnerGos -> Gos
toGos slides gos =
    { slides = List.filterMap (\x -> x) (toGosAux slides (List.reverse gos.slides) [])
    , transitions = gos.transitions
    , record = gos.record
    , locked = gos.locked
    }


slidesAsDict : List Slide -> Dict Int Slide
slidesAsDict slides =
    Dict.fromList (List.map (\x -> ( x.id, x )) slides)


toCapsuleDetails : InnerCapsuleDetails -> CapsuleDetails
toCapsuleDetails innerDetails =
    { capsule = innerDetails.capsule
    , slides = innerDetails.slides
    , projects = innerDetails.projects
    , slide_show = innerDetails.slide_show
    , background = innerDetails.background
    , logo = innerDetails.logo
    , structure = List.map (toGos (slidesAsDict innerDetails.slides)) innerDetails.structure
    }


decodeCapsuleDetails : Decoder CapsuleDetails
decodeCapsuleDetails =
    let
        innerDecoder =
            Decode.map7 InnerCapsuleDetails
                (Decode.field "capsule" decodeCapsule)
                (Decode.field "slides" (Decode.list decodeSlide))
                (Decode.field "projects" (Decode.list (decodeProject [])))
                (Decode.field "slide_show" (Decode.maybe decodeAsset))
                (Decode.field "background" (Decode.maybe decodeAsset))
                (Decode.field "logo" (Decode.maybe decodeAsset))
                (Decode.field "structure" (Decode.list decodeInnerGos))
    in
    Decode.map toCapsuleDetails innerDecoder


detailsSortSlides : CapsuleDetails -> List (List Slide)
detailsSortSlides details =
    List.map .slides details.structure



-- Sign up form


type alias SignUpContent a =
    { a
        | username : String
        , password : String
        , email : String
    }


encodeSignUpContent : SignUpContent a -> Encode.Value
encodeSignUpContent { username, password, email } =
    Encode.object
        [ ( "username", Encode.string username )
        , ( "password", Encode.string password )
        , ( "email", Encode.string email )
        ]


signUp : (Result Http.Error () -> msg) -> SignUpContent a -> Cmd msg
signUp responseToMsg content =
    Http.post
        { url = "/api/new-user/"
        , expect = Http.expectWhatever responseToMsg
        , body = Http.jsonBody (encodeSignUpContent content)
        }



-- Log in form


type alias LoginContent a =
    { a
        | username : String
        , password : String
    }


encodeLoginContent : LoginContent a -> Encode.Value
encodeLoginContent { username, password } =
    Encode.object
        [ ( "username", Encode.string username )
        , ( "password", Encode.string password )
        ]


login : (Result Http.Error Session -> msg) -> LoginContent b -> Cmd msg
login resultToMsg content =
    Http.post
        { url = "/api/login"
        , expect = Http.expectJson resultToMsg decodeSession
        , body = Http.jsonBody (encodeLoginContent content)
        }


logOut : (Result Http.Error () -> msg) -> Cmd msg
logOut resultToMsg =
    Http.post
        { url = "/api/logout"
        , expect = Http.expectWhatever resultToMsg
        , body = Http.emptyBody
        }



-- New project form


type alias NewProjectContent a =
    { a
        | name : String
    }


encodeNewProjectContent : NewProjectContent a -> Encode.Value
encodeNewProjectContent { name } =
    Encode.object
        [ ( "project_name", Encode.string name )
        ]


newProject : (Result Http.Error Project -> msg) -> NewProjectContent a -> Cmd msg
newProject resultToMsg content =
    Http.post
        { url = "/api/new-project"
        , expect = Http.expectJson resultToMsg (decodeProject [])
        , body = Http.jsonBody (encodeNewProjectContent content)
        }



-- Project page


capsulesFromProjectId : (Result Http.Error (List Capsule) -> msg) -> Int -> Cmd msg
capsulesFromProjectId resultToMsg id =
    Http.get
        { url = "/api/project/" ++ String.fromInt id ++ "/capsules"
        , expect = Http.expectJson resultToMsg decodeCapsules
        }



-- New capsule  form


type alias NewCapsuleContent a =
    { a
        | name : String
        , title : String
        , description : String
    }


encodeNewCapsuleContent : Int -> NewCapsuleContent a -> Encode.Value
encodeNewCapsuleContent projectId { name, title, description } =
    Encode.object
        [ ( "name", Encode.string name )
        , ( "title", Encode.string title )
        , ( "description", Encode.string description )
        , ( "project_id", Encode.int projectId )
        ]


newCapsule : (Result Http.Error Capsule -> msg) -> Int -> NewCapsuleContent a -> Cmd msg
newCapsule resultToMsg projectId content =
    Http.post
        { url = "/api/new-capsule"
        , expect = Http.expectJson resultToMsg decodeCapsule
        , body = Http.jsonBody (encodeNewCapsuleContent projectId content)
        }



-- Capsule Details


capsuleFromId : (Result Http.Error CapsuleDetails -> msg) -> Int -> Cmd msg
capsuleFromId resultToMsg id =
    Http.get
        { url = "/api/capsule/" ++ String.fromInt id
        , expect = Http.expectJson resultToMsg decodeCapsuleDetails
        }


capsuleUploadSlideShow : (Result Http.Error CapsuleDetails -> msg) -> Int -> File.File -> Cmd msg
capsuleUploadSlideShow resultToMsg id content =
    Http.post
        { url = "/api/capsule/" ++ String.fromInt id ++ "/upload_slides"
        , expect = Http.expectJson resultToMsg decodeCapsuleDetails
        , body = Http.multipartBody [ Http.filePart "file" content ]
        }


capsuleUploadBackground : (Result Http.Error CapsuleDetails -> msg) -> Int -> File.File -> Cmd msg
capsuleUploadBackground resultToMsg id content =
    Http.post
        { url = "/api/capsule/" ++ String.fromInt id ++ "/upload_background"
        , expect = Http.expectJson resultToMsg decodeCapsuleDetails
        , body = Http.multipartBody [ Http.filePart "file" content ]
        }


capsuleUploadLogo : (Result Http.Error CapsuleDetails -> msg) -> Int -> File.File -> Cmd msg
capsuleUploadLogo resultToMsg id content =
    Http.post
        { url = "/api/capsule/" ++ String.fromInt id ++ "/upload_logo"
        , expect = Http.expectJson resultToMsg decodeCapsuleDetails
        , body = Http.multipartBody [ Http.filePart "file" content ]
        }


type alias EditSlideContent a =
    { a
        | prompt : String
    }


encodeSlideContent : EditSlideContent a -> Encode.Value
encodeSlideContent { prompt } =
    Encode.object
        [ ( "prompt", Encode.string prompt )
        ]


updateSlide : (Result Http.Error Slide -> msg) -> Int -> EditSlideContent a -> Cmd msg
updateSlide resultToMsg id content =
    Http.request
        { method = "PUT"
        , headers = []
        , url = "/api/slide/" ++ String.fromInt id
        , expect = Http.expectJson resultToMsg decodeSlide
        , body = Http.jsonBody (encodeSlideContent content)
        , timeout = Nothing
        , tracker = Nothing
        }


encodeSlideStructure : CapsuleDetails -> Encode.Value
encodeSlideStructure capsule =
    let
        encodeGos : Gos -> Encode.Value
        encodeGos gos =
            Encode.object
                [ ( "record_path", Maybe.withDefault Encode.null (Maybe.map Encode.string gos.record) )
                , ( "transitions", Encode.list Encode.float gos.transitions )
                , ( "slides", Encode.list Encode.int (List.map .id gos.slides) )
                , ( "locked", Encode.bool gos.locked )
                ]
    in
    Encode.list encodeGos capsule.structure


updateSlideStructure : (Result Http.Error CapsuleDetails -> msg) -> CapsuleDetails -> Cmd msg
updateSlideStructure resultToMsg content =
    Http.request
        { method = "POST"
        , headers = []
        , url = "/api/capsule/" ++ String.fromInt content.capsule.id ++ "/gos_order"
        , expect = Http.expectJson resultToMsg decodeCapsuleDetails
        , body = Http.jsonBody (encodeSlideStructure content)
        , timeout = Nothing
        , tracker = Nothing
        }



-- Setup forms


type alias DatabaseTestContent a =
    { a
        | hostname : String
        , username : String
        , password : String
        , name : String
    }


encodeDatabaseTestContent : DatabaseTestContent a -> Encode.Value
encodeDatabaseTestContent { hostname, username, password, name } =
    Encode.object
        [ ( "hostname", Encode.string hostname )
        , ( "username", Encode.string username )
        , ( "password", Encode.string password )
        , ( "name", Encode.string name )
        ]


testDatabase : (Result Http.Error () -> msg) -> DatabaseTestContent a -> Cmd msg
testDatabase resultToMsg content =
    Http.post
        { url = "/api/test-database"
        , expect = Http.expectWhatever resultToMsg
        , body = Http.jsonBody (encodeDatabaseTestContent content)
        }


type alias MailerTestContent a =
    { a
        | hostname : String
        , username : String
        , password : String
        , recipient : String
        , enabled : Bool
        , requireMailConfirmation : Bool
    }


encodeMailerTestContent : MailerTestContent a -> Encode.Value
encodeMailerTestContent { hostname, username, password, recipient } =
    Encode.object
        [ ( "hostname", Encode.string hostname )
        , ( "username", Encode.string username )
        , ( "password", Encode.string password )
        , ( "recipient", Encode.string recipient )
        ]


encodeConfig : DatabaseTestContent a -> MailerTestContent b -> Encode.Value
encodeConfig database mailer =
    Encode.object
        [ ( "database_hostname", Encode.string database.hostname )
        , ( "database_username", Encode.string database.username )
        , ( "database_password", Encode.string database.password )
        , ( "database_name", Encode.string database.name )
        , ( "mailer_enabled", Encode.bool mailer.enabled )
        , ( "mailer_require_email_confirmation", Encode.bool mailer.requireMailConfirmation )
        , ( "mailer_hostname", Encode.string mailer.hostname )
        , ( "mailer_username", Encode.string mailer.username )
        , ( "mailer_password", Encode.string mailer.password )
        ]


testMailer : (Result Http.Error () -> msg) -> MailerTestContent a -> Cmd msg
testMailer resultToMsg content =
    Http.post
        { url = "/api/test-mailer"
        , expect = Http.expectWhatever resultToMsg
        , body = Http.jsonBody (encodeMailerTestContent content)
        }


setupConfig : (Result Http.Error () -> msg) -> DatabaseTestContent a -> MailerTestContent b -> Cmd msg
setupConfig resultToMsg database mailer =
    Http.post
        { url = "/api/setup-config"
        , expect = Http.expectWhatever resultToMsg
        , body = Http.jsonBody (encodeConfig database mailer)
        }
