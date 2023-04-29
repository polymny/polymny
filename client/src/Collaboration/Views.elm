module Collaboration.Views exposing (..)

{-| Views for the production page.
-}

import App.Types as App
import App.Utils as App
import Collaboration.Types as Collaboration
import Config exposing (Config)
import Data.Capsule as Data
import Data.Types as Data
import Data.User exposing (User)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Graphics as Ui
import Ui.Utils as Ui


{-| The full view of the page.
-}
view : Config -> User -> Collaboration.Model Data.Capsule -> ( Element App.Msg, Element App.Msg )
view config user model =
    let
        -- Shortcut for lang
        lang =
            config.clientState.lang

        -- Header for table
        collaboratorHead : Element App.Msg
        collaboratorHead =
            Element.el
                [ Ui.wf
                , Ui.p 10
                , Ui.b 1
                , Border.color Colors.greyBorder
                , Ui.rt 10
                ]
            <|
                Element.text <|
                    Strings.stepsCollaborationCollaborator lang <|
                        List.length model.capsule.collaborators

        -- View for a collaborator of the capsule
        collaboratorView : Int -> Data.Collaborator -> Element App.Msg
        collaboratorView id u =
            let
                ( logo, role ) =
                    case u.role of
                        Data.Owner ->
                            ( Ui.logoRed 50, Strings.dataCapsuleRoleOwner lang )

                        Data.Write ->
                            ( Ui.logoBlue 50, Strings.dataCapsuleRoleWrite lang )

                        Data.Read ->
                            ( Ui.logo 50, Strings.dataCapsuleRoleRead lang )

                attr =
                    if id == List.length model.capsule.collaborators - 1 then
                        [ Ui.wf
                        , Ui.p 10
                        , Border.widthEach { left = 1, right = 1, bottom = 1, top = 0 }
                        , Border.color Colors.greyBorder
                        , Ui.s 10
                        , Background.color Colors.white
                        ]

                    else
                        [ Ui.wf
                        , Ui.p 10
                        , Ui.bx 1
                        , Border.color Colors.greyBorder
                        , Ui.s 10
                        , Background.color Colors.white
                        ]
            in
            Element.row attr
                [ logo
                , Element.text u.username
                , Element.el [ Font.italic, Ui.ar ] <| Element.text role
                ]

        -- All collaborators
        collaborators : Element App.Msg
        collaborators =
            (collaboratorHead :: List.indexedMap collaboratorView model.capsule.collaborators)
                |> Element.column [ Ui.wf ]
    in
    ( Element.row [ Ui.wf, Ui.hf, Ui.s 10, Ui.p 10 ]
        [ Element.el [ Ui.wf ] Element.none
        , Element.el [ Ui.wf, Ui.at ] collaborators
        , Element.el [ Ui.wf ] Element.none
        ]
    , Element.none
    )
