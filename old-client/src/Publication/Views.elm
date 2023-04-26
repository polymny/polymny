module Publication.Views exposing (..)

import Capsule
import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import FontAwesome as Fa
import Html
import Html.Attributes
import Html.Events
import Lang
import Publication.Types as Publication
import Route
import Ui.Colors as Colors
import Ui.Utils as Ui
import User exposing (User)


view : Core.Global -> User -> Publication.Model -> ( Element Core.Msg, Maybe (Element Core.Msg) )
view global user model =
    let
        video =
            Element.column [ Ui.wf, Ui.hf, Element.spacing 10 ] <|
                case Capsule.videoPath model.capsule of
                    Just p ->
                        [ Element.el Ui.formTitle (Element.text (Lang.currentProducedVideo global.lang))
                        , Element.row [ Ui.wf ]
                            [ videoElement p
                            , Element.el [ Ui.wf ] Element.none
                            ]
                        ]

                    Nothing ->
                        [ Element.text (Lang.videoNotProduced global.lang) ]

        settings =
            Element.column [ Ui.wf, Ui.hf, Element.spacing 10 ]
                [ Element.row [ Ui.wf, Element.spacing 10 ]
                    [ Element.el Ui.formTitle (Element.text (Lang.privacySettings global.lang))
                    , Ui.simpleButton
                        { label = Element.text (Lang.privacy global.lang model.capsule.privacy)
                        , onPress = Just (Core.PublicationMsg Publication.TogglePrivacyPopup)
                        }
                    ]
                , Input.checkbox []
                    { onChange = \x -> Core.PublicationMsg (Publication.PromptSubtitlesChanged x)
                    , icon = Input.defaultCheckbox
                    , checked = model.capsule.promptSubtitles
                    , label = Input.labelLeft Ui.labelAttr (Element.text (Lang.promptSubtitles global.lang))
                    }
                ]

        endSettings =
            Element.row [ Ui.wf, Element.spacing 10 ]
                [ if model.capsule.published == Capsule.Done then
                    Ui.newTabLink []
                        { label = Element.text (Lang.watchVideo global.lang)
                        , route = Route.Custom (global.videoRoot ++ "/" ++ model.capsule.id ++ "/")
                        }

                  else
                    Element.none
                , case ( model.capsule.published, model.capsule.produced ) of
                    ( Capsule.Idle, Capsule.Done ) ->
                        Ui.primaryButton
                            { onPress = Just (Core.PublicationMsg Publication.Publish)
                            , label = Element.text (Lang.publishVideo global.lang)
                            }

                    ( Capsule.Idle, _ ) ->
                        Element.text (Lang.cantPublishBecauseNotProduced global.lang)

                    ( Capsule.Done, _ ) ->
                        Element.row [ Element.spacing 10 ]
                            [ Ui.iconButton [ Font.color Colors.navbar ]
                                { onPress = Core.Copy (global.videoRoot ++ "/" ++ model.capsule.id ++ "/") |> Just
                                , icon = Fa.link
                                , text = Nothing
                                , tooltip = Just (Lang.copyVideoUrl global.lang)
                                }
                            , Ui.simpleButton
                                { onPress = Just (Core.PublicationMsg Publication.Unpublish)
                                , label = Element.text (Lang.unpublishVideo global.lang)
                                }
                            ]

                    _ ->
                        Element.row [ Element.spacing 10 ]
                            [ Ui.primaryButton
                                { onPress = Nothing
                                , label =
                                    Element.row []
                                        [ Element.text (Lang.publishing global.lang)
                                        , Element.el [ Element.paddingEach { left = 10, right = 0, top = 0, bottom = 0 } ]
                                            Ui.spinner
                                        ]
                                }
                            , Ui.primaryButton
                                { onPress = Just (Core.PublicationMsg Publication.Cancel)
                                , label = Element.text (Lang.cancelPublication global.lang)
                                }
                            ]
                ]

        element =
            Element.column [ Element.padding 10, Element.spacing 10, Ui.wf ] [ video, settings, endSettings ]
    in
    ( element
    , if model.showPrivacyPopup then
        Just (privacyPopup global model)

      else
        Nothing
    )


privacyPopup : Core.Global -> Publication.Model -> Element Core.Msg
privacyPopup global model =
    let
        mkButton : Capsule.Privacy -> Element Core.Msg
        mkButton privacy =
            if model.capsule.privacy == privacy then
                Ui.primaryButton
                    { label = Element.text (Lang.privacy global.lang privacy)
                    , onPress = Just (Core.PublicationMsg (Publication.PrivacyChanged privacy))
                    }

            else
                Ui.simpleButton
                    { label = Element.text (Lang.privacy global.lang privacy)
                    , onPress = Just (Core.PublicationMsg (Publication.PrivacyChanged privacy))
                    }
    in
    Ui.customSizedPopup 1
        (Lang.privacySettings global.lang)
        (Element.column
            [ Ui.hf, Ui.wf, Element.padding 10, Element.spacing 10, Background.color Colors.whiteTer ]
            [ mkButton Capsule.Private
            , Element.paragraph Ui.labelAttr [ Element.text (Lang.explainPrivate global.lang) ]
            , Element.el
                [ Background.color Colors.warningLight
                , Border.width 1
                , Border.color Colors.warning
                , Border.rounded 10
                , Element.padding 10
                ]
                (Element.paragraph Ui.labelAttr [ Element.text (Lang.explainPrivateWarning global.lang) ])
            , mkButton Capsule.Unlisted
            , Element.paragraph Ui.labelAttr [ Element.text (Lang.explainUnlisted global.lang) ]
            , mkButton Capsule.Public
            , Element.paragraph Ui.labelAttr [ Element.text (Lang.explainPublic global.lang) ]
            , Element.el [ Element.padding 10, Element.alignBottom, Element.alignRight ]
                (Ui.primaryButton { label = Element.text (Lang.close global.lang), onPress = Just (Core.PublicationMsg Publication.TogglePrivacyPopup) })
            ]
        )


videoElement : String -> Element Core.Msg
videoElement path =
    Element.el [ Ui.wf, Ui.hf, Border.width 1, Border.color Colors.greyLighter ]
        (Element.html
            (Html.video
                [ Html.Attributes.controls True, Html.Attributes.class "wf" ]
                [ Html.source [ Html.Attributes.src path ] [] ]
            )
        )
