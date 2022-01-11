module NewCapsule.Types exposing (..)

import Capsule exposing (Capsule)
import RemoteData exposing (WebData)


type alias Model =
    { project : String
    , name : String
    , capsule : WebData ( Capsule, List ( Int, Capsule.Slide ) )
    , showProject : Bool
    }


init : Maybe String -> String -> Model
init project name =
    { project = Maybe.withDefault "Nouveau projet" project
    , name = name
    , capsule = RemoteData.Loading
    , showProject = project |> Maybe.map (\_ -> False) |> Maybe.withDefault True
    }


changeCapsule : WebData Capsule -> Model -> Model
changeCapsule data model =
    { model | capsule = RemoteData.map (\x -> ( x, prepare x )) data }


prepare : Capsule -> List ( Int, Capsule.Slide )
prepare capsule =
    List.indexedMap Tuple.pair (List.concat (List.map .slides capsule.structure))


structureFromUi : List ( Int, Capsule.Slide ) -> List Capsule.Gos
structureFromUi input =
    input |> List.reverse |> structureFromUiAux [] |> List.map Tuple.second


structureFromUiAux : List ( Int, Capsule.Gos ) -> List ( Int, Capsule.Slide ) -> List ( Int, Capsule.Gos )
structureFromUiAux acc input =
    case ( input, acc ) of
        ( [], _ ) ->
            acc

        ( ( gosId, uuid ) :: t, [] ) ->
            structureFromUiAux [ ( gosId, gosFromSlide uuid ) ] t

        ( ( gosId, uuid ) :: t1, ( currentGosId, currentGos ) :: t2 ) ->
            if gosId == currentGosId then
                structureFromUiAux (( gosId, { currentGos | slides = uuid :: currentGos.slides } ) :: t2) t1

            else
                structureFromUiAux (( gosId, gosFromSlide uuid ) :: (( currentGosId, currentGos ) :: t2)) t1


gosFromSlide : Capsule.Slide -> Capsule.Gos
gosFromSlide slide =
    { record = Nothing
    , slides = [ slide ]
    , events = []
    , webcamSettings = Capsule.defaultWebcamSettings
    , fade = { vfadein = Nothing, vfadeout = Nothing, afadein = Nothing, afadeout = Nothing }
    }


type Msg
    = SlideClicked Int
    | Cancel
    | ProjectChanged String
    | NameChanged String
    | GoToPreparation
    | GoToAcquisition
