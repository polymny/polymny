module Preparation.Types exposing (..)

import Capsule exposing (Capsule)
import DnDList
import DnDList.Groups
import File exposing (File)
import Status exposing (Status)


type Progress
    = Upload Float
    | Transcoding Float


type alias Model =
    { capsule : Capsule
    , slides : List (List MaybeSlide)
    , slideModel : DnDList.Groups.Model
    , gosModel : DnDList.Model
    , editPrompt : Maybe Capsule.Slide
    , changeSlideForm : Maybe ChangeSlideForm
    , tracker : Maybe ( String, Progress )
    }


type ChangeSlide
    = ReplaceSlide Capsule.Slide
    | AddSlide Int
    | AddGos Int


type alias ChangeSlideForm =
    { slide : ChangeSlide
    , page : String
    , file : File
    , status : Status
    }


initReplaceForm : Capsule.Slide -> Int -> File -> ChangeSlideForm
initReplaceForm slide page file =
    { slide = ReplaceSlide slide, page = String.fromInt page, file = file, status = Status.NotSent }


initAddSlideForm : Int -> Int -> File -> ChangeSlideForm
initAddSlideForm gos page file =
    { slide = AddSlide gos, page = String.fromInt page, file = file, status = Status.NotSent }


initChangeSlideForm : ChangeSlide -> Int -> File -> ChangeSlideForm
initChangeSlideForm slide page file =
    { slide = slide, page = String.fromInt page, file = file, status = Status.NotSent }


type MaybeSlide
    = Slide Int Capsule.Slide
    | GosId Int


type Msg
    = StartEditPrompt String
    | PromptChanged String
    | CancelPromptChange
    | PromptChangeSlide (Maybe Capsule.Slide)
    | RequestDeleteSlide String
    | DeleteSlide String
    | DnD DnDMsg
    | ExtraResourceSelect ChangeSlide
    | ExtraResourceSelected ChangeSlide File
    | ExtraResourceChangePage String
    | ExtraResourcePageValidate
    | ExtraResourcePageCancel
    | ExtraResourceFinished Capsule String
    | ExtraResourceFailed
    | ExtraResourceDelete Capsule.Slide
    | ExtraResourceProgress String Progress
    | ExtraResourceVideoUploadCancel


type DnDMsg
    = SlideMoved DnDList.Groups.Msg
    | GosMoved DnDList.Msg
    | ConfirmBroken Capsule
    | CancelBroken Capsule


init : Capsule -> Model
init capsule =
    { capsule = capsule
    , slides = setupSlides capsule
    , slideModel = slideSystem.model
    , gosModel = gosSystem.model
    , editPrompt = Nothing
    , changeSlideForm = Nothing
    , tracker = Nothing
    }


replaceCapsule : Model -> Capsule -> Model
replaceCapsule model capsule =
    let
        editPrompt =
            model.editPrompt
                |> Maybe.andThen (\x -> Capsule.findSlide x.uuid capsule)
                |> Maybe.andThen (\_ -> model.editPrompt)

        keepCurrentChangeSlide =
            case model.changeSlideForm of
                Just slide ->
                    case slide.slide of
                        ReplaceSlide s ->
                            Capsule.findSlide s.uuid capsule /= Nothing

                        _ ->
                            True

                _ ->
                    True

        changeSlideForm =
            if keepCurrentChangeSlide then
                model.changeSlideForm

            else
                Nothing
    in
    { capsule = capsule
    , slides = setupSlides capsule
    , slideModel = slideSystem.model
    , gosModel = gosSystem.model
    , editPrompt = editPrompt
    , changeSlideForm = changeSlideForm
    , tracker = model.tracker
    }


setupSlides : Capsule -> List (List MaybeSlide)
setupSlides capsule =
    let
        list : List (List MaybeSlide)
        list =
            capsule.structure
                |> List.indexedMap (\id x -> GosId -1 :: List.map (\y -> Slide id y) x.slides)
                |> List.intersperse [ GosId -1 ]

        extremities =
            [ GosId -1 ] :: List.reverse ([ GosId -1 ] :: List.reverse list)
    in
    List.indexedMap indexedLambda extremities


filter : MaybeSlide -> Maybe ( Int, Capsule.Slide )
filter input =
    case input of
        Slide i s ->
            Just ( i, s )

        _ ->
            Nothing


indexedLambda : Int -> List MaybeSlide -> List MaybeSlide
indexedLambda id slides =
    List.map (updateGosId id) slides



-- DnD shit


slideConfig : DnDList.Groups.Config MaybeSlide
slideConfig =
    { beforeUpdate = slideBeforeUpdate
    , listen = DnDList.Groups.OnDrag
    , operation = DnDList.Groups.Rotate
    , groups =
        { listen = DnDList.Groups.OnDrag
        , operation = DnDList.Groups.InsertAfter
        , comparator = slideComparator
        , setter = slideSetter
        }
    }


slideBeforeUpdate : Int -> Int -> List MaybeSlide -> List MaybeSlide
slideBeforeUpdate _ _ list =
    list


slideComparator : MaybeSlide -> MaybeSlide -> Bool
slideComparator slide1 slide2 =
    case ( slide1, slide2 ) of
        ( Slide gos1 _, Slide gos2 _ ) ->
            gos1 == gos2

        ( GosId a, GosId b ) ->
            a == b

        _ ->
            False


slideSetter : MaybeSlide -> MaybeSlide -> MaybeSlide
slideSetter slide1 slide2 =
    case ( slide1, slide2 ) of
        ( Slide gos1 _, Slide _ s2 ) ->
            Slide gos1 s2

        ( GosId id, Slide _ s2 ) ->
            Slide id s2

        ( Slide _ s1, GosId id ) ->
            Slide id s1

        ( GosId i1, GosId _ ) ->
            GosId i1


slideSystem : DnDList.Groups.System MaybeSlide DnDMsg
slideSystem =
    DnDList.Groups.create slideConfig SlideMoved


gosConfig : DnDList.Config (List MaybeSlide)
gosConfig =
    { beforeUpdate = \_ _ list -> list
    , movement = DnDList.Free
    , listen = DnDList.OnDrag
    , operation = DnDList.Rotate
    }


gosSystem : DnDList.System (List MaybeSlide) DnDMsg
gosSystem =
    DnDList.create gosConfig GosMoved


updateGosId : Int -> MaybeSlide -> MaybeSlide
updateGosId id slide =
    case slide of
        GosId _ ->
            GosId id

        Slide _ s ->
            Slide id s


regroupSlidesAux : Int -> List (List ( Int, Maybe MaybeSlide )) -> List ( Int, Maybe MaybeSlide ) -> List (List ( Int, Maybe MaybeSlide ))
regroupSlidesAux number current list =
    case ( list, current ) of
        ( [], _ ) ->
            current

        ( h :: t, [] ) ->
            regroupSlidesAux number [ [ h ] ] t

        ( h :: t, h2 :: t2 ) ->
            if List.length (List.filterMap (\( _, x ) -> filter (Maybe.withDefault (GosId -1) x)) h2) < number then
                regroupSlidesAux number ((h2 ++ [ h ]) :: t2) t

            else
                regroupSlidesAux number ([ h ] :: h2 :: t2) t


regroupSlides : Int -> List ( Int, MaybeSlide ) -> List (List ( Int, Maybe MaybeSlide ))
regroupSlides number list =
    case regroupSlidesAux number [] (List.map (\( a, b ) -> ( a, Just b )) list) of
        [] ->
            []

        h :: t ->
            (h ++ List.repeat (number - List.length (List.filterMap (\( _, x ) -> filter (Maybe.withDefault (GosId -1) x)) h)) ( -1, Nothing )) :: t
