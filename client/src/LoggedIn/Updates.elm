module LoggedIn.Updates exposing (update)

import Acquisition.Types as Acquisition
import Acquisition.Updates as Acquisition
import Api
import Browser.Navigation as Nav
import Core.Types as Core
import Edition.Types as Edition
import Edition.Updates as Edition
import File.Select as Select
import LoggedIn.Types as LoggedIn
import NewCapsule.Types as NewCapsule
import NewCapsule.Updates as NewCapsule
import NewProject.Types as NewProject
import NewProject.Updates as NewProject
import Preparation.Types as Preparation
import Preparation.Updates as Preparation
import Status
import Utils


update : LoggedIn.Msg -> Core.Global -> LoggedIn.Model -> ( LoggedIn.Model, Cmd Core.Msg )
update msg global { session, tab } =
    case ( msg, tab ) of
        ( LoggedIn.PreparationMsg preparationMsg, LoggedIn.Preparation model ) ->
            let
                ( newModel, cmd ) =
                    Preparation.update preparationMsg model
            in
            ( { session = session, tab = LoggedIn.Preparation newModel }, cmd )

        ( LoggedIn.PreparationClicked capsule, _ ) ->
            ( { session = session, tab = LoggedIn.Preparation (Preparation.init capsule) }
            , Nav.pushUrl global.key ("/capsule/" ++ String.fromInt capsule.capsule.id ++ "/preparation")
            )

        ( LoggedIn.AcquisitionMsg acquisitionMsg, LoggedIn.Acquisition model ) ->
            Acquisition.update session acquisitionMsg model

        ( LoggedIn.AcquisitionClicked capsule, _ ) ->
            let
                ( model, cmd ) =
                    Acquisition.initAtFirstNonRecorded capsule Acquisition.All

                coreCmd =
                    Cmd.map (\x -> Core.LoggedInMsg (LoggedIn.AcquisitionMsg x)) cmd
            in
            ( { session = session, tab = LoggedIn.Acquisition model }
            , Cmd.batch
                [ coreCmd
                , Nav.pushUrl global.key ("/capsule/" ++ String.fromInt capsule.capsule.id ++ "/acquisition")
                ]
            )

        ( LoggedIn.EditionMsg editionMsg, LoggedIn.Edition model ) ->
            Edition.update session editionMsg model

        ( LoggedIn.EditionClicked capsule False, _ ) ->
            let
                editionModel =
                    { status = Status.Success ()
                    , details = capsule
                    , withVideo = True
                    , webcamSize = Edition.Medium
                    , webcamPosition = Edition.BottomLeft
                    }
            in
            ( { session = session
              , tab = LoggedIn.Edition editionModel
              }
            , Nav.pushUrl global.key ("/capsule/" ++ String.fromInt capsule.capsule.id ++ "/edition")
            )

        ( LoggedIn.EditionClicked details True, _ ) ->
            let
                editionModel =
                    { status = Status.Sent
                    , details = details
                    , withVideo = True
                    , webcamSize = Edition.Medium
                    , webcamPosition = Edition.BottomLeft
                    }
            in
            ( { session = session
              , tab = LoggedIn.Edition editionModel
              }
            , Api.editionAuto resultToMsg3
                details.capsule.id
                { withVideo = True
                , webcamSize = "Medium"
                , webcamPosition = "BottomLeft"
                }
            )

        ( LoggedIn.Record capsule gos, _ ) ->
            let
                ( t, cmd ) =
                    Acquisition.init capsule Acquisition.Single gos
            in
            ( { session = session, tab = LoggedIn.Acquisition t }, Cmd.map (\x -> Core.LoggedInMsg (LoggedIn.AcquisitionMsg x)) cmd )

        ( LoggedIn.CapsuleReceived capsuleDetails, _ ) ->
            ( { session = session, tab = LoggedIn.Preparation (Preparation.init capsuleDetails) }
            , Nav.pushUrl global.key ("/capsule/" ++ String.fromInt capsuleDetails.capsule.id ++ "/preparation")
            )

        --( LoggedIn.AcquisitionMsg Acquisition.AcquisitionClicked, _ ) ->
        --   ( LoggedIn.Model session tab, Cmd.none )
        ( LoggedIn.UploadSlideShowMsg uploadSlideShowMsg, LoggedIn.Home form showMenu ) ->
            let
                ( newModel, cmd ) =
                    updateUploadSlideShow uploadSlideShowMsg { session = session, tab = tab } form showMenu
            in
            ( newModel, cmd )

        ( LoggedIn.ShowMenuToggleMsg, LoggedIn.Home form showMenu ) ->
            ( { session = session, tab = LoggedIn.Home form (not showMenu) }, Cmd.none )

        ( LoggedIn.NewProjectMsg newProjectMsg, LoggedIn.NewProject newProjectModel ) ->
            let
                ( newSession, newModel, cmd ) =
                    NewProject.update session newProjectMsg newProjectModel
            in
            ( { session = newSession, tab = LoggedIn.NewProject newModel }
            , Cmd.batch
                [ cmd
                , Nav.pushUrl global.key "/new-project"
                ]
            )

        ( LoggedIn.ProjectClicked project, _ ) ->
            ( { session = session
              , tab = LoggedIn.Project project Nothing
              }
            , Api.capsulesFromProjectId (resultToMsg project) project.id
            )

        ( LoggedIn.CapsulesReceived project capsules, _ ) ->
            let
                newSession =
                    { session | active_project = Just project }
            in
            ( { session = newSession
              , tab = LoggedIn.Project { project | capsules = capsules } Nothing
              }
            , Nav.pushUrl global.key ("/project/" ++ String.fromInt project.id)
            )

        ( LoggedIn.NewCapsuleMsg newCapsuleMsg, LoggedIn.Project project (Just newCapsuleModel) ) ->
            let
                ( newModel, cmd ) =
                    NewCapsule.update project newCapsuleMsg newCapsuleModel
            in
            ( { session = session
              , tab = newModel
              }
            , cmd
            )

        ( LoggedIn.NewCapsuleClicked project, _ ) ->
            ( { session = session
              , tab = LoggedIn.Project project (Just NewCapsule.init)
              }
            , Nav.pushUrl global.key ("/new-capsule/" ++ String.fromInt project.id)
            )

        ( LoggedIn.CapsuleClicked capsule, _ ) ->
            ( { session = session
              , tab = tab
              }
            , Api.capsuleFromId resultToMsg2 capsule.id
            )

        _ ->
            ( LoggedIn.Model session tab, Cmd.none )


updateUploadSlideShow : LoggedIn.UploadSlideShowMsg -> LoggedIn.Model -> LoggedIn.UploadForm -> Bool -> ( LoggedIn.Model, Cmd Core.Msg )
updateUploadSlideShow msg { session } form showMenu =
    case msg of
        LoggedIn.UploadSlideShowSelectFileRequested ->
            ( LoggedIn.Model session (LoggedIn.Home form showMenu)
            , Select.file
                [ "application/pdf" ]
                (\x ->
                    Core.LoggedInMsg <|
                        LoggedIn.UploadSlideShowMsg <|
                            LoggedIn.UploadSlideShowFileReady x
                )
            )

        LoggedIn.UploadSlideShowFileReady file ->
            ( LoggedIn.Model session (LoggedIn.Home { form | status = Status.Sent, file = Just file } showMenu)
            , Api.quickUploadSlideShow resultToMsg1 file
            )

        LoggedIn.UploadSlideShowFormSubmitted ->
            case form.file of
                Nothing ->
                    ( LoggedIn.Model session (LoggedIn.Home form showMenu), Cmd.none )

                Just file ->
                    ( LoggedIn.Model session (LoggedIn.Home { form | status = Status.Sent } showMenu)
                    , Api.quickUploadSlideShow resultToMsg1 file
                    )

        LoggedIn.UploadSlideShowSuccess capsule ->
            let
                ( model, cmd ) =
                    Acquisition.initAtFirstNonRecorded capsule Acquisition.All

                coreCmd =
                    Cmd.map (\x -> Core.LoggedInMsg (LoggedIn.AcquisitionMsg x)) cmd
            in
            ( LoggedIn.Model session (LoggedIn.Acquisition model)
            , coreCmd
            )


resultToMsg : Api.Project -> Result e (List Api.Capsule) -> Core.Msg
resultToMsg project result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <|
                LoggedIn.CapsulesReceived project x
        )
        (\_ -> Core.Noop)
        result


resultToMsg1 : Result e Api.CapsuleDetails -> Core.Msg
resultToMsg1 result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <| LoggedIn.UploadSlideShowMsg <| LoggedIn.UploadSlideShowSuccess x
        )
        (\_ -> Core.Noop)
        result


resultToMsg2 : Result e Api.CapsuleDetails -> Core.Msg
resultToMsg2 result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <|
                LoggedIn.CapsuleReceived x
        )
        (\_ -> Core.Noop)
        result


resultToMsg3 : Result e Api.CapsuleDetails -> Core.Msg
resultToMsg3 result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <| LoggedIn.EditionMsg <| Edition.AutoSuccess x
        )
        (\_ -> Core.Noop)
        result
