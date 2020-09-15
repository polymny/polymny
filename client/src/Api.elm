module Api exposing
    ( Asset
    , Capsule
    , CapsuleDetails
    , Gos
    , Project
    , PublishedType(..)
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
    , decodeProjectWithCapsules
    , decodeSession
    , detailsSortSlides
    , editionAuto
    , encodeSlideStructure
    , forgotPassword
    , get
    , logOut
    , login
    , newCapsule
    , newProject
    , post
    , publishVideo
    , quickUploadSlideShow
    , resetPassword
    , setupConfig
    , signUp
    , slideDeleteExtraResource
    , slideReplace
    , slideUploadExtraResource
    , testDatabase
    , testMailer
    , updateOptions
    , updateSlide
    , updateSlideStructure
    , validateCapsule
    )

import Dict exposing (Dict)
import File
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Webcam



-- Helper for request


get : { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
get { url, body, expect } =
    Http.request
        { method = "GET"
        , headers = [ Http.header "Accept" "application/json" ]
        , url = url
        , body = body
        , expect = expect
        , timeout = Nothing
        , tracker = Nothing
        }


post : { url : String, body : Http.Body, expect : Http.Expect msg } -> Cmd msg
post { url, body, expect } =
    Http.request
        { method = "POST"
        , headers = [ Http.header "Accept" "application/json" ]
        , url = url
        , body = body
        , expect = expect
        , timeout = Nothing
        , tracker = Nothing
        }



-- Api types


type alias Project =
    { id : Int
    , name : String
    , lastVisited : Int
    , folded : Bool
    , capsules : List Capsule
    }


createProject : Int -> String -> Int -> Project
createProject id name lastVisited =
    Project id name lastVisited True []


type PublishedType
    = NotPublished
    | Publishing
    | Published


decodePublishedAux : String -> PublishedType
decodePublishedAux s =
    case s of
        "Publishing" ->
            Publishing

        "Published" ->
            Published

        _ ->
            NotPublished


decodePublished : Decoder PublishedType
decodePublished =
    Decode.map decodePublishedAux Decode.string


type alias CapsuleEditionOptions =
    { withVideo : Bool
    , webcamSize : Maybe Webcam.WebcamSize
    , webcamPosition : Maybe Webcam.WebcamPosition
    }


decodeWebcamSize : Decoder Webcam.WebcamSize
decodeWebcamSize =
    Decode.map
        (\x ->
            case x of
                "Small" ->
                    Webcam.Small

                "Medium" ->
                    Webcam.Medium

                "Large" ->
                    Webcam.Large

                _ ->
                    Webcam.Medium
        )
        Decode.string


decodeWebcamPosition : Decoder Webcam.WebcamPosition
decodeWebcamPosition =
    Decode.map
        (\x ->
            case x of
                "TopLeft" ->
                    Webcam.TopLeft

                "TopRight" ->
                    Webcam.TopRight

                "BottomLeft" ->
                    Webcam.BottomLeft

                "BottomRight" ->
                    Webcam.BottomRight

                _ ->
                    Webcam.BottomLeft
        )
        Decode.string


decodeCapsuleEditionOptions : Decoder CapsuleEditionOptions
decodeCapsuleEditionOptions =
    Decode.map3 CapsuleEditionOptions
        (Decode.field "with_video" Decode.bool)
        (Decode.field "webcam_size" (Decode.maybe decodeWebcamSize))
        (Decode.field "webcam_position" (Decode.maybe decodeWebcamPosition))


type alias Capsule =
    { id : Int
    , name : String
    , title : String
    , description : String
    , published : PublishedType
    , capsuleEditionOptions : Maybe CapsuleEditionOptions
    }


decodeCapsule : Decoder Capsule
decodeCapsule =
    Decode.map6 Capsule
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "published" decodePublished)
        (Decode.field "edition_options" (Decode.maybe decodeCapsuleEditionOptions))


decodeCapsules : Decoder (List Capsule)
decodeCapsules =
    Decode.list decodeCapsule


withCapsules : List Capsule -> Int -> String -> Int -> Project
withCapsules capsules id name lastVisited =
    Project id name lastVisited True capsules


decodeProject : List Capsule -> Decoder Project
decodeProject capsules =
    Decode.map3 (withCapsules capsules)
        (Decode.field "id" Decode.int)
        (Decode.field "project_name" Decode.string)
        (Decode.field "last_visited" Decode.int)


decodeProjectWithCapsules : Decoder Project
decodeProjectWithCapsules =
    Decode.map4 (\x y z t -> Project x y z True t)
        (Decode.field "id" Decode.int)
        (Decode.field "project_name" Decode.string)
        (Decode.field "last_visited" Decode.int)
        (Decode.field "capsules" decodeCapsules)


type alias Session =
    { username : String
    , projects : List Project
    , active_project : Maybe Project
    , withVideo : Maybe Bool
    , webcamSize : Maybe Webcam.WebcamSize
    , webcamPosition : Maybe Webcam.WebcamPosition
    }


decodeSession : Decoder Session
decodeSession =
    Decode.map (\x -> x)
        (Decode.map6 Session
            (Decode.field "username" Decode.string)
            (Decode.field "projects" (Decode.map (\x -> List.filter (\y -> List.length y.capsules > 0) x) (Decode.list decodeProjectWithCapsules)))
            (Decode.field "active_project" (Decode.maybe decodeProjectWithCapsules))
            (Decode.field "with_video" (Decode.maybe Decode.bool))
            (Decode.field "webcam_size" (Decode.maybe decodeWebcamSize))
            (Decode.field "webcam_position" (Decode.maybe decodeWebcamPosition))
        )


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
        (Decode.field "asset_path" (Decode.map (\x -> "/data/" ++ x) Decode.string))
        (Decode.field "asset_type" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "upload_date" Decode.int)
        (Decode.field "uuid" Decode.string)


type alias Slide =
    { id : Int
    , asset : Asset
    , capsule_id : Int
    , prompt : String
    , extra : Maybe Asset
    }


decodeSlide : Decoder Slide
decodeSlide =
    Decode.map5 Slide
        (Decode.field "id" Decode.int)
        (Decode.field "asset" decodeAsset)
        (Decode.field "capsule_id" Decode.int)
        (Decode.field "prompt" Decode.string)
        (Decode.field "extra" (Decode.maybe decodeAsset))


type alias InnerGos =
    { slides : List Int
    , transitions : List Int
    , record : Maybe String
    , background : Maybe String
    , locked : Bool
    }


decodeInnerGos : Decoder InnerGos
decodeInnerGos =
    Decode.map5 InnerGos
        (Decode.field "slides" (Decode.list Decode.int))
        (Decode.field "transitions" (Decode.list Decode.int))
        (Decode.field "record_path" (Decode.nullable (Decode.map (\x -> "/data/" ++ x) Decode.string)))
        (Decode.maybe (Decode.field "background_path" (Decode.map (\x -> "/data/" ++ x) Decode.string)))
        (Decode.field "locked" Decode.bool)


type alias Gos =
    { slides : List Slide
    , transitions : List Int
    , record : Maybe String
    , background : Maybe String
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
    , video : Maybe Asset
    }


type alias CapsuleDetails =
    { capsule : Capsule
    , slides : List Slide
    , projects : List Project
    , slide_show : Maybe Asset
    , background : Maybe Asset
    , logo : Maybe Asset
    , structure : List Gos
    , video : Maybe Asset
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
    , background = gos.background
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
    , video = innerDetails.video
    }


decodeCapsuleDetails : Decoder CapsuleDetails
decodeCapsuleDetails =
    let
        innerDecoder =
            Decode.map8 InnerCapsuleDetails
                (Decode.field "capsule" decodeCapsule)
                (Decode.field "slides" (Decode.list decodeSlide))
                (Decode.field "projects" (Decode.list (decodeProject [])))
                (Decode.field "slide_show" (Decode.maybe decodeAsset))
                (Decode.field "background" (Decode.maybe decodeAsset))
                (Decode.field "logo" (Decode.maybe decodeAsset))
                (Decode.field "structure" (Decode.list decodeInnerGos))
                (Decode.field "video" (Decode.maybe decodeAsset))
    in
    Decode.map toCapsuleDetails innerDecoder


detailsSortSlides : CapsuleDetails -> List (List Slide)
detailsSortSlides details =
    List.map .slides details.structure


validateCapsule : (Result Http.Error CapsuleDetails -> msg) -> String -> String -> CapsuleDetails -> Cmd msg
validateCapsule responseToMsg projectName capsuleName content =
    post
        { url = "/api/capsule/" ++ String.fromInt content.capsule.id ++ "/validate"
        , expect = Http.expectJson responseToMsg decodeCapsuleDetails
        , body = Http.jsonBody (Encode.object [ ( "name", Encode.string capsuleName ) ])
        }



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
    post
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
    post
        { url = "/api/login"
        , expect = Http.expectJson resultToMsg decodeSession
        , body = Http.jsonBody (encodeLoginContent content)
        }


type alias ForgotPasswordContent a =
    { a | email : String }


encodeForgotPasswordContent : ForgotPasswordContent a -> Encode.Value
encodeForgotPasswordContent { email } =
    Encode.object [ ( "email", Encode.string email ) ]


forgotPassword : (Result Http.Error () -> msg) -> ForgotPasswordContent b -> Cmd msg
forgotPassword resultToMsg content =
    post
        { url = "/api/request-new-password"
        , expect = Http.expectWhatever resultToMsg
        , body = Http.jsonBody (encodeForgotPasswordContent content)
        }


type alias ResetPasswordContent a =
    { a
        | password : String
        , key : String
    }


encodeResetPasswordContent : ResetPasswordContent a -> Encode.Value
encodeResetPasswordContent { password, key } =
    Encode.object [ ( "key", Encode.string key ), ( "new_password", Encode.string password ) ]


resetPassword : (Result Http.Error Session -> msg) -> ResetPasswordContent b -> Cmd msg
resetPassword resultToMsg content =
    post
        { url = "/api/change-password"
        , expect = Http.expectJson resultToMsg decodeSession
        , body = Http.jsonBody (encodeResetPasswordContent content)
        }


logOut : (Result Http.Error () -> msg) -> Cmd msg
logOut resultToMsg =
    post
        { url = "/api/logout"
        , expect = Http.expectWhatever resultToMsg
        , body = Http.emptyBody
        }



-- New project form


quickUploadSlideShow : (Result Http.Error CapsuleDetails -> msg) -> File.File -> Cmd msg
quickUploadSlideShow resultToMsg content =
    post
        { url = "/api/quick_upload_slides"
        , expect = Http.expectJson resultToMsg decodeCapsuleDetails
        , body = Http.multipartBody [ Http.filePart "file" content ]
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
    post
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
    post
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
    post
        { url = "/api/capsule/" ++ String.fromInt id ++ "/upload_slides"
        , expect = Http.expectJson resultToMsg decodeCapsuleDetails
        , body = Http.multipartBody [ Http.filePart "file" content ]
        }


capsuleUploadBackground : (Result Http.Error CapsuleDetails -> msg) -> Int -> File.File -> Cmd msg
capsuleUploadBackground resultToMsg id content =
    post
        { url = "/api/capsule/" ++ String.fromInt id ++ "/upload_background"
        , expect = Http.expectJson resultToMsg decodeCapsuleDetails
        , body = Http.multipartBody [ Http.filePart "file" content ]
        }


capsuleUploadLogo : (Result Http.Error CapsuleDetails -> msg) -> Int -> File.File -> Cmd msg
capsuleUploadLogo resultToMsg id content =
    post
        { url = "/api/capsule/" ++ String.fromInt id ++ "/upload_logo"
        , expect = Http.expectJson resultToMsg decodeCapsuleDetails
        , body = Http.multipartBody [ Http.filePart "file" content ]
        }


encodeWebcamSize : Webcam.WebcamSize -> String
encodeWebcamSize webcamSize =
    case webcamSize of
        Webcam.Small ->
            "Small"

        Webcam.Medium ->
            "Medium"

        Webcam.Large ->
            "Large"


encodeWebcamPosition : Webcam.WebcamPosition -> String
encodeWebcamPosition webcamPosition =
    case webcamPosition of
        Webcam.TopLeft ->
            "TopLeft"

        Webcam.TopRight ->
            "TopRight"

        Webcam.BottomLeft ->
            "BottomLeft"

        Webcam.BottomRight ->
            "BottomRight"


type alias EditionAutoContent a =
    { a
        | withVideo : Bool
        , webcamSize : Webcam.WebcamSize
        , webcamPosition : Webcam.WebcamPosition
    }


encodeEditionAutoContent : EditionAutoContent a -> Encode.Value
encodeEditionAutoContent { withVideo, webcamSize, webcamPosition } =
    Encode.object
        [ ( "with_video", Encode.bool withVideo )
        , ( "webcam_size", Encode.string <| encodeWebcamSize webcamSize )
        , ( "webcam_position", Encode.string <| encodeWebcamPosition webcamPosition )
        ]


editionAuto : (Result Http.Error CapsuleDetails -> msg) -> Int -> EditionAutoContent a -> Cmd msg
editionAuto resultToMsg id content =
    post
        { url = "/api/capsule/" ++ String.fromInt id ++ "/edition"
        , expect = Http.expectJson resultToMsg decodeCapsuleDetails
        , body = Http.jsonBody (encodeEditionAutoContent content)
        }


slideUploadExtraResource : (Result Http.Error Slide -> msg) -> Int -> File.File -> Cmd msg
slideUploadExtraResource resultToMsg id content =
    post
        { url = "/api/slide/" ++ String.fromInt id ++ "/upload_resource"
        , expect = Http.expectJson resultToMsg decodeSlide
        , body = Http.multipartBody [ Http.filePart "file" content ]
        }


slideDeleteExtraResource : (Result Http.Error Slide -> msg) -> Int -> Cmd msg
slideDeleteExtraResource resultToMsg id =
    post
        { url = "/api/slide/" ++ String.fromInt id ++ "/delete_resource"
        , expect = Http.expectJson resultToMsg decodeSlide
        , body = Http.emptyBody
        }


slideReplace : (Result Http.Error Slide -> msg) -> Int -> File.File -> Cmd msg
slideReplace resultToMsg id content =
    post
        { url = "/api/slide/" ++ String.fromInt id ++ "/replace"
        , expect = Http.expectJson resultToMsg decodeSlide
        , body = Http.multipartBody [ Http.filePart "file" content ]
        }


publishVideo : (Result Http.Error () -> msg) -> Int -> Cmd msg
publishVideo resultToMsg id =
    post
        { url = "/api/capsule/" ++ String.fromInt id ++ "/publication"
        , expect = Http.expectWhatever resultToMsg
        , body = Http.emptyBody
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
                , ( "background", Maybe.withDefault Encode.null (Maybe.map Encode.string gos.background) )
                , ( "transitions", Encode.list Encode.int gos.transitions )
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


type alias OptionsContent a =
    { a
        | withVideo : Bool
        , webcamSize : Webcam.WebcamSize
        , webcamPosition : Webcam.WebcamPosition
    }


encodeOptionsContent : OptionsContent a -> Encode.Value
encodeOptionsContent { withVideo, webcamSize, webcamPosition } =
    Encode.object
        [ ( "with_video", Encode.bool withVideo )
        , ( "webcam_size", Encode.string <| encodeWebcamSize webcamSize )
        , ( "webcam_position", Encode.string <| encodeWebcamPosition webcamPosition )
        ]


updateOptions : (Result Http.Error Session -> msg) -> OptionsContent a -> Cmd msg
updateOptions resultToMsg content =
    Http.request
        { method = "PUT"
        , headers = []
        , url = "/api/options"
        , expect = Http.expectJson resultToMsg decodeSession
        , body = Http.jsonBody (encodeOptionsContent content)
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
    post
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
    post
        { url = "/api/test-mailer"
        , expect = Http.expectWhatever resultToMsg
        , body = Http.jsonBody (encodeMailerTestContent content)
        }


setupConfig : (Result Http.Error () -> msg) -> DatabaseTestContent a -> MailerTestContent b -> Cmd msg
setupConfig resultToMsg database mailer =
    post
        { url = "/api/setup-config"
        , expect = Http.expectWhatever resultToMsg
        , body = Http.jsonBody (encodeConfig database mailer)
        }
