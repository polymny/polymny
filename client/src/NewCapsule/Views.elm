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
import Element.Input as Input
import NewCapsule.Types as NewCapsule
import RemoteData
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Utils as Ui
import Utils


{-| The view function for the new capsule page.
-}
view : Config -> User -> NewCapsule.Model -> ( Element App.Msg, Element App.Msg )
view config _ model =
    let
        projectInput =
            Input.text []
                { label = Input.labelAbove [] (Ui.title (Strings.dataProjectProjectName config.clientState.lang))
                , text = model.projectName
                , placeholder = Nothing
                , onChange = \x -> App.NewCapsuleMsg (NewCapsule.ProjectChanged x)
                }
                |> Utils.tern model.showProject Element.none

        nameInput =
            Input.text []
                { label = Input.labelAbove [] (Ui.title (Strings.dataCapsuleCapsuleName config.clientState.lang))
                , text = model.capsuleName
                , placeholder = Nothing
                , onChange = \x -> App.NewCapsuleMsg (NewCapsule.NameChanged x)
                }

        pageContent =
            case ( model.slideUpload, model.capsuleUpdate ) of
                ( RemoteData.Loading _, _ ) ->
                    Ui.animatedEl Ui.spin [ Ui.cx ] (Ui.icon 60 Ui.spinner)

                ( _, ( _, RemoteData.Loading _ ) ) ->
                    Ui.animatedEl Ui.spin [ Ui.cx ] (Ui.icon 60 Ui.spinner)

                ( RemoteData.Success ( capsule, slides ), _ ) ->
                    slidesView capsule slides

                _ ->
                    Element.none

        bottomBar =
            case ( model.slideUpload, model.capsuleUpdate ) of
                ( RemoteData.Success _, ( _, RemoteData.NotAsked ) ) ->
                    Element.row [ Ui.wf, Element.spacing 10 ]
                        [ Ui.secondary []
                            { action = Ui.Msg <| App.NewCapsuleMsg <| NewCapsule.Cancel
                            , label = Element.text <| Strings.uiCancel config.clientState.lang
                            }
                        , Ui.secondary [ Element.alignRight ]
                            { action = Ui.Msg <| App.NewCapsuleMsg <| NewCapsule.Submit <| NewCapsule.Preparation
                            , label = Element.text <| Strings.stepsPreparationOrganizeSlides config.clientState.lang
                            }
                        , Ui.primary [ Element.alignRight ]
                            { action = Ui.Msg <| App.NewCapsuleMsg <| NewCapsule.Submit <| NewCapsule.Acquisition
                            , label = Element.text <| Strings.stepsAcquisitionStartRecording config.clientState.lang
                            }
                        ]

                _ ->
                    Element.none
    in
    ( Element.row [ Ui.wf, Ui.hf, Ui.p 10 ]
        [ Element.el [ Ui.wfp 1 ] Element.none
        , Element.column [ Ui.wfp 6, Element.spacing 10, Element.alignTop ]
            [ projectInput, nameInput, pageContent, bottomBar ]
        , Element.el [ Ui.wfp 1 ] Element.none
        ]
    , Element.none
    )


{-| Shows the slides with the delimiters.
-}
slidesView : Data.Capsule -> List NewCapsule.Slide -> Element App.Msg
slidesView capsule slides =
    makeView capsule slides
        |> Utils.regroupFixed 10
        |> List.map
            (List.indexedMap
                (\i x ->
                    case ( x, modBy 2 i == 0 ) of
                        ( Just e, _ ) ->
                            e

                        ( _, True ) ->
                            Element.el [ Ui.wf ] Element.none

                        ( _, False ) ->
                            Element.el [ Ui.p 10 ] Element.none
                )
            )
        |> List.map (Element.row [ Ui.wf ])
        |> Element.column [ Element.spacing 10, Ui.wf, Ui.hf ]


makeView : Data.Capsule -> List NewCapsule.Slide -> List (Element App.Msg)
makeView capsule input =
    makeViewAux capsule [] input |> List.reverse


makeViewAux : Data.Capsule -> List (Element App.Msg) -> List NewCapsule.Slide -> List (Element App.Msg)
makeViewAux capsule acc input =
    case input of
        h1 :: h2 :: t ->
            makeViewAux capsule (delimiterView h1 h2 :: slideView capsule h1 :: acc) (h2 :: t)

        h1 :: [] ->
            slideView capsule h1 :: acc

        [] ->
            acc


{-| Shows a slide of the capsule.
-}
slideView : Data.Capsule -> NewCapsule.Slide -> Element App.Msg
slideView capsule ( i, _, s ) =
    Element.el [ Ui.wf ]
        (Element.image [ Border.color Colors.greyBorder, Ui.b 1, Ui.wf ]
            { description = "Slide number " ++ String.fromInt i
            , src = Data.assetPath capsule (s.uuid ++ ".png")
            }
        )


{-| Show a vertical delimiter between two slides.

If the slides belong to the same grain, the delimiter will be dashed, otherwise, it will be solid.

-}
delimiterView : NewCapsule.Slide -> NewCapsule.Slide -> Element App.Msg
delimiterView ( index1, grain1, _ ) ( _, grain2, _ ) =
    let
        border =
            if grain1 == grain2 then
                Border.dashed

            else
                Border.solid
    in
    Input.button [ Ui.px 10, Ui.hf ]
        { label = Element.el [ border, Ui.cx, Ui.hf, Ui.bl 2, Border.color Colors.black ] Element.none
        , onPress = Just (App.NewCapsuleMsg (NewCapsule.DelimiterClicked (grain1 == grain2) index1))
        }
