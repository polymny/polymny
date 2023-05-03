module Preparation.Updates exposing (update, subs)

{-| This module contains the update function for the preparation page.

@docs update, subs

-}

import Api.Capsule as Api
import App.Types as App
import App.Utils as App
import Config exposing (Config)
import Data.Capsule as Data
import Data.User as Data exposing (User)
import Dict exposing (Dict)
import File
import File.Select as Select
import Keyboard
import List.Extra
import Preparation.Types as Preparation
import RemoteData
import Svg.Attributes exposing (display)
import Utils


{-| The update function of the preparation page.
-}
update : Preparation.Msg -> App.Model -> ( App.Model, Cmd App.Msg )
update msg model =
    let
        ( maybeCapsule, _ ) =
            App.capsuleAndGos model.user model.page
    in
    case ( model.page, maybeCapsule ) of
        ( App.Preparation m, Just capsule ) ->
            case msg of
                Preparation.DnD sMsg ->
                    updateDnD model.user sMsg m model.config
                        |> Tuple.mapFirst (\( x, y ) -> { model | page = App.Preparation x, config = y })

                Preparation.CapsuleUpdate id data ->
                    if model.config.clientState.lastRequest == id + 1 then
                        ( { model | page = App.Preparation { m | capsuleUpdate = data } }, Cmd.none )

                    else
                        ( model, Cmd.none )

                Preparation.DeleteSlide Utils.Request slide ->
                    ( { model
                        | page =
                            App.Preparation
                                { m
                                    | popupType = Preparation.DeleteSlidePopup slide
                                    , displayPopup = True
                                }
                      }
                    , Cmd.none
                    )

                Preparation.DeleteSlide Utils.Cancel _ ->
                    ( { model | page = App.Preparation { m | displayPopup = False } }, Cmd.none )

                Preparation.DeleteSlide Utils.Confirm slide ->
                    let
                        newCapsule =
                            Data.deleteSlide slide capsule

                        ( sync, newConfig ) =
                            ( Api.updateCapsule newCapsule
                                (\x -> App.PreparationMsg (Preparation.CapsuleUpdate model.config.clientState.lastRequest x))
                            , Config.incrementRequest model.config
                            )
                    in
                    ( { model
                        | user = Data.updateUser newCapsule model.user
                        , page = App.Preparation (Preparation.init newCapsule)
                        , config = newConfig
                      }
                    , sync
                    )

                Preparation.DeleteExtra Utils.Request slide ->
                    ( { model
                        | page =
                            App.Preparation
                                { m
                                    | popupType = Preparation.DeleteExtraPopup slide
                                    , displayPopup = True
                                }
                      }
                    , Cmd.none
                    )

                Preparation.DeleteExtra Utils.Cancel _ ->
                    ( { model | page = App.Preparation { m | displayPopup = False } }, Cmd.none )

                Preparation.DeleteExtra Utils.Confirm slide ->
                    let
                        newCapsule =
                            Data.deleteExtra slide capsule

                        ( sync, newConfig ) =
                            ( Api.updateCapsule newCapsule
                                (\x -> App.PreparationMsg (Preparation.CapsuleUpdate model.config.clientState.lastRequest x))
                            , Config.incrementRequest model.config
                            )
                    in
                    ( { model
                        | user = Data.updateUser newCapsule model.user
                        , page = App.Preparation (Preparation.init newCapsule)
                        , config = newConfig
                      }
                    , sync
                    )

                Preparation.Extra sMsg ->
                    let
                        ( newM, cmd, newConfig ) =
                            updateExtra model.user sMsg m model.config
                    in
                    ( { model | page = App.Preparation newM, config = newConfig }, cmd )

                Preparation.EditPrompt slide ->
                    ( { model
                        | page =
                            App.Preparation
                                { m
                                    | popupType = Preparation.EditPromptPopup slide
                                    , displayPopup = True
                                }
                      }
                    , Cmd.none
                    )

                Preparation.PromptChanged Utils.Request slide ->
                    ( { model
                        | page =
                            App.Preparation
                                { m
                                    | popupType = Preparation.EditPromptPopup slide
                                    , displayPopup = True
                                }
                      }
                    , Cmd.none
                    )

                Preparation.PromptChanged Utils.Cancel _ ->
                    ( { model | page = App.Preparation { m | displayPopup = False } }, Cmd.none )

                Preparation.PromptChanged Utils.Confirm slide ->
                    let
                        newCapsule =
                            Data.updateSlide { slide | prompt = fixPrompt slide.prompt } capsule

                        sync =
                            Api.updateCapsule newCapsule
                                (\x -> App.PreparationMsg (Preparation.CapsuleUpdate model.config.clientState.lastRequest x))
                    in
                    ( { model
                        | user = Data.updateUser newCapsule model.user
                        , page = App.Preparation (Preparation.init newCapsule)
                        , config = Config.incrementRequest model.config
                      }
                    , sync
                    )

                Preparation.GoToPreviousSlide currentSlideIndex currentSlide ->
                    let
                        newCapsule =
                            Data.updateSlide { currentSlide | prompt = fixPrompt currentSlide.prompt } capsule

                        sync =
                            Api.updateCapsule newCapsule
                                (\x -> App.PreparationMsg (Preparation.CapsuleUpdate model.config.clientState.lastRequest x))

                        previousSlide =
                            capsule.structure
                                |> List.concatMap .slides
                                |> List.drop (currentSlideIndex - 2)
                                |> List.head
                    in
                    ( { model
                        | config = Config.incrementRequest model.config
                        , page =
                            App.Preparation <|
                                case previousSlide of
                                    Just previousSlidee ->
                                        { m
                                            | popupType = Preparation.EditPromptPopup previousSlidee
                                            , displayPopup = True
                                        }

                                    Nothing ->
                                        { m | displayPopup = False }
                      }
                    , sync
                    )

                Preparation.GoToNextSlide currentSlideIndex currentSlide ->
                    let
                        newCapsule =
                            Data.updateSlide { currentSlide | prompt = fixPrompt currentSlide.prompt } capsule

                        sync =
                            Api.updateCapsule newCapsule
                                (\x -> App.PreparationMsg (Preparation.CapsuleUpdate model.config.clientState.lastRequest x))

                        nextSlide =
                            capsule.structure
                                |> List.concatMap .slides
                                |> List.drop currentSlideIndex
                                |> List.head
                    in
                    ( { model
                        | config = Config.incrementRequest model.config
                        , page =
                            App.Preparation <|
                                case nextSlide of
                                    Just nextSlidee ->
                                        { m
                                            | popupType = Preparation.EditPromptPopup nextSlidee
                                            , displayPopup = True
                                        }

                                    Nothing ->
                                        { m | displayPopup = False }
                      }
                    , sync
                    )

                Preparation.EscapePressed ->
                    if m.displayPopup then
                        case m.popupType of
                            Preparation.ConfirmUpdateCapsulePopup _ ->
                                update Preparation.CancelUpdateCapsule model

                            _ ->
                                ( { model | page = App.Preparation { m | displayPopup = False } }, Cmd.none )

                    else
                        ( model, Cmd.none )

                Preparation.EnterPressed ->
                    if m.displayPopup then
                        case m.popupType of
                            Preparation.NoPopup ->
                                ( model, Cmd.none )

                            Preparation.EditPromptPopup slide ->
                                ( model, Cmd.none )

                            Preparation.DeleteExtraPopup slide ->
                                update (Preparation.DeleteExtra Utils.Confirm slide) model

                            Preparation.DeleteSlidePopup slide ->
                                update (Preparation.DeleteSlide Utils.Confirm slide) model

                            Preparation.ConfirmUpdateCapsulePopup c ->
                                update Preparation.ConfirmUpdateCapsule model

                            Preparation.ChangeSlidePopup f ->
                                update
                                    (Preparation.Extra <|
                                        Preparation.Selected
                                            f.slide
                                            f.file
                                            (case String.toInt f.page of
                                                Just x ->
                                                    if x > 0 then
                                                        Just x

                                                    else
                                                        Nothing

                                                _ ->
                                                    Nothing
                                            )
                                    )
                                    model

                    else
                        ( model, Cmd.none )

                Preparation.ConfirmUpdateCapsule ->
                    if m.displayPopup then
                        case m.popupType of
                            Preparation.ConfirmUpdateCapsulePopup c ->
                                ( { model | page = App.Preparation <| Preparation.init c, config = Config.incrementRequest model.config }
                                , Api.updateCapsule c
                                    (\x -> App.PreparationMsg (Preparation.CapsuleUpdate model.config.clientState.lastRequest x))
                                )

                            _ ->
                                ( model, Cmd.none )

                    else
                        ( model, Cmd.none )

                Preparation.CancelUpdateCapsule ->
                    ( { model | page = App.Preparation <| Preparation.init capsule }, Cmd.none )

        _ ->
            ( model, Cmd.none )


{-| The update function that deals with extra resources.
-}
updateExtra : User -> Preparation.ExtraMsg -> Preparation.Model String -> Config.Config -> ( Preparation.Model String, Cmd App.Msg, Config.Config )
updateExtra user msg model config =
    let
        maybeCapsule =
            Data.getCapsuleById model.capsule user
    in
    case ( msg, maybeCapsule ) of
        ( Preparation.Select changeSlide, Just _ ) ->
            let
                mimes =
                    case changeSlide of
                        Preparation.ReplaceSlide _ ->
                            [ "image/*", "application/pdf", "video/*" ]

                        _ ->
                            [ "image/*", "application/pdf" ]

                cmd =
                    Select.file mimes (\x -> App.PreparationMsg (Preparation.Extra (Preparation.Selected changeSlide x Nothing)))
            in
            ( model, cmd, config )

        ( Preparation.Selected changeSlide file page, Just capsule ) ->
            case ( File.mime file, page ) of
                ( "application/pdf", Nothing ) ->
                    ( { model
                        | popupType = Preparation.ChangeSlidePopup { slide = changeSlide, file = file, page = "1" }
                        , displayPopup = True
                      }
                    , Cmd.none
                    , config
                    )

                _ ->
                    let
                        p =
                            Maybe.withDefault 0 page

                        mkMsg x =
                            App.PreparationMsg <| Preparation.Extra <| Preparation.ChangeSlideUpdated x

                        task : Config.TaskStatus
                        task =
                            { task =
                                case changeSlide of
                                    Preparation.AddSlide _ ->
                                        Config.AddSlide config.clientState.taskId capsule.id

                                    Preparation.AddGos _ ->
                                        Config.AddGos config.clientState.taskId capsule.id

                                    Preparation.ReplaceSlide _ ->
                                        Config.ReplaceSlide config.clientState.taskId capsule.id
                            , progress = Just 0.0
                            , finished = False
                            , aborted = False
                            , global = True
                            }

                        ( newConfig, _ ) =
                            Config.update (Config.UpdateTaskStatus task) config
                    in
                    case changeSlide of
                        Preparation.AddSlide gos ->
                            ( { model | changeSlide = RemoteData.Loading Nothing }
                            , Api.addSlide capsule gos p file config.clientState.taskId mkMsg
                            , Config.incrementTaskId newConfig
                            )

                        Preparation.AddGos gos ->
                            ( { model | changeSlide = RemoteData.Loading Nothing }
                            , Api.addGos capsule gos p file config.clientState.taskId mkMsg
                            , Config.incrementTaskId newConfig
                            )

                        Preparation.ReplaceSlide slide ->
                            ( { model | changeSlide = RemoteData.Loading Nothing }
                            , Api.replaceSlide capsule slide p file config.clientState.taskId mkMsg
                            , Config.incrementTaskId newConfig
                            )

        ( Preparation.PageChanged page, Just _ ) ->
            let
                newModel =
                    if model.displayPopup then
                        case model.popupType of
                            Preparation.ChangeSlidePopup c ->
                                { model
                                    | popupType = Preparation.ChangeSlidePopup { c | page = page }
                                    , displayPopup = True
                                }

                            _ ->
                                { model | displayPopup = False }

                    else
                        { model | displayPopup = False }
            in
            ( newModel, Cmd.none, config )

        ( Preparation.PageCancel, Just _ ) ->
            ( { model | displayPopup = False, changeSlide = RemoteData.NotAsked }, Cmd.none, config )

        ( Preparation.ChangeSlideUpdated (RemoteData.Success c), Just _ ) ->
            let
                cmd : Cmd App.Msg
                cmd =
                    Api.updateCapsule c
                        (\x -> App.PreparationMsg (Preparation.CapsuleUpdate config.clientState.lastRequest x))
            in
            ( Preparation.init c, cmd, Config.incrementRequest config )

        ( Preparation.ChangeSlideUpdated d, Just _ ) ->
            ( { model | changeSlide = d }, Cmd.none, config )

        _ ->
            ( model, Cmd.none, config )


{-| The update function for the DnD part of the page.
-}
updateDnD : User -> Preparation.DnDMsg -> Preparation.Model String -> Config -> ( ( Preparation.Model String, Config ), Cmd App.Msg )
updateDnD user msg model config =
    let
        maybeCapsule =
            Data.getCapsuleById model.capsule user
    in
    case ( msg, maybeCapsule ) of
        ( Preparation.SlideMoved sMsg, Just capsule ) ->
            let
                pre =
                    Preparation.slideSystem.info model.slideModel

                ( slideModel, slides ) =
                    Preparation.slideSystem.update sMsg model.slideModel model.slides

                post =
                    Preparation.slideSystem.info slideModel

                dropped =
                    pre /= Nothing && post == Nothing

                ( ( broken, newStructure ), newSlides ) =
                    case ( pre, post ) of
                        ( Just _, Nothing ) ->
                            let
                                extracted =
                                    extractStructure slides
                            in
                            ( fixStructure capsule.structure extracted
                            , Preparation.setupSlides { capsule | structure = extracted }
                            )

                        _ ->
                            ( ( False, capsule.structure ), slides )

                ( syncCmd, newConfig ) =
                    if dropped && capsule.structure /= newStructure && not broken then
                        ( Api.updateCapsule
                            { capsule | structure = newStructure }
                            (\x -> App.PreparationMsg (Preparation.CapsuleUpdate config.clientState.lastRequest x))
                        , Config.incrementRequest config
                        )

                    else
                        ( Cmd.none, config )

                newCapsule =
                    { capsule | structure = newStructure }
            in
            ( ( { model
                    | slideModel = slideModel
                    , popupType = Utils.tern broken (Preparation.ConfirmUpdateCapsulePopup newCapsule) model.popupType
                    , displayPopup = Utils.tern broken True model.displayPopup
                    , slides = newSlides
                }
              , newConfig
              )
            , Cmd.batch
                [ syncCmd
                , Preparation.slideSystem.commands slideModel
                    |> Cmd.map (\x -> App.PreparationMsg (Preparation.DnD x))
                ]
            )

        _ ->
            ( ( model, config ), Cmd.none )


{-| Creates a dummy capsule structure given a list of slides.
-}
extractStructure : List Preparation.Slide -> List Data.Gos
extractStructure slides =
    slides
        |> List.Extra.gatherWith (\a b -> a.totalGosId == b.totalGosId)
        |> List.map (\( a, b ) -> a :: b)
        |> List.map (List.filterMap .slide)
        |> List.filter (\x -> x /= [])
        |> List.map Data.gosFromSlides


{-| Retrieves the information in the structure from the old structure given a structure that contains only slides.

Returns the new structure as well as a boolean indicating if records have been lost.

-}
fixStructure : List Data.Gos -> List Data.Gos -> ( Bool, List Data.Gos )
fixStructure old new =
    let
        -- The dict that associates the list of slides id to the gos in the previous list of gos
        oldGos : Dict (List String) Data.Gos
        oldGos =
            Dict.fromList (List.map (\x -> ( List.map .uuid x.slides, x )) old)

        -- The dict that associates the list of slides id to the gos in the new
        -- list of gos, which doesn't contain any records or other stuff
        newGos : Dict (List String) Data.Gos
        newGos =
            Dict.fromList (List.map (\x -> ( List.map .uuid x.slides, x )) new)

        -- Retrieves the old gos from the new gos, allownig to get the record and other stuff back
        fix : Data.Gos -> Data.Gos
        fix gos =
            case Dict.get (List.map .uuid gos.slides) oldGos of
                Nothing ->
                    gos

                Just x ->
                    x

        -- Retrieves the new gos from the old gos, if not found and the old gos
        -- has records and stuff, it will be lost
        isBroken : Data.Gos -> Bool
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


{-| Fixes the empty lines and trailing spaces in a prompt string.
-}
fixPrompt : String -> String
fixPrompt input =
    input
        |> String.split "\n"
        |> List.filter (not << String.isEmpty)
        |> List.map String.trim
        |> String.join "\n"


{-| Keyboard shortcuts of the preparation page.
-}
shortcuts : Keyboard.RawKey -> App.Msg
shortcuts msg =
    case Keyboard.rawValue msg of
        "Escape" ->
            App.PreparationMsg Preparation.EscapePressed

        "Enter" ->
            App.PreparationMsg Preparation.EnterPressed

        _ ->
            App.Noop


{-| Subscriptions for the prepration view.
-}
subs : Preparation.Model String -> Sub App.Msg
subs model =
    Sub.batch
        [ Sub.batch
            [ Preparation.slideSystem.subscriptions model.slideModel
            , Preparation.gosSystem.subscriptions model.gosModel
            ]
            |> Sub.map Preparation.DnD
            |> Sub.map App.PreparationMsg
        , Keyboard.ups shortcuts
        ]
