module Publication.Views exposing (..)

{-| This module contains the view of the publication page.
-}

import App.Types as App
import Config exposing (Config)
import Data.Capsule as Data
import Data.Types as Data
import Data.User as Data exposing (User)
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Publication.Types as Publication
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Utils as Ui


{-| View of the publication page.
-}
view : Config -> User -> Publication.Model -> ( Element App.Msg, Element App.Msg )
view config user model =
    let
        lang =
            config.clientState.lang

        -- Helper to easily make titles
        title : String -> Element App.Msg
        title string =
            Element.el [ Font.size 22, Font.bold ] <| Element.text string

        -- Helper to create the HTML video element
        videoElement : String -> Element App.Msg
        videoElement path =
            Element.el [ Ui.wf, Ui.hf, Border.width 1, Border.color Colors.greyBorder ]
                (Element.html
                    (Html.video
                        [ Html.Attributes.controls True, Html.Attributes.class "wf" ]
                        [ Html.source [ Html.Attributes.src path ] [] ]
                    )
                )

        -- View of the video
        video =
            Element.column [ Ui.wf, Ui.hf, Element.spacing 10 ] <|
                case Data.videoPath model.capsule of
                    Just p ->
                        [ title <| Strings.stepsProductionCurrentProducedVideo lang
                        , Element.el [ Ui.wf ] <| videoElement p
                        ]

                    Nothing ->
                        [ Element.text <| Strings.stepsProductionVideoNotProduced lang ++ "." ]

        -- Converts the privacy name to string
        privacyString : Data.Privacy -> String
        privacyString privacy =
            case privacy of
                Data.Private ->
                    Strings.stepsPublicationPrivacyPrivate lang

                Data.Unlisted ->
                    Strings.stepsPublicationPrivacyUnlisted lang

                Data.Public ->
                    Strings.stepsPublicationPrivacyPublic lang

        -- Title for privacy settings
        privacyTitle =
            title <| Strings.stepsPublicationPrivacyPrivacySettings lang

        -- Button for privacy settings
        privacyButton =
            Ui.secondary []
                { action = Ui.Msg <| App.PublicationMsg <| Publication.TogglePrivacyPopup
                , label = privacyString model.capsule.privacy
                }

        -- Helper to create privacy buttons
        mkPrivacyButton : Data.Privacy -> Element App.Msg
        mkPrivacyButton privacy =
            (if model.capsule.privacy == privacy then
                Ui.primary

             else
                Ui.secondary
            )
                []
                { label = privacyString privacy
                , action = Ui.Msg <| App.PublicationMsg <| Publication.SetPrivacy privacy
                }

        -- Warning because private doesn't work yet
        privateWarning =
            Element.el [ Background.color Colors.redLight, Border.color Colors.red, Ui.b 1, Ui.r 10, Ui.p 10 ]
                (Element.paragraph [] [ Element.text (Strings.stepsPublicationPrivacyPrivateVideosNotAvailable lang ++ ".") ])

        -- Helper to create privacy explanations
        mkPrivacyExplanation : Data.Privacy -> Element App.Msg
        mkPrivacyExplanation privacy =
            Element.paragraph []
                [ Element.text
                    (case privacy of
                        Data.Private ->
                            Strings.stepsPublicationPrivacyExplainPrivate lang ++ "."

                        Data.Unlisted ->
                            Strings.stepsPublicationPrivacyExplainUnlisted lang ++ "."

                        Data.Public ->
                            Strings.stepsPublicationPrivacyExplainPublic lang ++ "."
                    )
                ]

        -- The privacy selection popup
        privacyPopup =
            Ui.popup 1
                (Strings.stepsPublicationPrivacyPrivacySettings lang)
                (Element.column [ Ui.hf, Ui.wf, Ui.s 50, Ui.p 10 ]
                    [ Element.column
                        [ Ui.s 10 ]
                        [ mkPrivacyButton Data.Private
                        , mkPrivacyExplanation Data.Private
                        , privateWarning
                        ]
                    , Element.column [ Ui.s 10 ]
                        [ mkPrivacyButton Data.Unlisted
                        , mkPrivacyExplanation Data.Unlisted
                        ]
                    , Element.column [ Ui.s 10 ]
                        [ mkPrivacyButton Data.Public
                        , mkPrivacyExplanation Data.Public
                        ]
                    , Ui.primary [ Ui.ab, Ui.ar ]
                        { label = Strings.uiConfirm lang
                        , action = Ui.Msg <| App.PublicationMsg <| Publication.TogglePrivacyPopup
                        }
                    ]
                )

        -- Title for publication options
        publicationTitle =
            title "Paramètres de publication"

        -- Option to enable the automatic generation of captions via prompt text
        usePromptForSubtitles =
            Input.checkbox []
                { checked = model.capsule.promptSubtitles
                , icon = Input.defaultCheckbox
                , label = Input.labelRight [] <| Element.text <| Strings.stepsPublicationPromptSubtitles lang ++ "."
                , onChange = \x -> App.PublicationMsg <| Publication.SetPromptSubtitles x
                }

        -- Publish button
        publishButton =
            Ui.primary []
                { label = Strings.stepsPublicationPublishVideo lang
                , action = Ui.Msg <| App.PublicationMsg <| Publication.PublishVideo
                }

        -- Title for additionnal information of published capsule
        publicationInformationTitle =
            title "Code d'intégration HTML"

        -- Text area showing the iframe code for the capsule
        iframeCode =
            Input.multiline []
                { label = Input.labelHidden "oops"
                , onChange = \_ -> App.Noop
                , placeholder = Nothing
                , spellcheck = False
                , text = Data.iframeHtml config model.capsule
                }

        -- Menu for publication
        menu =
            Element.column [ Ui.wf, Ui.hf, Ui.s 30 ]
                [ Element.column [ Ui.s 10 ]
                    [ privacyTitle
                    , privacyButton
                    ]
                , Element.column [ Ui.s 10 ]
                    [ publicationTitle
                    , usePromptForSubtitles
                    , publishButton
                    ]
                , Element.column [ Ui.s 10 ]
                    [ publicationInformationTitle
                    , iframeCode
                    ]
                ]
    in
    ( Element.row [ Ui.wf, Ui.hf, Ui.p 10, Ui.s 10 ]
        [ menu, video ]
    , if model.showPrivacyPopup then
        privacyPopup

      else
        Element.none
    )
