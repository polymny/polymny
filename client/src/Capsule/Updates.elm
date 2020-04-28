module Capsule.Updates exposing (..)

import Api
import Capsule.Types as Capsule
import Core.Types as Core
import File.Select as Select
import Log
import LoggedIn.Types as LoggedIn
import Status
import Utils


update : Capsule.Msg -> Capsule.Model -> ( Capsule.Model, Cmd Core.Msg )
update msg page =
    case ( msg, page ) of
        ( Capsule.UploadSlideShowMsg newUploadSlideShowMsg, model ) ->
            let
                ( newModel, newCmd ) =
                    updateUploadSlideShow newUploadSlideShowMsg model.uploadForm model.details.capsule.id
            in
            ( { model | uploadForm = newModel }, newCmd )

        ( Capsule.EditPromptMsg editPromptMsg, model ) ->
            let
                ( newModel, newCmd ) =
                    updateEditPromptMsg editPromptMsg model.editPrompt
            in
            ( { model | editPrompt = newModel }, newCmd )

        ( Capsule.DnD slideMsg, model ) ->
            let
                ( data, cmd ) =
                    updateDnD slideMsg model

                moveCmd =
                    Cmd.map (\x -> Core.LoggedInMsg (LoggedIn.CapsuleMsg (Capsule.DnD x))) cmd

                syncCmd =
                    Api.updateSlideStructure resultToMsg data.details

                cmds =
                    if Api.compareSlides data.details.slides model.details.slides then
                        moveCmd

                    else
                        Cmd.batch [ moveCmd, syncCmd ]
            in
            ( data, cmds )


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
                (\x -> Core.LoggedInMsg (LoggedIn.CapsuleMsg (Capsule.UploadSlideShowMsg (Capsule.UploadSlideShowFileReady x))))
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


updateDnD : Capsule.DnDMsg -> Capsule.Model -> ( Capsule.Model, Cmd Capsule.DnDMsg )
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
                            List.indexedMap (\i slide -> { slide | position_in_gos = i })
                                (List.filterMap Capsule.filterSlide slides)

                        _ ->
                            capsule.slides

                updatedSlidesView =
                    case ( pre, post ) of
                        ( Just _, Nothing ) ->
                            Capsule.setupSlides updatedSlides

                        _ ->
                            Capsule.regroupSlides slides

                capsule =
                    data.details

                newCapsule =
                    { capsule | slides = updatedSlides }
            in
            ( { data | details = newCapsule, slideModel = slideModel, slides = updatedSlidesView }
            , Capsule.slideSystem.commands slideModel
            )

        Capsule.GosMoved msg ->
            let
                ( gosModel, goss ) =
                    Capsule.gosSystem.update msg data.gosModel (Capsule.setupSlides data.details.slides)

                updatedGoss =
                    List.indexedMap
                        (\i gos -> List.map (\slide -> { slide | gos = i }) gos)
                        (List.map (\x -> List.filterMap Capsule.filterSlide x) goss)

                capsule =
                    data.details

                newCapsule =
                    { capsule | slides = List.concat updatedGoss }
            in
            ( { data | details = newCapsule, gosModel = gosModel }, Capsule.gosSystem.commands gosModel )


resultToMsg : Result e Api.CapsuleDetails -> Core.Msg
resultToMsg result =
    Utils.resultToMsg (\x -> Core.LoggedInMsg <| LoggedIn.CapsuleReceived x) (\_ -> Core.Noop) result


resultToMsg2 : Result e Api.Slide -> Core.Msg
resultToMsg2 result =
    Utils.resultToMsg (\x -> Core.LoggedInMsg <| LoggedIn.CapsuleMsg <| Capsule.EditPromptMsg <| Capsule.EditPromptSuccess <| x) (\_ -> Core.Noop) result
