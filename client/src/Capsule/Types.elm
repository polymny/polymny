module Capsule.Types exposing
    ( DnDMsg(..)
    , EditPrompt
    , EditPromptMsg(..)
    , Forms
    , MaybeSlide(..)
    , Model
    , Msg(..)
    , UploadBackgroundMsg(..)
    , UploadForm
    , UploadLogoMsg(..)
    , UploadModel(..)
    , UploadSlideShowMsg(..)
    , filterSlide
    , gosConfig
    , gosSystem
    , init
    , isJustGosId
    , isJustSlide
    , regroupSlides
    , setupSlides
    , slideSystem
    )

import Api
import DnDList
import DnDList.Groups
import File exposing (File)
import Status exposing (Status)


type alias Model =
    { details : Api.CapsuleDetails
    , slides : List (List MaybeSlide)
    , uploadForms : Forms
    , editPrompt : EditPrompt
    , slideModel : DnDList.Groups.Model
    , gosModel : DnDList.Model
    }


type MaybeSlide
    = JustSlide Api.Slide
    | GosId Int


type alias UploadForm =
    { status : Status () ()
    , file : Maybe File
    }


type alias Forms =
    { slideShow : UploadForm
    , background : UploadForm
    , logo : UploadForm
    }


initUploadForm : UploadForm
initUploadForm =
    UploadForm Status.NotSent Nothing


initForms : Forms
initForms =
    { slideShow = initUploadForm
    , background = initUploadForm
    , logo = initUploadForm
    }


type alias EditPrompt =
    { status : Status () ()
    , visible : Bool
    , prompt : String
    , slideId : Int
    }


initEditPrompt : EditPrompt
initEditPrompt =
    EditPrompt Status.NotSent False "" 0


type Msg
    = DnD DnDMsg
    | EditPromptMsg EditPromptMsg
    | UploadSlideShowMsg UploadSlideShowMsg
    | UploadBackgroundMsg UploadBackgroundMsg
    | UploadLogoMsg UploadLogoMsg


type DnDMsg
    = SlideMoved DnDList.Groups.Msg
    | GosMoved DnDList.Msg


type EditPromptMsg
    = EditPromptOpenDialog Int String
    | EditPromptCloseDialog
    | EditPromptTextChanged String
    | EditPromptSubmitted
    | EditPromptSuccess Api.Slide


type UploadSlideShowMsg
    = UploadSlideShowSelectFileRequested
    | UploadSlideShowFileReady File
    | UploadSlideShowFormSubmitted


type UploadBackgroundMsg
    = UploadBackgroundSelectFileRequested
    | UploadBackgroundFileReady File
    | UploadBackgroundFormSubmitted


type UploadLogoMsg
    = UploadLogoSelectFileRequested
    | UploadLogoFileReady File
    | UploadLogoFormSubmitted


type UploadModel
    = SlideShow
    | Background
    | Logo


init : Api.CapsuleDetails -> Model
init details =
    Model details (setupSlides details.slides) initForms initEditPrompt slideSystem.model gosSystem.model


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
        ( JustSlide s1, JustSlide s2 ) ->
            s1.gos == s2.gos

        ( GosId a, GosId b ) ->
            a == b

        _ ->
            False


slideSetter : MaybeSlide -> MaybeSlide -> MaybeSlide
slideSetter slide1 slide2 =
    case ( slide1, slide2 ) of
        ( JustSlide s1, JustSlide s2 ) ->
            JustSlide { s2 | gos = s1.gos }

        ( GosId id, JustSlide s2 ) ->
            JustSlide { s2 | gos = id }

        ( JustSlide s1, GosId id ) ->
            JustSlide { s1 | gos = id }

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

        JustSlide s ->
            JustSlide { s | gos = id }


indexedLambda : Int -> List MaybeSlide -> List MaybeSlide
indexedLambda id slide =
    List.map (updateGosId id) slide


setupSlides : List Api.Slide -> List (List MaybeSlide)
setupSlides slides =
    let
        list =
            List.intersperse [ GosId -1 ] (List.map (\x -> GosId -1 :: List.map JustSlide x) (Api.sortSlides slides))

        extremities =
            [ GosId -1 ] :: List.reverse ([ GosId -1 ] :: List.reverse list)
    in
    List.indexedMap indexedLambda extremities


regroupSlidesAux : List MaybeSlide -> List MaybeSlide -> List (List MaybeSlide) -> List (List MaybeSlide)
regroupSlidesAux slides currentList total =
    case slides of
        [] ->
            if currentList == [] then
                total

            else
                currentList :: total

        (JustSlide s) :: t ->
            regroupSlidesAux t (JustSlide s :: currentList) total

        (GosId id) :: t ->
            if currentList == [] then
                regroupSlidesAux t [ GosId id ] total

            else
                regroupSlidesAux t [ GosId id ] (currentList :: total)


regroupSlides : List MaybeSlide -> List (List MaybeSlide)
regroupSlides slides =
    List.reverse (List.map List.reverse (regroupSlidesAux slides [] []))


filterSlide : MaybeSlide -> Maybe Api.Slide
filterSlide slide =
    case slide of
        JustSlide s ->
            Just s

        _ ->
            Nothing


isJustSlide : MaybeSlide -> Bool
isJustSlide slide =
    case slide of
        JustSlide _ ->
            True

        _ ->
            False


isJustGosId : List MaybeSlide -> Bool
isJustGosId slides =
    case slides of
        [ GosId _ ] ->
            True

        _ ->
            False
