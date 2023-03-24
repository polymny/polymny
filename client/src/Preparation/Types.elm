module Preparation.Types exposing
    ( Model, ChangeSlideForm, ChangeSlide(..), Slide, slideSystem, gosSystem, setupSlides, init, Msg(..), ExtraMsg(..), DnDMsg(..), enumerate, PopupType(..)
    , withCapsule
    )

{-| This module contains the type for the preparation page, where user can manage a capsule.

In all the following documentation, DnD refers to Drag'n'Drop. It is necessary to have a user-friendly interface, but is
quite a pain to deal with.

@docs Model, ChangeSlideForm, ChangeSlide, Slide, slideSystem, gosSystem, setupSlides, init, Msg, ExtraMsg, DnDMsg, enumerate, PopupType

-}

import Data.Capsule as Data exposing (Capsule)
import DnDList
import DnDList.Groups
import File exposing (File)
import RemoteData
import Utils
import Home.Types exposing (Msg(..))


{-| The type for the model of the preparation page.
-}
type alias Model a =
    { capsule : a
    , slides : List Slide
    , slideModel : DnDList.Groups.Model
    , gosModel : DnDList.Model
    , capsuleUpdate : RemoteData.WebData ()
    , popupType : PopupType
    , displayPopup : Bool
    , changeSlide : RemoteData.WebData Data.Capsule
    }


{-| The type for the popup that can be displayed.
-}
type PopupType
    = NoPopup
    | DeleteSlidePopup Data.Slide
    | DeleteExtraPopup Data.Slide
    | ChangeSlidePopup ChangeSlideForm
    | EditPromptPopup Data.Slide
    | ConfirmUpdateCapsulePopup Capsule


{-| Transforms the capsule id into a real capsule.
-}
withCapsule : Capsule -> Model String -> Model Capsule
withCapsule capsule model =
    { capsule = capsule
    , slides = model.slides
    , slideModel = model.slideModel
    , gosModel = model.gosModel
    , capsuleUpdate = model.capsuleUpdate
    , changeSlide = model.changeSlide
    , popupType = model.popupType
    , displayPopup = model.displayPopup
    }


{-| The content of the form to change or add a slide.
-}
type alias ChangeSlideForm =
    { slide : ChangeSlide
    , page : String
    , file : File
    }


{-| The different possibilities for changing a slide.
-}
type ChangeSlide
    = ReplaceSlide Data.Slide
    | AddSlide Int
    | AddGos Int


{-| A helper function to initialiaze a model.
-}
init : Capsule -> Model String
init capsule =
    { capsule = capsule.id
    , slides = setupSlides capsule
    , slideModel = slideSystem.model
    , gosModel = gosSystem.model
    , capsuleUpdate = RemoteData.NotAsked
    , changeSlide = RemoteData.NotAsked
    , popupType = NoPopup
    , displayPopup = False
    }


{-| The message type of this page.
-}
type Msg
    = DnD DnDMsg
    | CapsuleUpdate Int (RemoteData.WebData ())
    | DeleteSlide Utils.Confirmation Data.Slide
    | DeleteExtra Utils.Confirmation Data.Slide
    | Extra ExtraMsg
    | EditPrompt Data.Slide
    | PromptChanged Utils.Confirmation Data.Slide
    | GoToPreviousSlide Int Data.Slide
    | GoToNextSlide Int Data.Slide
    | EscapePressed
    | EnterPressed
    | ConfirmUpdateCapsule
    | CancelUpdateCapsule


{-| The type that handles all file upload.
-}
type ExtraMsg
    = Select ChangeSlide
    | Selected ChangeSlide File (Maybe Int)
    | PageChanged String
    | PageCancel
    | ChangeSlideUpdated (RemoteData.WebData Data.Capsule)


{-| The different DnD messages that can occur.
-}
type DnDMsg
    = SlideMoved DnDList.Groups.Msg
    | GosMoved DnDList.Msg


{-| A slide with easy access to its position in the capsule structure.

  - the `gosId` is the real gos id to which the slide belongs.
  - the `totalGosId` is the id of the gos the the view.
  - the `slideId` is the real id of the slide, starting from 0 from the first slide of the first gos, and counting every
    slide.
  - the `totalSlideId` takes also into account the fact that an virtual gos contains a virtual slide.
  - the `slide` is the real slide.

-}
type alias Slide =
    { gosId : Int
    , totalGosId : Int
    , slideId : Int
    , totalSlideId : Int
    , slide : Maybe Data.Slide
    }


{-| A helper function to easily create a slide.
-}
makeSlide : Int -> Int -> Int -> Int -> Maybe Data.Slide -> Slide
makeSlide gosId totalGosId slideId totalSlideId slide =
    { gosId = gosId
    , totalGosId = totalGosId
    , slideId = slideId
    , totalSlideId = totalSlideId
    , slide = slide
    }


{-| A helper function to prepare the List Slide from the capsule.
-}
setupSlides : Data.Capsule -> List Slide
setupSlides input =
    let
        slideMapper : Int -> ( Int, Data.Slide ) -> Slide
        slideMapper gosId ( slideId, slide ) =
            makeSlide gosId -1 slideId -1 (Just slide)

        gosMapper : ( Int, List ( Int, Data.Slide ) ) -> List Slide
        gosMapper ( gosId, slides ) =
            List.map (slideMapper gosId) slides

        output : List Slide
        output =
            input.structure
                |> List.map .slides
                |> enumerate
                |> List.map gosMapper
                |> List.intersperse [ makeSlide -1 -1 -1 -1 Nothing ]
                |> (\x -> [ makeSlide -1 -1 -1 -1 Nothing ] :: x ++ [ [ makeSlide -1 -1 -1 -1 Nothing ] ])
                |> reindex
                |> List.concat
    in
    output


{-| Fixes the totalGosId and totalSlideId of the List (List Slide).
-}
reindex : List (List Slide) -> List (List Slide)
reindex input =
    let
        mapper : ( Int, List ( Int, Slide ) ) -> List Slide
        mapper ( totalGosId, a ) =
            List.map (\( i, x ) -> { x | totalGosId = totalGosId, totalSlideId = i }) a
    in
    input |> enumerate |> List.map mapper


{-| An util function to doubly enumerate elements.
-}
enumerate : List (List a) -> List ( Int, List ( Int, a ) )
enumerate input =
    enumerateAux 0 0 [] input
        |> List.map (Tuple.mapSecond List.reverse)
        |> List.reverse


{-| An auxilary function to help doubly enumerate elements.
-}
enumerateAux : Int -> Int -> List ( Int, List ( Int, a ) ) -> List (List a) -> List ( Int, List ( Int, a ) )
enumerateAux currentOuter currentInner acc input =
    case ( input, acc ) of
        ( [], _ ) ->
            acc

        ( [] :: [], _ ) ->
            acc

        ( [] :: t, _ ) ->
            enumerateAux (currentOuter + 1) currentInner (( currentOuter + 1, [] ) :: acc) t

        ( (h :: t) :: t2, [] ) ->
            enumerateAux currentOuter (currentInner + 1) [ ( currentOuter, [ ( currentInner, h ) ] ) ] (t :: t2)

        ( (h :: t) :: t2, ( hiA, [] ) :: t1 ) ->
            enumerateAux currentOuter (currentInner + 1) (( hiA, [ ( currentInner, h ) ] ) :: t1) (t :: t2)

        ( (h :: t) :: t2, ( hiA, hlAh :: hlAt ) :: t1 ) ->
            enumerateAux currentOuter (currentInner + 1) (( hiA, ( currentInner, h ) :: hlAh :: hlAt ) :: t1) (t :: t2)


{-| Compares two slides to know if they're in the same gos.
-}
slideComparator : Slide -> Slide -> Bool
slideComparator s1 s2 =
    s1.totalGosId == s2.totalGosId


{-| Changes the gos of a slide.
-}
slideSetter : Slide -> Slide -> Slide
slideSetter s1 s2 =
    { s2 | totalGosId = s1.totalGosId, gosId = s1.gosId }


{-| Configuration for DnD of slides.
-}
slideConfig : DnDList.Groups.Config Slide
slideConfig =
    { beforeUpdate = \_ _ a -> a
    , listen = DnDList.Groups.OnDrag
    , operation = DnDList.Groups.Rotate
    , groups =
        { listen = DnDList.Groups.OnDrag
        , operation = DnDList.Groups.InsertAfter
        , comparator = slideComparator
        , setter = slideSetter
        }
    }


{-| The slide system for DnD.
-}
slideSystem : DnDList.Groups.System Slide DnDMsg
slideSystem =
    DnDList.Groups.create slideConfig SlideMoved


{-| Configuration for DnD of gos.
-}
gosConfig : DnDList.Config (List Slide)
gosConfig =
    { beforeUpdate = \_ _ a -> a
    , movement = DnDList.Free
    , listen = DnDList.OnDrag
    , operation = DnDList.Rotate
    }


{-| The gos system for DnD.
-}
gosSystem : DnDList.System (List Slide) DnDMsg
gosSystem =
    DnDList.create gosConfig GosMoved
