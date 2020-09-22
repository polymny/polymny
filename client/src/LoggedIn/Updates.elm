module LoggedIn.Updates exposing (update)

import Acquisition.Types as Acquisition
import Acquisition.Updates as Acquisition
import Api
import Browser.Navigation as Nav
import Core.Types as Core
import Dropdown
import Edition.Types as Edition
import Edition.Updates as Edition
import File
import File.Select as Select
import Log
import LoggedIn.Ports as Ports
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
        ( LoggedIn.GosClicked i, LoggedIn.Preparation _ ) ->
            ( global, { session = session, tab = tab }, Ports.scrollIntoView ("gos-" ++ String.fromInt i) )

        ( LoggedIn.GosClicked i, LoggedIn.Edition editionModel ) ->
            let
                gosIndex : Int
                gosIndex =
                    (i - 1) // 2
            in
            ( global, { session = session, tab = LoggedIn.Edition { editionModel | currentGos = gosIndex } }, Cmd.none )

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
                editionModel.details
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
            updateUploadSlideShow global uploadSlideShowMsg { session = session, tab = tab } form

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
                newProjectName =
                    case dmsg of
                        Dropdown.OnFilterTyped name ->
                            name

                        _ ->
                            uploadForm.projectName

                ( newModel, newCmd ) =
                    Dropdown.update LoggedIn.dropdownConfig dmsg uploadForm.dropdown session.projects
            in
            ( global
            , LoggedIn.Model session
                (LoggedIn.Home { uploadForm | projectName = newProjectName, dropdown = newModel })
            , newCmd
            )

        ( LoggedIn.OptionPicked option, LoggedIn.Home uploadForm ) ->
            ( global, LoggedIn.Model session (LoggedIn.Home { uploadForm | projectSelected = option }), Cmd.none )

        ( LoggedIn.CancelRename, LoggedIn.Home uploadForm ) ->
            ( global, LoggedIn.Model session (LoggedIn.Home { uploadForm | rename = Nothing }), Cmd.none )

        ( LoggedIn.RenameMsg rename, LoggedIn.Home uploadForm ) ->
            ( global, LoggedIn.Model session (LoggedIn.Home { uploadForm | rename = Just rename }), Cmd.none )

        ( LoggedIn.ValidateRenameProject, LoggedIn.Home uploadForm ) ->
            let
                cmd =
                    case uploadForm.rename of
                        Just (LoggedIn.RenameProject ( i, s )) ->
                            Api.renameProject (\_ -> Core.Noop) i s

                        Just (LoggedIn.RenameCapsule ( _, j, s )) ->
                            Api.renameCapsule (\_ -> Core.Noop) j s

                        _ ->
                            Cmd.none

                mapper : Int -> String -> Api.Project -> Api.Project
                mapper id newName project =
                    if project.id == id then
                        { project | name = newName }

                    else
                        project

                mapperCapsule : Int -> String -> Api.Project -> Api.Project
                mapperCapsule id newName project =
                    { project
                        | capsules =
                            List.map
                                (\capsule ->
                                    if capsule.id == id then
                                        { capsule | name = newName }

                                    else
                                        capsule
                                )
                                project.capsules
                    }

                projects =
                    case uploadForm.rename of
                        Just (LoggedIn.RenameProject ( id, s )) ->
                            List.map (mapper id s) session.projects

                        Just (LoggedIn.RenameCapsule ( _, id, s )) ->
                            List.map (mapperCapsule id s) session.projects

                        _ ->
                            session.projects
            in
            ( global
            , LoggedIn.Model { session | projects = projects } (LoggedIn.Home { uploadForm | rename = Nothing })
            , cmd
            )

        _ ->
            ( global, LoggedIn.Model session tab, Cmd.none )


updateUploadSlideShow : Core.Global -> LoggedIn.UploadSlideShowMsg -> LoggedIn.Model -> LoggedIn.UploadForm -> ( Core.Global, LoggedIn.Model, Cmd Core.Msg )
updateUploadSlideShow global msg { session, tab } form =
    case msg of
        LoggedIn.UploadSlideShowSelectFileRequested ->
            ( global
            , LoggedIn.Model session (LoggedIn.Home form)
            , Select.file
                [ "application/pdf" ]
                (\x ->
                    Core.LoggedInMsg <|
                        LoggedIn.UploadSlideShowMsg <|
                            LoggedIn.UploadSlideShowFileReady x
                )
            )

        LoggedIn.UploadSlideShowFileReady file ->
            ( global
            , LoggedIn.Model session
                (LoggedIn.Home
                    { form
                        | status = Status.Sent
                        , file = Just file
                        , projectName = File.name file
                        , capsuleName = File.name file
                    }
                )
            , Api.quickUploadSlideShow (resultToMsg1 global.expiry) file
            )

        LoggedIn.UploadSlideShowFormSubmitted ->
            case form.file of
                Nothing ->
                    ( global, LoggedIn.Model session (LoggedIn.Home form), Cmd.none )

                Just file ->
                    ( global
                    , LoggedIn.Model session (LoggedIn.Home { form | status = Status.Sent })
                    , Api.quickUploadSlideShow (resultToMsg1 global.expiry) file
                    )

        LoggedIn.UploadSlideShowSuccess expiry capsule ->
            if expiry < global.expiry then
                ( global, { session = session, tab = tab }, Cmd.none )

            else
                ( global
                , LoggedIn.Model session
                    (LoggedIn.Home
                        { form
                            | status = Status.Success ()
                            , capsule = Just capsule
                            , slides = Just (List.indexedMap Tuple.pair capsule.slides)
                        }
                    )
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
            ( global
            , LoggedIn.Model session (LoggedIn.Home { form | status = Status.Error () })
            , Cmd.none
            )

        LoggedIn.UploadSlideShowChangeProjectName newName ->
            ( global
            , LoggedIn.Model session (LoggedIn.Home { form | projectName = newName })
            , Cmd.none
            )

        LoggedIn.UploadSlideShowChangeCapsuleName newName ->
            ( global
            , LoggedIn.Model session (LoggedIn.Home { form | capsuleName = newName })
            , Cmd.none
            )

        LoggedIn.UploadSlideShowGoToAcquisition ->
            case ( form.capsule, form.slides ) of
                ( Just c, Just s ) ->
                    ( global
                    , LoggedIn.Model session (LoggedIn.Home form)
                    , Api.validateCapsule resultToMsg4 (convertStructure s) form.projectSelected form.projectName form.capsuleName c
                    )

                _ ->
                    ( global, LoggedIn.Model session (LoggedIn.Home form), Cmd.none )

        LoggedIn.UploadSlideShowGoToPreparation ->
            case ( form.capsule, form.slides ) of
                ( Just c, Just s ) ->
                    ( global
                    , LoggedIn.Model session (LoggedIn.Home form)
                    , Api.validateCapsule resultToMsg5 (convertStructure s) form.projectSelected form.projectName form.capsuleName c
                    )

                _ ->
                    ( global, LoggedIn.Model session (LoggedIn.Home form), Cmd.none )

        LoggedIn.UploadSlideShowCancel ->
            ( { global | expiry = global.expiry + 1 }
            , LoggedIn.Model session
                (LoggedIn.Home
                    { form
                        | status = Status.NotSent
                        , file = Nothing
                        , capsule = Nothing
                        , projectSelected = Nothing
                    }
                )
            , Cmd.none
            )

        LoggedIn.UploadSlideShowSlideClicked index ->
            let
                increment : List ( Int, Api.Slide ) -> List ( Int, Api.Slide )
                increment =
                    List.map (\( x, y ) -> ( x + 1, y ))

                slides =
                    case form.slides of
                        Nothing ->
                            Nothing

                        Just s ->
                            case ( List.head (List.drop (index - 1) s), List.head (List.drop index s) ) of
                                ( _, Nothing ) ->
                                    Nothing

                                ( Nothing, _ ) ->
                                    form.slides

                                ( Just ( ip, _ ), Just ( i, slide ) ) ->
                                    if ip == i then
                                        Just (List.take index s ++ (( i + 1, slide ) :: List.drop (index + 1) (increment s)))

                                    else
                                        Just (List.take index s ++ (( ip, slide ) :: List.drop (index + 1) s))

                reindexSlidesAux : Int -> Int -> List ( Int, Api.Slide ) -> List ( Int, Api.Slide ) -> List ( Int, Api.Slide )
                reindexSlidesAux counter currentValue current input =
                    case input of
                        [] ->
                            current

                        ( i, s ) :: t ->
                            if i /= currentValue then
                                reindexSlidesAux (counter + 1) i (( counter + 1, s ) :: current) t

                            else
                                reindexSlidesAux counter i (( counter, s ) :: current) t

                reindexSlides : List ( Int, Api.Slide ) -> List ( Int, Api.Slide )
                reindexSlides input =
                    List.reverse (reindexSlidesAux 0 0 [] input)

                newSlides =
                    Maybe.map reindexSlides slides
            in
            ( global
            , LoggedIn.Model session (LoggedIn.Home { form | slides = newSlides })
            , Cmd.none
            )


getId : ( Int, Api.Slide ) -> Int
getId ( _, y ) =
    y.id


convertStructureAux : List (List ( Int, Api.Slide )) -> List ( Int, Api.Slide ) -> List (List ( Int, Api.Slide ))
convertStructureAux current input =
    case ( input, current ) of
        ( [], _ ) ->
            current

        ( h :: t, [] ) ->
            convertStructureAux [ [ h ] ] t

        ( h :: t, [] :: t2 ) ->
            convertStructureAux ([ h ] :: t2) t

        ( h :: t, (h2 :: r2) :: t2 ) ->
            if Tuple.first h == Tuple.first h2 then
                convertStructureAux ((h :: h2 :: r2) :: t2) t

            else
                convertStructureAux ([ h ] :: (h2 :: r2) :: t2) t


convertStructure : List ( Int, Api.Slide ) -> List (List Int)
convertStructure input =
    List.reverse (List.map List.reverse (List.map (\x -> List.map getId x) (convertStructureAux [] input)))


resultToMsg : Api.Project -> Result e (List Api.Capsule) -> Core.Msg
resultToMsg project result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <|
                LoggedIn.CapsulesReceived project x
        )
        (\_ -> Core.Noop)
        result


resultToMsg1 : Int -> Result e Api.CapsuleDetails -> Core.Msg
resultToMsg1 expiry result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <| LoggedIn.UploadSlideShowMsg <| LoggedIn.UploadSlideShowSuccess expiry x
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


resultToMsg4 : Result e Api.CapsuleDetails -> Core.Msg
resultToMsg4 result =
    case result of
        Ok o ->
            Core.LoggedInMsg (LoggedIn.AcquisitionClicked o)

        Err e ->
            let
                _ =
                    Log.debug "Request fail" e
            in
            Core.Noop


resultToMsg5 : Result e Api.CapsuleDetails -> Core.Msg
resultToMsg5 result =
    case result of
        Ok o ->
            Core.LoggedInMsg (LoggedIn.PreparationClicked o)

        Err e ->
            let
                _ =
                    Log.debug "Request fail" e
            in
            Core.Noop
