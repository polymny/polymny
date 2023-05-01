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
import Element.Input as Input
import Lang
import Material.Icons
import RemoteData
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
                ( logo, role, switchAllowed ) =
                    case u.role of
                        Data.Owner ->
                            ( Ui.logoRed 50, Strings.dataCapsuleRoleOwner lang, False )

                        Data.Write ->
                            ( Ui.logoBlue 50, Strings.dataCapsuleRoleWrite lang, True )

                        Data.Read ->
                            ( Ui.logo 50, Strings.dataCapsuleRoleRead lang, True )

                attr =
                    [ Ui.wf
                    , Ui.p 10
                    , Border.widthEach { left = 1, right = 1, bottom = 1, top = 0 }
                    , Border.color Colors.greyBorder
                    , Ui.s 10
                    , Background.color Colors.white
                    ]
            in
            Element.row attr
                [ logo
                , Element.text u.username
                , if switchAllowed then
                    Ui.link [ Font.italic, Ui.ar ]
                        { label = role
                        , action = Ui.Msg <| App.CollaborationMsg <| Collaboration.SwitchRole u
                        }

                  else
                    Element.el [ Font.italic, Ui.ar ] <| Element.text role
                , if u.role /= Data.Owner then
                    Ui.primaryIcon []
                        { icon = Material.Icons.clear
                        , action = Ui.Msg <| App.CollaborationMsg <| Collaboration.RemoveCollaborator u
                        , tooltip = Strings.stepsCollaborationRemoveCollaborator lang
                        }

                  else
                    Element.none
                ]

        -- All collaborators
        collaborators : Element App.Msg
        collaborators =
            (collaboratorHead :: List.indexedMap collaboratorView model.capsule.collaborators)
                |> Element.column [ Ui.wf ]

        -- New collaborator form
        addCollaboratorForm : Element App.Msg
        addCollaboratorForm =
            Element.row [ Ui.s 10, Ui.wf ]
                [ Input.text [ Ui.wf ]
                    { label = Input.labelHidden <| Strings.loginUsernameOrEmail lang
                    , onChange =
                        \x ->
                            case model.newCollaboratorForm of
                                RemoteData.Loading _ ->
                                    App.Noop

                                _ ->
                                    App.CollaborationMsg <| Collaboration.NewCollaboratorChanged x
                    , placeholder = Just <| Input.placeholder [] <| Element.text <| Strings.loginUsernameOrEmail lang
                    , text = model.newCollaborator
                    }
                , Ui.primary []
                    { action = Ui.Msg <| App.CollaborationMsg <| Collaboration.NewCollaboratorFormSubmitted
                    , label = Element.text <| Strings.stepsCollaborationAddCollaborator lang
                    }
                ]

        -- Error message if collaborator addition failed
        collaboratorError : Element App.Msg
        collaboratorError =
            case model.newCollaboratorForm of
                RemoteData.Failure _ ->
                    Strings.stepsCollaborationAddCollaboratorFailed lang
                        ++ ". "
                        ++ Lang.question Strings.stepsCollaborationAddCollaboratorFailed2 lang
                        |> Ui.paragraph [ Ui.p 10, Border.color Colors.red, Ui.b 1, Background.color Colors.redLight, Font.color Colors.red ]

                _ ->
                    Element.none

        -- Main content
        content : Element App.Msg
        content =
            Element.column [ Ui.p 10, Ui.cx, Element.width (Element.fill |> Element.maximum 1000), Ui.s 10 ]
                [ collaborators
                , addCollaboratorForm
                , collaboratorError
                ]
    in
    ( content, Element.none )
