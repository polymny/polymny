module Core.Utils exposing (..)

import Acquisition.Types as Acquisition
import Admin.Types as Admin
import Api
import Browser.Navigation
import Capsule exposing (Capsule)
import CapsuleSettings.Types as CapsuleSettings
import Core.Types as Core
import Http
import Json.Decode as Decode exposing (Decoder)
import Lang
import List.Extra
import Log
import Preparation.Types as Preparation
import Production.Types as Production
import Publication.Types as Publication
import Route exposing (Route)
import Settings.Types as Settings
import Task
import Time
import Url
import User exposing (User)
import Utils exposing (andMap)


init : Decode.Value -> Url.Url -> Browser.Navigation.Key -> ( Maybe Core.Model, Cmd Core.Msg )
init flags url key =
    let
        global =
            Decode.decodeValue (Decode.field "global" (decodeGlobal key)) flags

        sortBy =
            global |> Result.map .sortBy |> Result.withDefault ( User.LastModified, False )

        user =
            Decode.decodeValue (Decode.field "user" (User.decode sortBy)) flags
    in
    case ( user, global ) of
        ( Ok u, Ok g ) ->
            let
                ( page, cmd ) =
                    pageFromRoute g u (Core.Home Core.newHomeModel) (Route.fromUrl url) Nothing
            in
            ( Just { user = u, global = g, page = page, popup = Nothing }
            , Cmd.batch [ Task.perform Core.TimeZoneChanged Time.here, cmd ]
            )

        ( a, b ) ->
            let
                _ =
                    Log.debug "user" a

                _ =
                    Log.debug "global" b
            in
            ( Nothing, Cmd.none )


decodeGlobal : Browser.Navigation.Key -> Decoder Core.Global
decodeGlobal key =
    Decode.succeed Core.Flags
        |> andMap (Decode.field "root" Decode.string)
        |> andMap (Decode.field "socket_root" Decode.string)
        |> andMap (Decode.field "video_root" Decode.string)
        |> andMap (Decode.field "version" Decode.string)
        |> andMap (Decode.maybe (Decode.field "commit" Decode.string))
        |> andMap (Decode.maybe (Decode.field "home" Decode.string))
        |> andMap (Decode.field "registration_disabled" Decode.bool)
        |> andMap (Decode.maybe (Decode.field "request_language" Lang.decode))
        |> andMap (Decode.maybe (Decode.field "storage_language" Lang.decode))
        |> andMap (Decode.maybe (Decode.field "zoomLevel" Decode.int) |> Decode.map (Maybe.withDefault 3))
        |> andMap (Decode.maybe (Decode.field "acquisitionInverted" Decode.bool) |> Decode.map (Maybe.withDefault False))
        |> andMap (Decode.maybe (Decode.field "videoDeviceId" Decode.string))
        |> andMap (Decode.maybe (Decode.field "resolution" Decode.string))
        |> andMap (Decode.maybe (Decode.field "audioDeviceId" Decode.string))
        |> andMap (Decode.field "sortBy" User.decodeSortBy)
        |> andMap (Decode.field "promptSize" Decode.int)
        |> Decode.map (Core.flagsToGlobal key)


pageFromRoute : Core.Global -> User -> Core.Page -> Route -> Maybe Capsule -> ( Core.Page, Cmd Core.Msg )
pageFromRoute global user currentPage route extraCapsule =
    let
        devices =
            global.devices

        findCapsule : String -> ( Maybe Capsule, Cmd Core.Msg )
        findCapsule id =
            case extraCapsule of
                Just x ->
                    ( Just x, Cmd.none )

                Nothing ->
                    case List.concatMap .capsules user.projects |> List.Extra.find (\x -> x.id == id) of
                        Just y ->
                            ( Just y, Cmd.none )

                        _ ->
                            ( Nothing, Api.getCapsule resultToMsg id )

        resultToMsg : Result Http.Error Capsule -> Core.Msg
        resultToMsg result =
            case result of
                Ok o ->
                    Core.ExtraCapsuleReceived route o

                _ ->
                    Core.Noop
    in
    case route of
        Route.Home ->
            ( Core.Home Core.newHomeModel, Cmd.none )

        Route.Preparation c _ ->
            let
                ( capsule, cmd ) =
                    findCapsule c
            in
            capsule
                |> Maybe.map (\x -> ( Core.Preparation (Preparation.init x), Cmd.none ))
                |> Maybe.withDefault ( Core.Home Core.newHomeModel, cmd )

        Route.Acquisition c id ->
            let
                ( capsule, cmd ) =
                    findCapsule c

                chosenDevice =
                    { videoDeviceId = global.videoDeviceId
                    , resolution = global.resolution
                    , audioDeviceId = global.audioDeviceId
                    }
            in
            capsule
                |> Maybe.map (\x -> Acquisition.init devices chosenDevice x id)
                |> Maybe.map (Tuple.mapFirst Core.Acquisition)
                |> Maybe.map (Tuple.mapSecond (\x -> Cmd.map Core.AcquisitionMsg x))
                |> Maybe.withDefault ( Core.Home Core.newHomeModel, cmd )

        Route.Production c id ->
            let
                ( capsule, cmd ) =
                    findCapsule c
            in
            capsule
                |> Maybe.map (\x -> ( Core.Production (Production.init x id), Cmd.none ))
                |> Maybe.withDefault ( Core.Home Core.newHomeModel, cmd )

        Route.Publication c ->
            let
                ( capsule, cmd ) =
                    findCapsule c
            in
            capsule
                |> Maybe.map (\x -> ( Core.Publication (Publication.init x), Cmd.none ))
                |> Maybe.withDefault ( Core.Home Core.newHomeModel, cmd )

        Route.CapsuleSettings c ->
            let
                ( capsule, cmd ) =
                    findCapsule c
            in
            capsule
                |> Maybe.map (\x -> ( Core.CapsuleSettings (CapsuleSettings.init x), Cmd.none ))
                |> Maybe.withDefault ( Core.Home Core.newHomeModel, cmd )

        Route.Settings ->
            ( Core.Settings (Settings.init user), Cmd.none )

        Route.Admin Route.Dashboard ->
            let
                resultToMsg2 : Result Http.Error String -> Core.Msg
                resultToMsg2 result =
                    case result of
                        Ok dashboard ->
                            Core.AdminDashboard dashboard

                        _ ->
                            Core.Noop
            in
            ( Core.Home Core.newHomeModel, Api.dashboard resultToMsg2 )

        Route.Admin (Route.User i) ->
            case currentPage of
                Core.Admin admin ->
                    let
                        newPage =
                            List.Extra.find (\x -> x.id == i) admin.users
                                |> Maybe.map Admin.UserPage
                                |> Maybe.withDefault Admin.Dashboard
                    in
                    ( Core.Admin { admin | page = newPage }, Cmd.none )

                _ ->
                    let
                        resultToMsg3 : Result Http.Error Admin.User -> Core.Msg
                        resultToMsg3 result =
                            case result of
                                Ok u ->
                                    Core.AdminUser u

                                _ ->
                                    Core.Noop
                    in
                    ( Core.Home Core.newHomeModel, Api.adminUser resultToMsg3 i )

        Route.Admin (Route.Users offset) ->
            let
                resultToMsg3 : Result Http.Error (List Admin.User) -> Core.Msg
                resultToMsg3 result =
                    case result of
                        Ok users ->
                            Core.AdminUsers users offset

                        _ ->
                            Core.Noop
            in
            ( Core.Home Core.newHomeModel, Api.adminUsers resultToMsg3 offset )

        Route.Admin (Route.Capsules pagination) ->
            let
                resultToMsg4 : Result Http.Error (List Capsule) -> Core.Msg
                resultToMsg4 result =
                    case result of
                        Ok capsules ->
                            Core.AdminCapsules capsules pagination

                        _ ->
                            Core.Noop
            in
            ( Core.Home Core.newHomeModel, Api.adminCapsules resultToMsg4 pagination )

        Route.Custom _ ->
            ( Core.NotFound, Cmd.none )

        Route.NotFound ->
            ( Core.NotFound, Cmd.none )


userDiskUsage : User -> Float
userDiskUsage user =
    let
        sizeinMb =
            List.map
                (\x ->
                    x.capsules
                        |> List.filter (\y -> y.role == Capsule.Owner)
                        |> List.map .diskUsage
                        |> List.sum
                )
                user.projects
                |> List.sum
                |> toFloat
    in
    sizeinMb / 1000
