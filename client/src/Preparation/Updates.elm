module Preparation.Updates exposing (update)

import Api
import Core.Types as Core
import Dict
import File.Select as Select
import LoggedIn.Types as LoggedIn
import Preparation.Types as Preparation
import Status
import Utils


update : Preparation.Msg -> Core.Global -> Preparation.Model -> ( Preparation.Model, Cmd Core.Msg )
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
            ( { model | uploadForms = newUploadForms }, newCmd )

        ( Preparation.UploadBackgroundMsg newUploadBackgroundMsg, model ) ->
            let
                ( newFormModel, newCmd ) =
                    updateUploadBackground newUploadBackgroundMsg model.uploadForms.background model.details.capsule.id

                oldUploadForms =
                    model.uploadForms

                newUploadForms =
                    { oldUploadForms | background = newFormModel }
            in
            ( { model | uploadForms = newUploadForms }, newCmd )

        ( Preparation.UploadLogoMsg newUploadLogoMsg, model ) ->
            let
                ( newFormModel, newCmd ) =
                    updateUploadLogo newUploadLogoMsg model.uploadForms.logo model.details.capsule.id

                oldUploadForms =
                    model.uploadForms

                newUploadForms =
                    { oldUploadForms | logo = newFormModel }
            in
            ( { model | uploadForms = newUploadForms }, newCmd )

        ( Preparation.UploadExtraResourceMsg newUploadExtraResourceMsg, model ) ->
            let
                ( newFormModel, newCmd, newModel ) =
                    updateUploadExtraResource newUploadExtraResourceMsg model.uploadForms.extraResource model

                oldUploadForms =
                    newModel.uploadForms

                newUploadForms =
                    { oldUploadForms | extraResource = newFormModel }
            in
            ( { newModel | uploadForms = newUploadForms }, newCmd )

        ( Preparation.EditPromptMsg editPromptMsg, model ) ->
            let
                ( newModel, newCmd ) =
                    updateEditPromptMsg editPromptMsg model.editPrompt
            in
            ( { model | editPrompt = newModel }, newCmd )

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
            ( data, cmds )

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
            ( { capsuleModel | details = newDetails }, Cmd.none )


updateEditPromptMsg : Preparation.EditPromptMsg -> Preparation.EditPrompt -> ( Preparation.EditPrompt, Cmd Core.Msg )
updateEditPromptMsg msg content =
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


updateUploadExtraResource :
    Preparation.UploadExtraResourceMsg
    -> Preparation.UploadExtraResourceForm
    -> Preparation.Model
    -> ( Preparation.UploadExtraResourceForm, Cmd Core.Msg, Preparation.Model )
updateUploadExtraResource msg uploadForm preparationModel =
    case msg of
        Preparation.UploadExtraResourceSelectFileRequested slideId ->
            ( { uploadForm | activeSlideId = Just slideId, deleteStatus = Status.NotSent }
            , Select.file
                [ "video/*" ]
                (\x ->
                    Core.LoggedInMsg <|
                        LoggedIn.PreparationMsg <|
                            Preparation.UploadExtraResourceMsg <|
                                Preparation.UploadExtraResourceFileReady x slideId
                )
            , preparationModel
            )

        Preparation.UploadExtraResourceFileReady file slideId ->
            ( { uploadForm | file = Just file, activeSlideId = Just slideId }
            , Cmd.none
            , preparationModel
            )

        Preparation.UploadExtraResourceFormSubmitted slideId ->
            case uploadForm.file of
                Nothing ->
                    ( uploadForm, Cmd.none, preparationModel )

                Just file ->
                    ( { uploadForm | status = Status.Sent, activeSlideId = Just slideId }
                    , Api.slideUploadExtraResource resultToMsg3 slideId file
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
            ( { uploadForm | status = Status.Success (), activeSlideId = Just slide.id }
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

                updatedStructure =
                    case ( pre, post ) of
                        ( Just _, Nothing ) ->
                            fixStructure data.details.structure (Preparation.extractStructure slides)

                        _ ->
                            data.details.structure

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

                updatedStructure =
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


fixStructure : List Api.Gos -> List Api.Gos -> List Api.Gos
fixStructure old new =
    let
        dict =
            Dict.fromList (List.map (\x -> ( List.map .id x.slides, x )) old)

        fix : Api.Gos -> Api.Gos
        fix gos =
            case Dict.get (List.map .id gos.slides) dict of
                Nothing ->
                    gos

                Just x ->
                    x

        ret =
            List.map fix new
    in
    ret


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
