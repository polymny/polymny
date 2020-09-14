module LoggedIn.Updates exposing (update)

import Acquisition.Types as Acquisition
import Acquisition.Updates as Acquisition
import Api
import Browser.Navigation as Nav
import Core.Types as Core
import Dropdown
import Edition.Types as Edition
import Edition.Updates as Edition
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import File
import File.Select as Select
import LoggedIn.Types as LoggedIn
import LoggedIn.Views as LoggedIn
import NewCapsule.Types as NewCapsule
import NewCapsule.Updates as NewCapsule
import NewProject.Types as NewProject
import NewProject.Updates as NewProject
import Preparation.Types as Preparation
import Preparation.Updates as Preparation
import Settings.Types as Settings
import Settings.Updates as Settings
import Status
import Utils


flatten : ( a, ( b, c ) ) -> ( a, b, c )
flatten ( a, ( b, c ) ) =
    ( a, b, c )


update : LoggedIn.Msg -> Core.Global -> LoggedIn.Model -> ( Core.Global, LoggedIn.Model, Cmd Core.Msg )
update msg global { session, tab } =
    case ( msg, tab ) of
        ( LoggedIn.PreparationMsg preparationMsg, LoggedIn.Preparation model ) ->
            let
                ( newGlobal, newModel, cmd ) =
                    Preparation.update preparationMsg global model
            in
            ( newGlobal, { session = session, tab = LoggedIn.Preparation newModel }, cmd )

        ( LoggedIn.PreparationClicked capsule, _ ) ->
            ( global
            , { session = session, tab = LoggedIn.Preparation (Preparation.init capsule) }
            , Nav.pushUrl global.key ("/capsule/" ++ String.fromInt capsule.capsule.id ++ "/preparation")
            )

        ( LoggedIn.AcquisitionMsg acquisitionMsg, LoggedIn.Acquisition model ) ->
            flatten ( global, Acquisition.update global session acquisitionMsg model )

        ( LoggedIn.AcquisitionClicked capsule, _ ) ->
            let
                ( model, cmd ) =
                    Acquisition.initAtFirstNonRecorded global.mattingEnabled capsule Acquisition.All

                coreCmd =
                    Cmd.map (\x -> Core.LoggedInMsg (LoggedIn.AcquisitionMsg x)) cmd
            in
            ( global
            , { session = session, tab = LoggedIn.Acquisition model }
            , Cmd.batch
                [ coreCmd
                , Nav.pushUrl global.key ("/capsule/" ++ String.fromInt capsule.capsule.id ++ "/acquisition")
                ]
            )

        ( LoggedIn.EditionMsg editionMsg, LoggedIn.Edition model ) ->
            flatten ( global, Edition.update session editionMsg model )

        ( LoggedIn.EditionClicked capsule False, _ ) ->
            let
                editionModel =
                    Edition.selectEditionOptions session capsule.capsule (Edition.init capsule)
            in
            ( global
            , { session = session
              , tab = LoggedIn.Edition editionModel
              }
            , Nav.pushUrl global.key ("/capsule/" ++ String.fromInt capsule.capsule.id ++ "/edition")
            )

        ( LoggedIn.EditionClicked capsule True, _ ) ->
            let
                editionModel =
                    Edition.selectEditionOptions session capsule.capsule (Edition.init capsule)
            in
            ( global
            , { session = session
              , tab = LoggedIn.Edition { editionModel | status = Status.Sent }
              }
            , Api.editionAuto resultToMsg3
                capsule.capsule.id
                { withVideo = editionModel.withVideo
                , webcamSize = editionModel.webcamSize
                , webcamPosition = editionModel.webcamPosition
                }
            )

        ( LoggedIn.Record capsule gos, _ ) ->
            let
                ( t, cmd ) =
                    Acquisition.init global.mattingEnabled capsule Acquisition.Single gos
            in
            ( global
            , { session = session, tab = LoggedIn.Acquisition t }
            , Cmd.map (\x -> Core.LoggedInMsg (LoggedIn.AcquisitionMsg x)) cmd
            )

        ( LoggedIn.CapsuleReceived capsuleDetails, _ ) ->
            ( global
            , { session = session, tab = LoggedIn.Preparation (Preparation.init capsuleDetails) }
            , Nav.pushUrl global.key ("/capsule/" ++ String.fromInt capsuleDetails.capsule.id ++ "/preparation")
            )

        --( LoggedIn.AcquisitionMsg Acquisition.AcquisitionClicked, _ ) ->
        --   ( LoggedIn.Model session tab, Cmd.none )
        ( LoggedIn.UploadSlideShowMsg uploadSlideShowMsg, LoggedIn.Home form ) ->
            flatten ( global, updateUploadSlideShow global uploadSlideShowMsg { session = session, tab = tab } form )

        ( LoggedIn.NewProjectMsg newProjectMsg, LoggedIn.NewProject newProjectModel ) ->
            let
                ( newSession, newModel, cmd ) =
                    NewProject.update session newProjectMsg newProjectModel
            in
            ( global
            , { session = newSession, tab = LoggedIn.NewProject newModel }
            , Cmd.batch
                [ cmd
                , Nav.pushUrl global.key "/new-project"
                ]
            )

        ( LoggedIn.ProjectClicked project, _ ) ->
            ( global
            , { session = session
              , tab = LoggedIn.Project project Nothing
              }
            , Api.capsulesFromProjectId (resultToMsg project) project.id
            )

        ( LoggedIn.CapsulesReceived project capsules, _ ) ->
            let
                newSession =
                    { session | active_project = Just project }
            in
            ( global
            , { session = newSession
              , tab = LoggedIn.Project { project | capsules = capsules } Nothing
              }
            , Nav.pushUrl global.key ("/project/" ++ String.fromInt project.id)
            )

        ( LoggedIn.NewCapsuleMsg newCapsuleMsg, LoggedIn.Project project (Just newCapsuleModel) ) ->
            let
                ( newModel, cmd ) =
                    NewCapsule.update project newCapsuleMsg newCapsuleModel
            in
            ( global
            , { session = session
              , tab = newModel
              }
            , cmd
            )

        ( LoggedIn.NewCapsuleClicked project, _ ) ->
            ( global
            , { session = session
              , tab = LoggedIn.Project project (Just NewCapsule.init)
              }
            , Nav.pushUrl global.key ("/new-capsule/" ++ String.fromInt project.id)
            )

        ( LoggedIn.CapsuleClicked capsule, _ ) ->
            ( global
            , { session = session
              , tab = tab
              }
            , Api.capsuleFromId resultToMsg2 capsule.id
            )

        ( LoggedIn.SettingsClicked, _ ) ->
            ( global
            , { session = session
              , tab = LoggedIn.Settings Settings.init
              }
            , Nav.pushUrl
                global.key
                "/settings"
            )

        ( LoggedIn.SettingsMsg newSettingsMsg, LoggedIn.Settings settingsModel ) ->
            let
                ( newSession, newModel, cmd ) =
                    Settings.update session newSettingsMsg settingsModel
            in
            ( global
            , { session = newSession, tab = LoggedIn.Settings newModel }
            , cmd
            )

        ( LoggedIn.ToggleFoldedProject id, _ ) ->
            let
                newProjects =
                    List.map
                        (\x ->
                            if x.id == id then
                                { x | folded = not x.folded }

                            else
                                x
                        )
                        session.projects
            in
            ( global, LoggedIn.Model { session | projects = newProjects } tab, Cmd.none )

        ( LoggedIn.DropdownMsg dmsg, LoggedIn.Home uploadForm ) ->
            let
                ( newModel, newCmd ) =
                    Dropdown.update LoggedIn.dropdownConfig dmsg uploadForm.dropdown (List.map .name session.projects)
            in
            ( global, LoggedIn.Model session (LoggedIn.Home { uploadForm | dropdown = newModel }), newCmd )

        _ ->
            ( global, LoggedIn.Model session tab, Cmd.none )


updateUploadSlideShow : Core.Global -> LoggedIn.UploadSlideShowMsg -> LoggedIn.Model -> LoggedIn.UploadForm -> ( LoggedIn.Model, Cmd Core.Msg )
updateUploadSlideShow global msg { session } form =
    case msg of
        LoggedIn.UploadSlideShowSelectFileRequested ->
            ( LoggedIn.Model session (LoggedIn.Home form)
            , Select.file
                [ "application/pdf" ]
                (\x ->
                    Core.LoggedInMsg <|
                        LoggedIn.UploadSlideShowMsg <|
                            LoggedIn.UploadSlideShowFileReady x
                )
            )

        LoggedIn.UploadSlideShowFileReady file ->
            ( LoggedIn.Model session
                (LoggedIn.Home
                    { form
                        | status = Status.Sent
                        , file = Just file
                        , projectName = File.name file
                        , capsuleName = File.name file
                    }
                )
            , Api.quickUploadSlideShow resultToMsg1 file
            )

        LoggedIn.UploadSlideShowFormSubmitted ->
            case form.file of
                Nothing ->
                    ( LoggedIn.Model session (LoggedIn.Home form), Cmd.none )

                Just file ->
                    ( LoggedIn.Model session (LoggedIn.Home { form | status = Status.Sent })
                    , Api.quickUploadSlideShow resultToMsg1 file
                    )

        LoggedIn.UploadSlideShowSuccess capsule ->
            ( LoggedIn.Model session (LoggedIn.Home { form | status = Status.Success (), capsule = Just capsule })
            , Cmd.none
            )

        -- let
        --     ( model, cmd ) =
        --         Acquisition.initAtFirstNonRecorded global.mattingEnabled capsule Acquisition.All
        --     coreCmd =
        --         Cmd.map (\x -> Core.LoggedInMsg (LoggedIn.AcquisitionMsg x)) cmd
        -- in
        -- ( LoggedIn.Model session (LoggedIn.Acquisition model)
        -- , coreCmd
        -- )
        LoggedIn.UploadSlideShowError ->
            ( LoggedIn.Model session (LoggedIn.Home { form | status = Status.Error () })
            , Cmd.none
            )

        LoggedIn.UploadSlideShowChangeProjectName newName ->
            ( LoggedIn.Model session (LoggedIn.Home { form | projectName = newName })
            , Cmd.none
            )

        LoggedIn.UploadSlideShowChangeCapsuleName newName ->
            ( LoggedIn.Model session (LoggedIn.Home { form | capsuleName = newName })
            , Cmd.none
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
        (\_ -> Core.LoggedInMsg <| LoggedIn.UploadSlideShowMsg <| LoggedIn.UploadSlideShowError)
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
        (\_ -> Core.LoggedInMsg <| LoggedIn.EditionMsg <| Edition.AutoFailed)
        result
