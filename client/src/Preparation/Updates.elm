module Preparation.Updates exposing (update)

import Api
import Core.Types as Core
import Dict
import File
import File.Select as Select
import LoggedIn.Types as LoggedIn
import Preparation.Types as Preparation
import Status
import Utils


update : Preparation.Msg -> Core.Global -> Preparation.Model -> ( Core.Global, Preparation.Model, Cmd Core.Msg )
update msg global capsuleModel =
    case ( msg, capsuleModel ) of
        ( Preparation.UploadSlideShowMsg newUploadSlideShowMsg, model ) ->
            let
                ( newFormModel, newCmd ) =
                    updateUploadSlideShow newUploadSlideShowMsg model.uploadForms.slideShow model.details.capsule.id

                oldUploadForms =
                    model.uploadForms

                newUploadForms =
                    { oldUploadForms | slideShow = newFormModel }
            in
            ( global, { model | uploadForms = newUploadForms }, newCmd )

        ( Preparation.UploadBackgroundMsg newUploadBackgroundMsg, model ) ->
            let
                ( newFormModel, newCmd ) =
                    updateUploadBackground newUploadBackgroundMsg model.uploadForms.background model.details.capsule.id

                oldUploadForms =
                    model.uploadForms

                newUploadForms =
                    { oldUploadForms | background = newFormModel }
            in
            ( global, { model | uploadForms = newUploadForms }, newCmd )

        ( Preparation.UploadLogoMsg newUploadLogoMsg, model ) ->
            let
                ( newFormModel, newCmd ) =
                    updateUploadLogo newUploadLogoMsg model.uploadForms.logo model.details.capsule.id

                oldUploadForms =
                    model.uploadForms

                newUploadForms =
                    { oldUploadForms | logo = newFormModel }
            in
            ( global, { model | uploadForms = newUploadForms }, newCmd )

        ( Preparation.UploadExtraResourceMsg newUploadExtraResourceMsg, model ) ->
            let
                ( newFormModel, newCmd, newModel ) =
                    updateUploadExtraResource newUploadExtraResourceMsg model.uploadForms.extraResource model

                oldUploadForms =
                    newModel.uploadForms

                newUploadForms =
                    { oldUploadForms | extraResource = newFormModel }
            in
            ( global, { newModel | uploadForms = newUploadForms }, newCmd )

        ( Preparation.ReplaceSlideMsg newReplaceSlideMsg, model ) ->
            let
                ( newFormModel, newCmd, newModel ) =
                    updateReplaceSlide newReplaceSlideMsg model.uploadForms.replaceSlide model

                oldUploadForms =
                    newModel.uploadForms

                newUploadForms =
                    { oldUploadForms | replaceSlide = newFormModel }
            in
            ( global, { newModel | uploadForms = newUploadForms }, newCmd )

        ( Preparation.EditPromptMsg editPromptMsg, model ) ->
            let
                slides =
                    List.filterMap Preparation.filterSlide (List.concat model.slides)

                ( newModel, newCmd ) =
                    updateEditPromptMsg slides editPromptMsg model.editPrompt
            in
            ( global, { model | editPrompt = newModel }, newCmd )

        ( Preparation.DnD slideMsg, model ) ->
            let
                ( data, cmd, shouldSync ) =
                    updateDnD slideMsg model

                moveCmd =
                    Cmd.map (\x -> Core.LoggedInMsg (LoggedIn.PreparationMsg (Preparation.DnD x))) cmd

                syncCmd =
                    Api.updateSlideStructure resultToMsg data.details

                cmds =
                    if shouldSync then
                        Cmd.batch [ moveCmd, syncCmd ]

                    else
                        moveCmd
            in
            ( global, data, cmds )

        ( Preparation.SwitchLock i, _ ) ->
            let
                gosStructure : Maybe Api.Gos
                gosStructure =
                    List.head (List.drop i capsuleModel.details.structure)

                gosUpdatedStructure : Maybe Api.Gos
                gosUpdatedStructure =
                    Maybe.map (\x -> { x | locked = not x.locked }) gosStructure

                newStructure : List Api.Gos
                newStructure =
                    case gosUpdatedStructure of
                        Just new ->
                            List.take i capsuleModel.details.structure
                                ++ (new :: List.drop (i + 1) capsuleModel.details.structure)

                        _ ->
                            capsuleModel.details.structure

                details : Api.CapsuleDetails
                details =
                    capsuleModel.details

                newDetails : Api.CapsuleDetails
                newDetails =
                    { details | structure = newStructure }
            in
            ( global, { capsuleModel | details = newDetails }, Cmd.none )

        ( Preparation.GosDelete i, _ ) ->
            let
                newStructure : List Api.Gos
                newStructure =
                    List.take i capsuleModel.details.structure
                        ++ List.drop (i + 1) capsuleModel.details.structure

                details : Api.CapsuleDetails
                details =
                    capsuleModel.details

                newDetails : Api.CapsuleDetails
                newDetails =
                    { details | structure = newStructure }
            in
            ( global, { capsuleModel | details = newDetails }, Api.updateSlideStructure resultToMsg newDetails )

        ( Preparation.SlideDelete gos_i slide_i, _ ) ->
            let
                gosStructure : Maybe Api.Gos
                gosStructure =
                    List.head (List.drop gos_i capsuleModel.details.structure)

                gosUpdatedStructure : Maybe ( Api.Gos, Bool )
                gosUpdatedStructure =
                    case gosStructure of
                        Just gos ->
                            let
                                newSlides =
                                    List.filter (\x -> x.id /= slide_i) gos.slides

                                ( newGos, lost ) =
                                    if newSlides /= gos.slides then
                                        ( { gos | slides = newSlides, transitions = [], record = Nothing }
                                        , gos.record /= Nothing
                                        )

                                    else
                                        ( gos, False )
                            in
                            Just ( newGos, lost )

                        _ ->
                            Nothing

                newStructure : List Api.Gos
                newStructure =
                    case gosUpdatedStructure of
                        Just ( new, _ ) ->
                            if List.isEmpty new.slides then
                                List.take gos_i capsuleModel.details.structure
                                    ++ List.drop (gos_i + 1) capsuleModel.details.structure

                            else
                                List.take gos_i capsuleModel.details.structure
                                    ++ (new :: List.drop (gos_i + 1) capsuleModel.details.structure)

                        _ ->
                            capsuleModel.details.structure

                message : String
                message =
                    "Cette opération va supprimer une planche."
                        ++ (case gosUpdatedStructure of
                                Just ( _, True ) ->
                                    " Des enregistrements seront perdus."

                                _ ->
                                    ""
                           )

                details : Api.CapsuleDetails
                details =
                    capsuleModel.details

                newDetails : Api.CapsuleDetails
                newDetails =
                    { details | structure = newStructure }

                newModel =
                    { capsuleModel | details = newDetails }
            in
            ( global
            , { capsuleModel | broken = Preparation.Broken newModel message }
            , Cmd.none
            )

        ( Preparation.UserSelectedTab t, _ ) ->
            ( global, { capsuleModel | t = t }, Cmd.none )

        ( Preparation.IncreaseNumberOfSlidesPerRow, _ ) ->
            ( { global | numberOfSlidesPerRow = global.numberOfSlidesPerRow + 1 }, capsuleModel, Cmd.none )

        ( Preparation.DecreaseNumberOfSlidesPerRow, _ ) ->
            ( { global | numberOfSlidesPerRow = global.numberOfSlidesPerRow - 1 }, capsuleModel, Cmd.none )

        ( Preparation.RejectBroken, _ ) ->
            ( global
            , { capsuleModel
                | broken = Preparation.NotBroken
                , slides = Preparation.setupSlides capsuleModel.details
                , slideModel = Preparation.slideSystem.model
                , gosModel = Preparation.gosSystem.model
              }
            , Cmd.none
            )

        ( Preparation.AcceptBroken, _ ) ->
            case capsuleModel.broken of
                Preparation.Broken m _ ->
                    ( global, m, Api.updateSlideStructure resultToMsg m.details )

                _ ->
                    ( global, capsuleModel, Cmd.none )


nextSlide : Int -> List Api.Slide -> Maybe Api.Slide
nextSlide id slides =
    case slides of
        h1 :: h2 :: t ->
            if h1.id == id then
                Just h2

            else
                nextSlide id (h2 :: t)

        _ ->
            Nothing


previousSlide : Int -> List Api.Slide -> Maybe Api.Slide
previousSlide id slides =
    case slides of
        h1 :: h2 :: t ->
            if h2.id == id then
                Just h1

            else
                previousSlide id (h2 :: t)

        _ ->
            Nothing


updateEditPromptMsg : List Api.Slide -> Preparation.EditPromptMsg -> Preparation.EditPrompt -> ( Preparation.EditPrompt, Cmd Core.Msg )
updateEditPromptMsg slides msg content =
    case msg of
        Preparation.EditPromptOpenDialog id text ->
            ( { content | visible = True, prompt = text, slideId = id }, Cmd.none )

        Preparation.EditPromptCloseDialog ->
            ( { content | visible = False }, Cmd.none )

        Preparation.EditPromptTextChanged text ->
            ( { content | prompt = text }, Cmd.none )

        Preparation.EditPromptSubmitted ->
            ( { content | status = Status.Sent }
            , Api.updateSlide resultToMsg2 content.slideId content
            )

        Preparation.EditPromptSuccess slide ->
            ( { content | visible = False, status = Status.Success () }
            , Api.capsuleFromId resultToMsg slide.capsule_id
            )

        Preparation.EditPromptError ->
            ( { content | visible = False, status = Status.Error () }
            , Cmd.none
            )

        Preparation.EditPromptNextSlide ->
            let
                nextSlideId =
                    case nextSlide content.slideId slides of
                        Just s ->
                            s.id

                        Nothing ->
                            content.slideId
            in
            ( { content | slideId = nextSlideId }, Cmd.none )

        Preparation.EditPromptPreviousSlide ->
            let
                previousSlideId =
                    case previousSlide content.slideId slides of
                        Just s ->
                            s.id

                        Nothing ->
                            content.slideId
            in
            ( { content | slideId = previousSlideId }, Cmd.none )


updateUploadSlideShow : Preparation.UploadSlideShowMsg -> Preparation.UploadForm -> Int -> ( Preparation.UploadForm, Cmd Core.Msg )
updateUploadSlideShow msg model capsuleId =
    case ( msg, model ) of
        ( Preparation.UploadSlideShowSelectFileRequested, _ ) ->
            ( model
            , Select.file
                [ "application/pdf" ]
                (\x ->
                    Core.LoggedInMsg <|
                        LoggedIn.PreparationMsg <|
                            Preparation.UploadSlideShowMsg <|
                                Preparation.UploadSlideShowFileReady x
                )
            )

        ( Preparation.UploadSlideShowFileReady file, form ) ->
            ( { form | file = Just file }
            , Cmd.none
            )

        ( Preparation.UploadSlideShowFormSubmitted, form ) ->
            case form.file of
                Nothing ->
                    ( form, Cmd.none )

                Just file ->
                    ( form, Api.capsuleUploadSlideShow resultToMsg capsuleId file )


updateUploadBackground : Preparation.UploadBackgroundMsg -> Preparation.UploadForm -> Int -> ( Preparation.UploadForm, Cmd Core.Msg )
updateUploadBackground msg model capsuleId =
    case ( msg, model ) of
        ( Preparation.UploadBackgroundSelectFileRequested, _ ) ->
            ( model
            , Select.file
                [ "image/jpeg", "image/png" ]
                (\x ->
                    Core.LoggedInMsg <|
                        LoggedIn.PreparationMsg <|
                            Preparation.UploadBackgroundMsg <|
                                Preparation.UploadBackgroundFileReady x
                )
            )

        ( Preparation.UploadBackgroundFileReady file, form ) ->
            ( { form | file = Just file }
            , Cmd.none
            )

        ( Preparation.UploadBackgroundFormSubmitted, form ) ->
            case form.file of
                Nothing ->
                    ( form, Cmd.none )

                Just file ->
                    ( form, Api.capsuleUploadBackground resultToMsg capsuleId file )


updateUploadLogo : Preparation.UploadLogoMsg -> Preparation.UploadForm -> Int -> ( Preparation.UploadForm, Cmd Core.Msg )
updateUploadLogo msg model capsuleId =
    case ( msg, model ) of
        ( Preparation.UploadLogoSelectFileRequested, _ ) ->
            ( model
            , Select.file
                [ "image/jpeg", "image/png", "image/svg+xml" ]
                (\x ->
                    Core.LoggedInMsg <|
                        LoggedIn.PreparationMsg <|
                            Preparation.UploadLogoMsg <|
                                Preparation.UploadLogoFileReady x
                )
            )

        ( Preparation.UploadLogoFileReady file, form ) ->
            ( { form | file = Just file }
            , Cmd.none
            )

        ( Preparation.UploadLogoFormSubmitted, form ) ->
            case form.file of
                Nothing ->
                    ( form, Cmd.none )

                Just file ->
                    ( form, Api.capsuleUploadLogo resultToMsg capsuleId file )


updateReplaceSlide :
    Preparation.ReplaceSlideMsg
    -> Preparation.ReplaceSlideForm
    -> Preparation.Model
    -> ( Preparation.ReplaceSlideForm, Cmd Core.Msg, Preparation.Model )
updateReplaceSlide msg replaceSlideForm preparationModel =
    case msg of
        Preparation.ReplaceSlideShowForm gosIndex slideId ->
            ( { replaceSlideForm | hide = False, activeGosIndex = Just gosIndex, ractiveSlideId = Just slideId }
            , Cmd.none
            , preparationModel
            )

        Preparation.ReplaceSlideSelectFileRequested ->
            ( replaceSlideForm
            , Select.file
                [ "image/*", "application/pdf" ]
                (\x ->
                    Core.LoggedInMsg <|
                        LoggedIn.PreparationMsg <|
                            Preparation.ReplaceSlideMsg <|
                                Preparation.ReplaceSlideFileReady x
                )
            , preparationModel
            )

        Preparation.ReplaceSlideFileReady file ->
            ( { replaceSlideForm | file = Just file }
            , Cmd.none
            , preparationModel
            )

        Preparation.ReplaceSlideFormSubmitted ->
            case replaceSlideForm.file of
                Nothing ->
                    ( replaceSlideForm, Cmd.none, preparationModel )

                Just file ->
                    ( { replaceSlideForm | status = Status.Sent }
                    , Api.slideReplace resultToMsg5 (Maybe.withDefault -1 replaceSlideForm.ractiveSlideId) file (Just 1)
                    , preparationModel
                    )

        Preparation.ReplaceSlideSuccess slide ->
            let
                updateSlide : Api.Slide -> Api.Slide -> Api.Slide
                updateSlide newSlide aSlide =
                    if aSlide.id == newSlide.id then
                        newSlide

                    else
                        aSlide

                newSlides =
                    List.map (updateSlide slide) preparationModel.details.slides

                newStructure =
                    List.map (\x -> { x | slides = List.map (updateSlide slide) x.slides }) preparationModel.details.structure

                details =
                    preparationModel.details
            in
            ( { replaceSlideForm | status = Status.Success () }
            , Cmd.none
            , Preparation.init { details | slides = newSlides, structure = newStructure }
            )

        Preparation.ReplaceSlideError ->
            ( { replaceSlideForm | status = Status.Error () }
            , Cmd.none
            , preparationModel
            )


updateUploadExtraResource :
    Preparation.UploadExtraResourceMsg
    -> Preparation.UploadExtraResourceForm
    -> Preparation.Model
    -> ( Preparation.UploadExtraResourceForm, Cmd Core.Msg, Preparation.Model )
updateUploadExtraResource msg uploadForm preparationModel =
    case msg of
        Preparation.UploadExtraResourceSelectFileRequested slideId gosId ->
            ( { uploadForm | activeSlideId = slideId, deleteStatus = Status.NotSent }
            , Select.file
                (case ( slideId, gosId ) of
                    ( Just _, _ ) ->
                        [ "video/*", "image/*", "application/pdf" ]

                    ( _, Just _ ) ->
                        [ "image/*", "application/pdf" ]

                    _ ->
                        [ "image/*", "application/pdf" ]
                )
                (\x ->
                    Core.LoggedInMsg <|
                        LoggedIn.PreparationMsg <|
                            Preparation.UploadExtraResourceMsg <|
                                Preparation.UploadExtraResourceFileReady x slideId gosId
                )
            , preparationModel
            )

        Preparation.UploadExtraResourceFileReady file (Just slideId) gos ->
            if File.mime file == "application/pdf" then
                ( { uploadForm | file = Just file, activeSlideId = Just slideId, targetGos = gos, askForPage = True, page = Just 1 }
                , Cmd.none
                , preparationModel
                )

            else if String.startsWith "image/" (File.mime file) then
                ( { uploadForm | file = Just file, activeSlideId = Just slideId, targetGos = gos }
                , Api.slideReplace resultToMsg3 (Maybe.withDefault -1 uploadForm.activeSlideId) file Nothing
                , preparationModel
                )

            else
                ( { uploadForm | file = Just file, activeSlideId = Just slideId, targetGos = gos }
                , Api.slideUploadExtraResource resultToMsg3 slideId file
                , preparationModel
                )

        Preparation.UploadExtraResourceFileReady file Nothing gos ->
            if File.mime file == "application/pdf" then
                ( { uploadForm | file = Just file, activeSlideId = Nothing, targetGos = gos, askForPage = True, page = Just 1 }
                , Cmd.none
                , preparationModel
                )

            else if String.startsWith "image/" (File.mime file) then
                ( { uploadForm | file = Just file, activeSlideId = Nothing }
                , Api.insertSlide resultToMsg6 preparationModel.details.capsule.id file gos Nothing
                , preparationModel
                )

            else
                ( uploadForm
                , Cmd.none
                , preparationModel
                )

        Preparation.UploadExtraResourceSuccess slide ->
            let
                updateSlide : Api.Slide -> Api.Slide -> Api.Slide
                updateSlide newSlide aSlide =
                    if aSlide.id == newSlide.id then
                        newSlide

                    else
                        aSlide

                newSlides =
                    List.map (updateSlide slide) preparationModel.details.slides

                newStructure =
                    List.map (\x -> { x | slides = List.map (updateSlide slide) x.slides }) preparationModel.details.structure

                details =
                    preparationModel.details
            in
            ( { uploadForm
                | status = Status.NotSent
                , activeSlideId = Nothing
                , targetGos = Nothing
                , page = Nothing
                , askForPage = False
                , file = Nothing
              }
            , Cmd.none
            , Preparation.init { details | slides = newSlides, structure = newStructure }
            )

        Preparation.UploadExtraResourceError ->
            ( { uploadForm | status = Status.Error () }
            , Cmd.none
            , preparationModel
            )

        Preparation.DeleteExtraResource slideId ->
            ( { uploadForm | status = Status.NotSent, file = Nothing, deleteStatus = Status.Sent }
            , Api.slideDeleteExtraResource
                resultToMsg4
                slideId
            , preparationModel
            )

        Preparation.DeleteExtraResourceSuccess slide ->
            let
                updateSlide : Api.Slide -> Api.Slide -> Api.Slide
                updateSlide newSlide aSlide =
                    if aSlide.id == newSlide.id then
                        newSlide

                    else
                        aSlide

                newSlides =
                    List.map (updateSlide slide) preparationModel.details.slides

                newStructure =
                    List.map (\x -> { x | slides = List.map (updateSlide slide) x.slides }) preparationModel.details.structure

                details =
                    preparationModel.details
            in
            ( { uploadForm | deleteStatus = Status.Success () }
            , Cmd.none
            , Preparation.init { details | slides = newSlides, structure = newStructure }
            )

        Preparation.DeleteExtraResourceError ->
            ( { uploadForm | deleteStatus = Status.Error () }
            , Cmd.none
            , preparationModel
            )

        Preparation.UploadExtraResourcePageChanged i ->
            ( { uploadForm | page = i }, Cmd.none, preparationModel )

        Preparation.UploadExtraResourceCancel ->
            ( { uploadForm
                | file = Nothing
                , page = Nothing
                , askForPage = False
                , activeSlideId = Nothing
              }
            , Cmd.none
            , preparationModel
            )

        Preparation.UploadExtraResourceValidate ->
            case ( uploadForm.file, uploadForm.page ) of
                ( Just file, page ) ->
                    ( { uploadForm | status = Status.Sent }
                    , case ( uploadForm.activeSlideId, uploadForm.targetGos ) of
                        ( Just id, _ ) ->
                            Api.slideReplace resultToMsg3 id file page

                        ( _, Just gos ) ->
                            Api.insertSlide resultToMsg6 preparationModel.details.capsule.id file (Just gos) page

                        _ ->
                            Api.insertSlide resultToMsg6 preparationModel.details.capsule.id file Nothing page
                    , preparationModel
                    )

                _ ->
                    ( uploadForm, Cmd.none, preparationModel )

        Preparation.UploadExtraResourceDetailsChanged newDetails ->
            ( { uploadForm
                | status = Status.NotSent
                , targetGos = Nothing
                , file = Nothing
                , activeSlideId = Nothing
                , page = Nothing
                , askForPage = False
              }
            , Cmd.none
            , { preparationModel | details = newDetails, slides = Preparation.setupSlides newDetails }
            )


updateDnD : Preparation.DnDMsg -> Preparation.Model -> ( Preparation.Model, Cmd Preparation.DnDMsg, Bool )
updateDnD slideMsg data =
    case slideMsg of
        Preparation.SlideMoved msg ->
            let
                pre =
                    Preparation.slideSystem.info data.slideModel

                ( slideModel, slides ) =
                    Preparation.slideSystem.update msg data.slideModel (List.concat data.slides)

                post =
                    Preparation.slideSystem.info slideModel

                updatedSlides =
                    case ( pre, post ) of
                        ( Just _, Nothing ) ->
                            List.filterMap Preparation.filterSlide slides

                        _ ->
                            data.details.slides

                ( broken, updatedStructure ) =
                    case ( pre, post ) of
                        ( Just _, Nothing ) ->
                            fixStructure data.details.structure (Preparation.extractStructure slides)

                        _ ->
                            ( False, data.details.structure )

                shouldSync =
                    case ( pre, post, data.details.structure /= updatedStructure ) of
                        ( Just _, Nothing, _ ) ->
                            True

                        _ ->
                            False

                details =
                    data.details

                updatedDetails =
                    { details | slides = updatedSlides, structure = updatedStructure }

                updatedSlidesView =
                    case ( pre, post ) of
                        ( Just _, Nothing ) ->
                            Preparation.setupSlides updatedDetails

                        _ ->
                            Preparation.regroupSlides slides
            in
            if broken then
                let
                    newData =
                        { data
                            | details = updatedDetails
                            , slideModel = slideModel
                            , slides = updatedSlidesView
                            , broken = Preparation.NotBroken
                        }
                in
                ( { data
                    | broken =
                        Preparation.Broken
                            newData
                            "Ce déplacement va détruire certains de vos enregistrements."
                  }
                , Preparation.slideSystem.commands slideModel
                , False
                )

            else
                ( { data | details = updatedDetails, slideModel = slideModel, slides = updatedSlidesView }
                , Preparation.slideSystem.commands slideModel
                , shouldSync
                )

        Preparation.GosMoved msg ->
            let
                pre =
                    Preparation.gosSystem.info data.gosModel

                ( gosModel, goss ) =
                    Preparation.gosSystem.update msg data.gosModel (Preparation.setupSlides data.details)

                post =
                    Preparation.gosSystem.info gosModel

                concat =
                    List.concat goss

                updatedSlides =
                    case ( pre, post ) of
                        ( Just _, Nothing ) ->
                            List.filterMap Preparation.filterSlide concat

                        _ ->
                            data.details.slides

                ( _, updatedStructure ) =
                    fixStructure data.details.structure (Preparation.extractStructure concat)

                shouldSync =
                    case ( pre, post, data.details.structure /= updatedStructure ) of
                        ( Just _, Nothing, _ ) ->
                            True

                        _ ->
                            False

                details =
                    data.details

                updatedDetails =
                    { details | slides = updatedSlides, structure = updatedStructure }

                updatedSlidesView =
                    case ( pre, post ) of
                        ( Just _, Nothing ) ->
                            Preparation.setupSlides updatedDetails

                        _ ->
                            Preparation.regroupSlides concat
            in
            ( { data | details = updatedDetails, gosModel = gosModel, slides = updatedSlidesView }, Preparation.gosSystem.commands gosModel, shouldSync )


fixStructure : List Api.Gos -> List Api.Gos -> ( Bool, List Api.Gos )
fixStructure old new =
    let
        -- The dict that associates the list of slides id to the gos in the previous list of gos
        oldGos : Dict.Dict (List Int) Api.Gos
        oldGos =
            Dict.fromList (List.map (\x -> ( List.map .id x.slides, x )) old)

        -- The dict that associates the list of slides id to the gos in the new
        -- list of gos, which doesn't contain any records or other stuff
        newGos : Dict.Dict (List Int) Api.Gos
        newGos =
            Dict.fromList (List.map (\x -> ( List.map .id x.slides, x )) new)

        -- Retrieves the old gos from the new gos, allownig to get the record and other stuff back
        fix : Api.Gos -> Api.Gos
        fix gos =
            case Dict.get (List.map .id gos.slides) oldGos of
                Nothing ->
                    gos

                Just x ->
                    x

        -- Retrieves the new gos from the old gos, if not found and the old gos
        -- has records and stuff, it will be lost
        isBroken : Api.Gos -> Bool
        isBroken gos =
            case ( Dict.get (List.map .id gos.slides) newGos, gos.record ) of
                -- if not found but the previous gos has a record, the record will be lost
                ( Nothing, Just _ ) ->
                    True

                -- otherwise, everything is fine
                _ ->
                    False

        broken =
            List.any isBroken old

        ret =
            List.map fix new
    in
    ( broken, ret )


resultToMsg : Result e Api.CapsuleDetails -> Core.Msg
resultToMsg result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <| LoggedIn.CapsuleReceived x
        )
        (\_ -> Core.Noop)
        result


resultToMsg2 : Result e Api.Slide -> Core.Msg
resultToMsg2 result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <|
                LoggedIn.PreparationMsg <|
                    Preparation.EditPromptMsg <|
                        Preparation.EditPromptSuccess <|
                            x
        )
        (\_ -> Core.Noop)
        result


resultToMsg3 : Result e Api.Slide -> Core.Msg
resultToMsg3 result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <|
                LoggedIn.PreparationMsg <|
                    Preparation.UploadExtraResourceMsg <|
                        Preparation.UploadExtraResourceSuccess <|
                            x
        )
        (\_ ->
            Core.LoggedInMsg <|
                LoggedIn.PreparationMsg <|
                    Preparation.UploadExtraResourceMsg <|
                        Preparation.UploadExtraResourceError
        )
        result


resultToMsg4 : Result e Api.Slide -> Core.Msg
resultToMsg4 result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <|
                LoggedIn.PreparationMsg <|
                    Preparation.UploadExtraResourceMsg <|
                        Preparation.DeleteExtraResourceSuccess <|
                            x
        )
        (\_ ->
            Core.LoggedInMsg <|
                LoggedIn.PreparationMsg <|
                    Preparation.UploadExtraResourceMsg <|
                        Preparation.DeleteExtraResourceError
        )
        result


resultToMsg5 : Result e Api.Slide -> Core.Msg
resultToMsg5 result =
    Utils.resultToMsg
        (\x ->
            Core.LoggedInMsg <|
                LoggedIn.PreparationMsg <|
                    Preparation.ReplaceSlideMsg <|
                        Preparation.ReplaceSlideSuccess <|
                            x
        )
        (\_ ->
            Core.LoggedInMsg <|
                LoggedIn.PreparationMsg <|
                    Preparation.ReplaceSlideMsg <|
                        Preparation.ReplaceSlideError
        )
        result


resultToMsg6 : Result e Api.CapsuleDetails -> Core.Msg
resultToMsg6 result =
    Utils.resultToMsg
        (\x ->
            Preparation.UploadExtraResourceDetailsChanged x
                |> Preparation.UploadExtraResourceMsg
                |> LoggedIn.PreparationMsg
                |> Core.LoggedInMsg
        )
        (\_ -> Core.Noop)
        result
