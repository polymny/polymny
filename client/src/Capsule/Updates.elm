module Capsule.Updates exposing (update)

import Api
import Capsule.Types as Capsule
import Core.Types as Core
import Dict
import File.Select as Select
import LoggedIn.Types as LoggedIn
import Preparation.Types as Preparation
import Status
import Utils


update : Capsule.Msg -> Capsule.Model -> ( Capsule.Model, Cmd Core.Msg )
update msg capsuleModel =
    case ( msg, capsuleModel ) of
        ( Capsule.UploadSlideShowMsg newUploadSlideShowMsg, model ) ->
            let
                ( newFormModel, newCmd ) =
                    updateUploadSlideShow newUploadSlideShowMsg model.uploadForms.slideShow model.details.capsule.id

                oldUploadForms =
                    model.uploadForms

                newUploadForms =
                    { oldUploadForms | slideShow = newFormModel }
            in
            ( { model | uploadForms = newUploadForms }, newCmd )

        ( Capsule.UploadBackgroundMsg newUploadBackgroundMsg, model ) ->
            let
                ( newFormModel, newCmd ) =
                    updateUploadBackground newUploadBackgroundMsg model.uploadForms.background model.details.capsule.id

                oldUploadForms =
                    model.uploadForms

                newUploadForms =
                    { oldUploadForms | background = newFormModel }
            in
            ( { model | uploadForms = newUploadForms }, newCmd )

        ( Capsule.UploadLogoMsg newUploadLogoMsg, model ) ->
            let
                ( newFormModel, newCmd ) =
                    updateUploadLogo newUploadLogoMsg model.uploadForms.logo model.details.capsule.id

                oldUploadForms =
                    model.uploadForms

                newUploadForms =
                    { oldUploadForms | logo = newFormModel }
            in
            ( { model | uploadForms = newUploadForms }, newCmd )

        ( Capsule.EditPromptMsg editPromptMsg, model ) ->
            let
                ( newModel, newCmd ) =
                    updateEditPromptMsg editPromptMsg model.editPrompt
            in
            ( { model | editPrompt = newModel }, newCmd )

        ( Capsule.DnD slideMsg, model ) ->
            let
                ( data, cmd, shouldSync ) =
                    updateDnD slideMsg model

                moveCmd =
                    Cmd.map (\x -> Core.LoggedInMsg (LoggedIn.PreparationMsg (Preparation.CapsuleMsg (Capsule.DnD x)))) cmd

                syncCmd =
                    Api.updateSlideStructure resultToMsg data.details

                cmds =
                    if shouldSync then
                        Cmd.batch [ moveCmd, syncCmd ]

                    else
                        moveCmd
            in
            ( data, cmds )

        ( Capsule.SwitchLock i, _ ) ->
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


updateEditPromptMsg : Capsule.EditPromptMsg -> Capsule.EditPrompt -> ( Capsule.EditPrompt, Cmd Core.Msg )
updateEditPromptMsg msg content =
    case msg of
        Capsule.EditPromptOpenDialog id text ->
            ( { content | visible = True, prompt = text, slideId = id }, Cmd.none )

        Capsule.EditPromptCloseDialog ->
            ( { content | visible = False }, Cmd.none )

        Capsule.EditPromptTextChanged text ->
            ( { content | prompt = text }, Cmd.none )

        Capsule.EditPromptSubmitted ->
            ( { content | status = Status.Sent }
            , Api.updateSlide resultToMsg2 content.slideId content
            )

        Capsule.EditPromptSuccess slide ->
            ( { content | visible = False, status = Status.Success () }
            , Api.capsuleFromId resultToMsg slide.capsule_id
            )


updateUploadSlideShow : Capsule.UploadSlideShowMsg -> Capsule.UploadForm -> Int -> ( Capsule.UploadForm, Cmd Core.Msg )
updateUploadSlideShow msg model capsuleId =
    case ( msg, model ) of
        ( Capsule.UploadSlideShowSelectFileRequested, _ ) ->
            ( model
            , Select.file
                [ "application/pdf" ]
                (\x ->
                    Core.LoggedInMsg <|
                        LoggedIn.PreparationMsg <|
                            Preparation.CapsuleMsg <|
                                Capsule.UploadSlideShowMsg <|
                                    Capsule.UploadSlideShowFileReady x
                )
            )

        ( Capsule.UploadSlideShowFileReady file, form ) ->
            ( { form | file = Just file }
            , Cmd.none
            )

        ( Capsule.UploadSlideShowFormSubmitted, form ) ->
            case form.file of
                Nothing ->
                    ( form, Cmd.none )

                Just file ->
                    ( form, Api.capsuleUploadSlideShow resultToMsg capsuleId file )


updateUploadBackground : Capsule.UploadBackgroundMsg -> Capsule.UploadForm -> Int -> ( Capsule.UploadForm, Cmd Core.Msg )
updateUploadBackground msg model capsuleId =
    case ( msg, model ) of
        ( Capsule.UploadBackgroundSelectFileRequested, _ ) ->
            ( model
            , Select.file
                [ "image/jpeg", "image/png" ]
                (\x ->
                    Core.LoggedInMsg <|
                        LoggedIn.PreparationMsg <|
                            Preparation.CapsuleMsg <|
                                Capsule.UploadBackgroundMsg <|
                                    Capsule.UploadBackgroundFileReady x
                )
            )

        ( Capsule.UploadBackgroundFileReady file, form ) ->
            ( { form | file = Just file }
            , Cmd.none
            )

        ( Capsule.UploadBackgroundFormSubmitted, form ) ->
            case form.file of
                Nothing ->
                    ( form, Cmd.none )

                Just file ->
                    ( form, Api.capsuleUploadBackground resultToMsg capsuleId file )


updateUploadLogo : Capsule.UploadLogoMsg -> Capsule.UploadForm -> Int -> ( Capsule.UploadForm, Cmd Core.Msg )
updateUploadLogo msg model capsuleId =
    case ( msg, model ) of
        ( Capsule.UploadLogoSelectFileRequested, _ ) ->
            ( model
            , Select.file
                [ "image/jpeg", "image/png", "image/svg+xml" ]
                (\x ->
                    Core.LoggedInMsg <|
                        LoggedIn.PreparationMsg <|
                            Preparation.CapsuleMsg <|
                                Capsule.UploadLogoMsg <|
                                    Capsule.UploadLogoFileReady x
                )
            )

        ( Capsule.UploadLogoFileReady file, form ) ->
            ( { form | file = Just file }
            , Cmd.none
            )

        ( Capsule.UploadLogoFormSubmitted, form ) ->
            case form.file of
                Nothing ->
                    ( form, Cmd.none )

                Just file ->
                    ( form, Api.capsuleUploadLogo resultToMsg capsuleId file )


updateDnD : Capsule.DnDMsg -> Capsule.Model -> ( Capsule.Model, Cmd Capsule.DnDMsg, Bool )
updateDnD slideMsg data =
    case slideMsg of
        Capsule.SlideMoved msg ->
            let
                pre =
                    Capsule.slideSystem.info data.slideModel

                ( slideModel, slides ) =
                    Capsule.slideSystem.update msg data.slideModel (List.concat data.slides)

                post =
                    Capsule.slideSystem.info slideModel

                updatedSlides =
                    case ( pre, post ) of
                        ( Just _, Nothing ) ->
                            List.filterMap Capsule.filterSlide slides

                        _ ->
                            data.details.slides

                updatedStructure =
                    case ( pre, post ) of
                        ( Just _, Nothing ) ->
                            fixStructure data.details.structure (Capsule.extractStructure slides)

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
                            Capsule.setupSlides updatedDetails

                        _ ->
                            Capsule.regroupSlides slides
            in
            ( { data | details = updatedDetails, slideModel = slideModel, slides = updatedSlidesView }
            , Capsule.slideSystem.commands slideModel
            , shouldSync
            )

        Capsule.GosMoved msg ->
            let
                pre =
                    Capsule.gosSystem.info data.gosModel

                ( gosModel, goss ) =
                    Capsule.gosSystem.update msg data.gosModel (Capsule.setupSlides data.details)

                post =
                    Capsule.gosSystem.info gosModel

                concat =
                    List.concat goss

                updatedSlides =
                    case ( pre, post ) of
                        ( Just _, Nothing ) ->
                            List.filterMap Capsule.filterSlide concat

                        _ ->
                            data.details.slides

                updatedStructure =
                    fixStructure data.details.structure (Capsule.extractStructure concat)

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
                            Capsule.setupSlides updatedDetails

                        _ ->
                            Capsule.regroupSlides concat
            in
            ( { data | details = updatedDetails, gosModel = gosModel, slides = updatedSlidesView }, Capsule.gosSystem.commands gosModel, shouldSync )


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
                    Preparation.CapsuleMsg <|
                        Capsule.EditPromptMsg <|
                            Capsule.EditPromptSuccess <|
                                x
        )
        (\_ -> Core.Noop)
        result
