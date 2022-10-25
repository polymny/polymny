module Preparation.Updates exposing (..)

import Api
import Capsule
import Core.Types as Core
import Dict exposing (Dict)
import File
import File.Select as Select
import Lang
import Popup
import Preparation.Types as Preparation
import Status
import User


update : Preparation.Msg -> Core.Model -> ( Core.Model, Cmd Core.Msg )
update msg model =
    case model.page of
        Core.Preparation m ->
            case msg of
                Preparation.StartEditPrompt uuid ->
                    case Capsule.findSlide uuid m.capsule of
                        Just slide ->
                            ( mkModel model (Core.Preparation { m | editPrompt = Just slide }), Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Preparation.PromptChanged newContent ->
                    let
                        newPrompt =
                            case m.editPrompt of
                                Just s ->
                                    Just { s | prompt = newContent }

                                x ->
                                    x
                    in
                    ( mkModel model (Core.Preparation { m | editPrompt = newPrompt }), Cmd.none )

                Preparation.CancelPromptChange ->
                    ( mkModel model (Core.Preparation { m | editPrompt = Nothing }), Cmd.none )

                Preparation.PromptChangeSlide newSlide ->
                    let
                        newCapsule =
                            case m.editPrompt of
                                Just s ->
                                    Capsule.changeSlide { s | prompt = clearNewLines s.prompt } m.capsule

                                _ ->
                                    m.capsule

                        newUser =
                            User.changeCapsule newCapsule model.user
                    in
                    ( mkModel
                        { model | user = newUser }
                        (Core.Preparation
                            { m
                                | capsule = newCapsule
                                , editPrompt = newSlide
                                , slides = Preparation.setupSlides newCapsule
                            }
                        )
                    , Api.updateCapsule Core.Noop newCapsule
                    )

                Preparation.RequestDeleteSlide uuid ->
                    let
                        popup =
                            Popup.popup
                                (Lang.warning model.global.lang)
                                (Lang.deleteSlideConfirm model.global.lang)
                                Core.Cancel
                                (Core.PreparationMsg (Preparation.DeleteSlide uuid))
                    in
                    ( { model | popup = Just popup }, Cmd.none )

                Preparation.DeleteSlide uuid ->
                    let
                        newCapsule =
                            Capsule.deleteSlide uuid m.capsule

                        newUser =
                            User.changeCapsule newCapsule model.user
                    in
                    ( mkModel
                        { model | user = newUser, popup = Nothing }
                        (Core.Preparation { m | capsule = newCapsule, slides = Preparation.setupSlides newCapsule })
                    , Api.updateCapsule Core.Noop newCapsule
                    )

                Preparation.DnD message ->
                    updateDnD message model m

                Preparation.ExtraResourceSelect slide ->
                    ( model
                    , Select.file
                        (case slide of
                            Preparation.AddGos _ ->
                                [ "application/pdf", "image/*" ]

                            _ ->
                                [ "application/pdf", "image/*", "video/*" ]
                        )
                        (\x -> Core.PreparationMsg (Preparation.ExtraResourceSelected slide x))
                    )

                Preparation.ExtraResourceSelected slide file ->
                    let
                        mime =
                            File.mime file

                        form =
                            Preparation.initChangeSlideForm slide 1 file

                        ( mkMsg, newForm ) =
                            if String.startsWith "video/" mime then
                                ( \_ -> Core.PreparationMsg (Preparation.ExtraResourceProgress "" (Preparation.Transcoding 0))
                                , Nothing
                                )

                            else
                                ( \x -> Core.PreparationMsg (Preparation.ExtraResourceFinished x mime)
                                , Just { form | status = Status.Sent }
                                )
                    in
                    if mime == "application/pdf" then
                        ( mkModel model (Core.Preparation { m | changeSlideForm = Just form }), Cmd.none )

                    else
                        let
                            ( tracker, cmd ) =
                                case form.slide of
                                    Preparation.ReplaceSlide s ->
                                        Api.replaceSlide
                                            mkMsg
                                            Core.Noop
                                            m.capsule.id
                                            s.uuid
                                            0
                                            form.file

                                    Preparation.AddSlide gos ->
                                        Api.addSlide
                                            mkMsg
                                            Core.Noop
                                            m.capsule.id
                                            gos
                                            0
                                            form.file

                                    Preparation.AddGos gos ->
                                        Api.addGos
                                            mkMsg
                                            Core.Noop
                                            m.capsule.id
                                            gos
                                            0
                                            form.file
                        in
                        ( mkModel model
                            (Core.Preparation
                                { m
                                    | tracker = Just ( tracker, Preparation.Upload 0.0 )
                                    , changeSlideForm = newForm
                                }
                            )
                        , cmd
                        )

                Preparation.ExtraResourceFailed ->
                    let
                        form =
                            m.changeSlideForm
                                |> Maybe.map (\x -> { x | status = Status.Error })
                    in
                    ( mkModel model (Core.Preparation { m | changeSlideForm = form, tracker = Nothing }), Cmd.none )

                Preparation.ExtraResourceChangePage newPage ->
                    let
                        newForm =
                            Maybe.map (\x -> { x | page = newPage }) m.changeSlideForm
                    in
                    ( mkModel model (Core.Preparation { m | changeSlideForm = newForm }), Cmd.none )

                Preparation.ExtraResourcePageValidate ->
                    case m.changeSlideForm of
                        Just { slide, page, file } ->
                            case String.toInt page of
                                Just p ->
                                    let
                                        newForm =
                                            Maybe.map (\x -> { x | status = Status.Sent }) m.changeSlideForm

                                        mime =
                                            File.mime file

                                        ms x =
                                            Core.PreparationMsg (Preparation.ExtraResourceFinished x mime)

                                        errMsg =
                                            Core.PreparationMsg Preparation.ExtraResourceFailed

                                        ( tracker, cmd ) =
                                            case slide of
                                                Preparation.ReplaceSlide s ->
                                                    Api.replaceSlide ms errMsg m.capsule.id s.uuid p file

                                                Preparation.AddSlide s ->
                                                    Api.addSlide ms errMsg m.capsule.id s p file

                                                Preparation.AddGos s ->
                                                    Api.addGos ms errMsg m.capsule.id s p file
                                    in
                                    ( mkModel model
                                        (Core.Preparation
                                            { m
                                                | changeSlideForm = newForm
                                                , tracker = Just ( tracker, Preparation.Upload 0.0 )
                                            }
                                        )
                                    , cmd
                                    )

                                Nothing ->
                                    ( model, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                Preparation.ExtraResourcePageCancel ->
                    ( mkModel model (Core.Preparation { m | changeSlideForm = Nothing, tracker = Nothing }), Cmd.none )

                Preparation.ExtraResourceProgress tracker progress ->
                    if Maybe.map Tuple.first m.tracker == Just tracker then
                        ( mkModel model (Core.Preparation { m | tracker = Just ( tracker, progress ) }), Cmd.none )

                    else
                        ( model, Cmd.none )

                Preparation.ExtraResourceFinished newCapsule mime ->
                    if String.startsWith "video/" mime then
                        ( mkModel
                            { model | user = User.changeCapsule newCapsule model.user }
                            (Core.Preparation { m | tracker = Just ( "", Preparation.Transcoding 0.0 ) })
                        , Cmd.none
                        )

                    else
                        ( mkModel
                            { model | user = User.changeCapsule newCapsule model.user }
                            (Core.Preparation (Preparation.init newCapsule))
                        , Cmd.none
                        )

                Preparation.ExtraResourceDelete slide ->
                    let
                        newCapsule =
                            Capsule.updateSlide { slide | extra = Nothing } m.capsule
                    in
                    ( mkModel
                        { model | user = User.changeCapsule newCapsule model.user }
                        (Core.Preparation (Preparation.init newCapsule))
                    , Api.updateCapsule Core.Noop newCapsule
                    )

                Preparation.ExtraResourceVideoUploadCancel ->
                    let
                        oldCapsule =
                            m.capsule

                        newCapsule =
                            { oldCapsule | videoUploaded = Capsule.Idle }
                    in
                    ( mkModel { model | user = User.changeCapsule newCapsule model.user } (Core.Preparation { m | changeSlideForm = Nothing, tracker = Nothing }), Api.cancelVideoUpload Core.Noop m.capsule )

        _ ->
            ( model, Cmd.none )


clearNewLines : String -> String
clearNewLines input =
    input |> String.split "\n" |> List.filter (not << String.isEmpty) |> String.join "\n"


mkModel : Core.Model -> Core.Page -> Core.Model
mkModel input newPage =
    { input | page = newPage }


updateDnD : Preparation.DnDMsg -> Core.Model -> Preparation.Model -> ( Core.Model, Cmd Core.Msg )
updateDnD msg model submodel =
    case msg of
        Preparation.SlideMoved m ->
            let
                pre =
                    Preparation.slideSystem.info submodel.slideModel

                ( slideModel, slides ) =
                    Preparation.slideSystem.update m submodel.slideModel (List.concat submodel.slides)

                post =
                    Preparation.slideSystem.info slideModel

                ( broken, updatedStructure ) =
                    case ( pre, post ) of
                        ( Just _, Nothing ) ->
                            fixStructure submodel.capsule.structure (extractStructure slides)

                        _ ->
                            ( False, submodel.capsule.structure )

                popup =
                    if broken && submodel.capsule.structure /= updatedStructure then
                        Just
                            (Popup.popup (Lang.warning model.global.lang)
                                (Lang.dndWillBreak model.global.lang)
                                (Core.PreparationMsg (Preparation.DnD (Preparation.CancelBroken submodel.capsule)))
                                (Core.PreparationMsg (Preparation.DnD (Preparation.ConfirmBroken updatedCapsule)))
                            )

                    else
                        Nothing

                capsule =
                    submodel.capsule

                updatedCapsule =
                    { capsule | structure = updatedStructure }

                updatedSlidesView =
                    case ( pre, post ) of
                        ( Just _, Nothing ) ->
                            Preparation.setupSlides updatedCapsule

                        _ ->
                            regroupSlides slides

                syncCmd =
                    case ( pre, post, submodel.capsule.structure /= updatedStructure && not broken ) of
                        ( Just _, Nothing, True ) ->
                            Api.updateCapsule Core.Noop updatedCapsule

                        _ ->
                            Cmd.none
            in
            ( { model
                | page =
                    if broken then
                        Core.Preparation
                            { submodel | slideModel = slideModel, slides = updatedSlidesView }

                    else
                        Core.Preparation
                            { submodel | slideModel = slideModel, slides = updatedSlidesView, capsule = updatedCapsule }
                , user = User.changeCapsule updatedCapsule model.user
                , popup = popup
              }
            , Cmd.batch
                [ Preparation.slideSystem.commands slideModel |> Cmd.map (\x -> Core.PreparationMsg (Preparation.DnD x))
                , syncCmd
                ]
            )

        Preparation.GosMoved _ ->
            ( model, Cmd.none )

        Preparation.ConfirmBroken capsule ->
            ( mkModel { model | user = User.changeCapsule capsule model.user, popup = Nothing }
                (Core.Preparation (Preparation.init capsule))
            , Api.updateCapsule Core.Noop capsule
            )

        Preparation.CancelBroken capsule ->
            ( mkModel { model | user = User.changeCapsule capsule model.user, popup = Nothing }
                (Core.Preparation (Preparation.init capsule))
            , Cmd.none
            )



-- Utils


extractStructure : List Preparation.MaybeSlide -> List Capsule.Gos
extractStructure slides =
    List.filter (\x -> x.slides /= []) (extractStructureAux (List.reverse slides) [] Nothing)


extractStructureAux : List Preparation.MaybeSlide -> List Capsule.Gos -> Maybe Capsule.Gos -> List Capsule.Gos
extractStructureAux slides current currentGos =
    case ( slides, currentGos ) of
        ( [], Nothing ) ->
            current

        ( [], Just gos ) ->
            gos :: current

        ( h :: t, _ ) ->
            let
                newCurrent =
                    case ( isGosId h, currentGos ) of
                        ( True, Just gos ) ->
                            gos :: current

                        ( True, Nothing ) ->
                            current

                        ( False, _ ) ->
                            current

                newGos =
                    case ( h, currentGos ) of
                        ( Preparation.Slide _ s, Nothing ) ->
                            { record = Nothing
                            , slides = [ s ]
                            , events = []
                            , webcamSettings = Capsule.defaultWebcamSettings
                            , fade = { afadein = Nothing, afadeout = Nothing, vfadein = Nothing, vfadeout = Nothing }
                            }

                        ( Preparation.Slide _ s, Just gos ) ->
                            let
                                newSlides =
                                    s :: gos.slides
                            in
                            { gos | slides = newSlides }

                        ( Preparation.GosId _, _ ) ->
                            { record = Nothing
                            , slides = []
                            , events = []
                            , webcamSettings = Capsule.defaultWebcamSettings
                            , fade = { afadein = Nothing, afadeout = Nothing, vfadein = Nothing, vfadeout = Nothing }
                            }
            in
            extractStructureAux t newCurrent (Just newGos)


regroupSlidesAux : List Preparation.MaybeSlide -> List Preparation.MaybeSlide -> List (List Preparation.MaybeSlide) -> List (List Preparation.MaybeSlide)
regroupSlidesAux slides currentList total =
    case slides of
        [] ->
            if currentList == [] then
                total

            else
                currentList :: total

        (Preparation.Slide gos s) :: t ->
            regroupSlidesAux t (Preparation.Slide gos s :: currentList) total

        (Preparation.GosId id) :: t ->
            if currentList == [] then
                regroupSlidesAux t [ Preparation.GosId id ] total

            else
                regroupSlidesAux t [ Preparation.GosId id ] (currentList :: total)


regroupSlides : List Preparation.MaybeSlide -> List (List Preparation.MaybeSlide)
regroupSlides slides =
    List.reverse (List.map List.reverse (regroupSlidesAux slides [] []))


fixStructure : List Capsule.Gos -> List Capsule.Gos -> ( Bool, List Capsule.Gos )
fixStructure old new =
    let
        -- The dict that associates the list of slides id to the gos in the previous list of gos
        oldGos : Dict (List String) Capsule.Gos
        oldGos =
            Dict.fromList (List.map (\x -> ( List.map .uuid x.slides, x )) old)

        -- The dict that associates the list of slides id to the gos in the new
        -- list of gos, which doesn't contain any records or other stuff
        newGos : Dict (List String) Capsule.Gos
        newGos =
            Dict.fromList (List.map (\x -> ( List.map .uuid x.slides, x )) new)

        -- Retrieves the old gos from the new gos, allownig to get the record and other stuff back
        fix : Capsule.Gos -> Capsule.Gos
        fix gos =
            case Dict.get (List.map .uuid gos.slides) oldGos of
                Nothing ->
                    gos

                Just x ->
                    x

        -- Retrieves the new gos from the old gos, if not found and the old gos
        -- has records and stuff, it will be lost
        isBroken : Capsule.Gos -> Bool
        isBroken gos =
            case ( Dict.get (List.map .uuid gos.slides) newGos, gos.record ) of
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


isJustSlide : Preparation.MaybeSlide -> Bool
isJustSlide slide =
    case slide of
        Preparation.Slide _ _ ->
            True

        _ ->
            False


isGosId : Preparation.MaybeSlide -> Bool
isGosId slide =
    not (isJustSlide slide)
