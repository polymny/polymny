module NewCapsule.Views exposing (view)

{-| This module contains the new caspule page view.

@docs view

-}

import App.Types as App
import Config exposing (Config)
import Data.Capsule as Data
import Data.User as Data exposing (User)
import Element exposing (Element)
import Element.Border as Border
import NewCapsule.Types as NewCapsule
import Ui.Colors as Colors
import Ui.Utils as Ui
import Utils


{-| The view function for the new capsule page.
-}
view : Config -> User -> NewCapsule.Model -> Element App.Msg
view config user model =
    Element.none


{-| Local type for slide.
The first int is the index of the grain, the second is the index of the slide.
-}
type alias Slide =
    ( Int, ( Int, Data.Slide ) )


{-| Shows a slide of the capsule.
-}
slideView : Data.Capsule -> Maybe Slide -> Element App.Msg
slideView capsule slide =
    let
        slideElement =
            case slide of
                Nothing ->
                    Element.none

                Just ( _, ( i, s ) ) ->
                    Element.image [ Border.color Colors.greyBorder, Ui.b 1, Ui.wf ]
                        { description = "Slide number " ++ String.fromInt i
                        , src = Data.assetPath capsule (s.uuid ++ ".png")
                        }
    in
    Element.el [ Ui.wf ] slideElement
