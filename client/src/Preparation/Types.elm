module Preparation.Types exposing
    ( DnDMsg(..)
    , EditPrompt
    , EditPromptMsg(..)
    , Forms
    , MaybeSlide(..)
    , Model
    , Msg(..)
    , ReplaceSlideForm
    , ReplaceSlideMsg(..)
    , Tab(..)
    , UploadBackgroundMsg(..)
    , UploadExtraResourceForm
    , UploadExtraResourceMsg(..)
    , UploadForm
    , UploadLogoMsg(..)
    , UploadModel(..)
    , UploadSlideShowMsg(..)
    , extractStructure
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
    , t : Tab
    }


type MaybeSlide
    = JustSlide Api.Slide Int
    | GosId Int


type alias UploadForm =
    { status : Status () ()
    , file : Maybe File
    }


initUploadForm : UploadForm
initUploadForm =
    UploadForm Status.NotSent Nothing


type alias UploadExtraResourceForm =
    { status : Status () ()
    , deleteStatus : Status () ()
    , file : Maybe File
    , activeSlideId : Maybe Int
    }


initUploadExtraResourceForm : UploadExtraResourceForm
initUploadExtraResourceForm =
    UploadExtraResourceForm Status.NotSent Status.NotSent Nothing Nothing


type alias ReplaceSlideForm =
    { status : Status () ()
    , file : Maybe File
    , ractiveSlideId : Maybe Int
    , activeGosIndex : Maybe Int
    , hide : Bool
    }


initReplaceSlideForm : ReplaceSlideForm
initReplaceSlideForm =
    ReplaceSlideForm Status.NotSent Nothing Nothing Nothing True


type alias Forms =
    { slideShow : UploadForm
    , background : UploadForm
    , logo : UploadForm
    , extraResource : UploadExtraResourceForm
    , replaceSlide : ReplaceSlideForm
    }


initForms : Forms
initForms =
    { slideShow = initUploadForm
    , background = initUploadForm
    , logo = initUploadForm
    , extraResource = initUploadExtraResourceForm
    , replaceSlide = initReplaceSlideForm
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


type Tab
    = First
    | Second
    | Third


type Msg
    = DnD DnDMsg
    | SwitchLock Int
    | GosDelete Int
    | SlideDelete Int Int
    | EditPromptMsg EditPromptMsg
    | UploadSlideShowMsg UploadSlideShowMsg
    | UploadBackgroundMsg UploadBackgroundMsg
    | UploadLogoMsg UploadLogoMsg
    | UploadExtraResourceMsg UploadExtraResourceMsg
    | ReplaceSlideMsg ReplaceSlideMsg
    | UserSelectedTab Tab


type DnDMsg
    = SlideMoved DnDList.Groups.Msg
    | GosMoved DnDList.Msg


type EditPromptMsg
    = EditPromptOpenDialog Int String
    | EditPromptCloseDialog
    | EditPromptTextChanged String
    | EditPromptSubmitted
    | EditPromptSuccess Api.Slide
    | EditPromptError


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


type UploadExtraResourceMsg
    = UploadExtraResourceSelectFileRequested Int
    | UploadExtraResourceFileReady File Int
    | UploadExtraResourceSuccess Api.Slide
    | UploadExtraResourceError
    | DeleteExtraResource Int
    | DeleteExtraResourceSuccess Api.Slide
    | DeleteExtraResourceError


type ReplaceSlideMsg
    = ReplaceSlideShowForm Int Int
    | ReplaceSlideSelectFileRequested
    | ReplaceSlideFileReady File
    | ReplaceSlideFormSubmitted
    | ReplaceSlideSuccess Api.Slide
    | ReplaceSlideError


type UploadModel
    = SlideShow
    | Background
    | Logo


init : Api.CapsuleDetails -> Model
init details =
    Model details (setupSlides details) initForms initEditPrompt slideSystem.model gosSystem.model First


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
        ( JustSlide _ gos1, JustSlide _ gos2 ) ->
            gos1 == gos2

        ( GosId a, GosId b ) ->
            a == b

        _ ->
            False


slideSetter : MaybeSlide -> MaybeSlide -> MaybeSlide
slideSetter slide1 slide2 =
    case ( slide1, slide2 ) of
        ( JustSlide _ gos1, JustSlide s2 _ ) ->
            JustSlide s2 gos1

        ( GosId id, JustSlide s2 _ ) ->
            JustSlide s2 id

        ( JustSlide s1 _, GosId id ) ->
            JustSlide s1 id

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

        JustSlide s _ ->
            JustSlide s id


indexedLambda : Int -> List MaybeSlide -> List MaybeSlide
indexedLambda id slide =
    List.map (updateGosId id) slide


setupSlides : Api.CapsuleDetails -> List (List MaybeSlide)
setupSlides capsule =
    let
        gos =
            List.indexedMap (\id x -> ( id, x )) (Api.detailsSortSlides capsule)

        list =
            List.intersperse [ GosId -1 ] (List.map (\( id, x ) -> GosId -1 :: List.map (\y -> JustSlide y id) x) gos)

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

        (JustSlide s gos) :: t ->
            regroupSlidesAux t (JustSlide s gos :: currentList) total

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
        JustSlide s _ ->
            Just s

        _ ->
            Nothing


isJustSlide : MaybeSlide -> Bool
isJustSlide slide =
    case slide of
        JustSlide _ _ ->
            True

        _ ->
            False


isGosId : MaybeSlide -> Bool
isGosId slide =
    not (isJustSlide slide)


isJustGosId : List MaybeSlide -> Bool
isJustGosId slides =
    case slides of
        [ GosId _ ] ->
            True

        _ ->
            False


extractStructure : List MaybeSlide -> List Api.Gos
extractStructure slides =
    List.filter (\x -> x.slides /= []) (extractStructureAux (List.reverse slides) [] Nothing)


extractStructureAux : List MaybeSlide -> List Api.Gos -> Maybe Api.Gos -> List Api.Gos
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
                        ( JustSlide s _, Nothing ) ->
                            { record = Nothing, slides = [ s ], locked = False, transitions = [], background = Nothing }

                        ( JustSlide s _, Just gos ) ->
                            let
                                newSlides =
                                    s :: gos.slides
                            in
                            { gos | slides = newSlides }

                        ( GosId _, _ ) ->
                            { record = Nothing, slides = [], locked = False, transitions = [], background = Nothing }
            in
            extractStructureAux t newCurrent (Just newGos)
