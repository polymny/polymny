module Ui.Navbar exposing (navbar, bottombar, leftColumn, addLeftColumn)

{-| This module contains the definition for the nav bar of the polymny app.

@docs navbar, bottombar, leftColumn, addLeftColumn

-}

import App.Types as App
import Config exposing (Config)
import Data.Capsule as Data exposing (Capsule)
import Data.User exposing (User)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Lang exposing (Lang)
import Route exposing (Route)
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Graphics as Ui
import Ui.Utils as Ui


{-| This function creates the navbar of the application.
-}
navbar : Maybe Config -> Maybe App.Page -> Maybe User -> Element msg
navbar config page user =
    let
        lang =
            Maybe.map .clientState config |> Maybe.map .lang |> Maybe.withDefault Lang.default

        capsule =
            Maybe.andThen App.getCapsule page
    in
    Element.row
        [ Background.color Colors.green2, Ui.wf ]
        [ Ui.navigationElement (Ui.Route Route.Home) [ Ui.pl 10, Ui.pr 30 ] Ui.logo
        , case ( capsule, page ) of
            ( Just c, Just p ) ->
                navButtons lang c p

            _ ->
                Element.none
        , Element.row [ Font.size 20, Element.alignRight, Element.spacing 10 ]
            [ Maybe.map .username user |> Maybe.map Element.text |> Maybe.withDefault Element.none
            , Ui.secondary [ Ui.pr 10 ] { action = Ui.None, label = Strings.loginLogout lang }
            ]
        ]


{-| This function creates a row with the navigation buttons of the different tabs of a capsule.
-}
navButtons : Lang -> Capsule -> App.Page -> Element msg
navButtons lang capsule page =
    let
        makeButton : Route -> (Lang -> String) -> Element msg
        makeButton route label =
            let
                attr =
                    if route == Route.fromPage page then
                        [ Background.color Colors.greyBackground ]

                    else
                        []
            in
            Ui.navigationElement (Ui.Route route) (Ui.hf :: Ui.p 12 :: Font.bold :: attr) (Element.el [ Element.centerY ] (Element.text (label lang)))
    in
    Element.row [ Ui.s 10, Ui.hf ]
        [ makeButton (Route.Preparation capsule.id) Strings.stepsPreparationPrepare
        , makeButton (Route.Acquisition capsule.id 0) Strings.stepsAcquisitionRecord
        , makeButton (Route.Custom "todo") Strings.stepsProductionProduce
        , makeButton (Route.Custom "todo") Strings.stepsPublicationPublish
        ]


{-| This function creates the bottom bar of the application.
-}
bottombar : Maybe Config -> Element msg
bottombar config =
    Element.row
        [ Background.color (Colors.grey 3)
        , Font.color Colors.greyBackground
        , Ui.wf
        , Ui.s 20
        , Ui.p 15
        , Font.size 16
        , Font.bold
        ]
        [ Ui.link
            [ Element.mouseOver [ Font.color Colors.greyBackground ] ]
            { label = "contacter@polymny.studio"
            , action = Ui.Route (Route.Custom "mailto:contacter@polymny.studio")
            }
        , Ui.link [ Ui.ar, Element.mouseOver [ Font.color Colors.greyBackground ] ]
            { label = "License GNU Affero V3"
            , action = Ui.Route (Route.Custom "https://github.com/polymny/polymny/blob/master/LICENSE")
            }
        , Ui.link [ Ui.ar, Element.mouseOver [ Font.color Colors.greyBackground ] ]
            { label = "Conditions d'utilisation"
            , action = Ui.Route (Route.Custom "https://polymny.studio/cgu/")
            }
        , Ui.link [ Ui.ar, Element.mouseOver [ Font.color Colors.greyBackground ] ]
            { label = "Source"
            , action = Ui.Route (Route.Custom "https://github.com/polymny/polymny")
            }
        , Ui.link [ Ui.ar, Element.mouseOver [ Font.color Colors.greyBackground ] ]
            { label = "Langue"
            , action = Ui.None
            }
        , config
            |> Maybe.map .serverConfig
            |> Maybe.map .version
            |> Maybe.map (\x -> Element.text ("Version " ++ x))
            |> Maybe.withDefault Element.none
        , config
            |> Maybe.map .serverConfig
            |> Maybe.andThen .commit
            |> Maybe.map (\x -> Element.text ("Commit " ++ x))
            |> Maybe.withDefault Element.none
        ]


{-| This function creates the left column of the capsule pages, which presents the grains.
-}
leftColumn : Lang -> Capsule -> Maybe Int -> Element msg
leftColumn lang capsule selectedGos =
    let
        gosView : Int -> Data.Gos -> Element msg
        gosView id gos =
            let
                inFrontLabel =
                    Strings.dataCapsuleGrain lang 1
                        ++ " "
                        ++ String.fromInt (id + 1)
                        |> Element.text
                        |> Element.el [ Ui.p 5, Ui.rbr 5, Background.color Colors.greyBorder ]

                borderColor =
                    if selectedGos == Just id then
                        Colors.green1

                    else
                        Colors.greyBorder
            in
            Element.el [ Ui.wf ]
                (Element.image
                    [ Ui.wf, Ui.b 5, Border.color borderColor, Element.inFront inFrontLabel ]
                    { src = Maybe.map (Data.slidePath capsule) (List.head gos.slides) |> Maybe.withDefault "oops"
                    , description = ""
                    }
                )
    in
    Element.column
        [ Background.color Colors.greyBackground, Ui.hf, Ui.p 10, Ui.br 1, Border.color Colors.greyBorder, Ui.s 10, Ui.wf ]
        (List.indexedMap gosView capsule.structure)


{-| Adds the left column to an already existing element.
-}
addLeftColumn : Lang -> Capsule -> Maybe Int -> ( Element msg, Element msg ) -> ( Element msg, Element msg )
addLeftColumn lang capsule selectedGos ( element, popup ) =
    ( Element.row [ Ui.hf, Ui.wf ] [ leftColumn lang capsule selectedGos, Element.el [ Ui.hf, Ui.wfp 7 ] element ], popup )
