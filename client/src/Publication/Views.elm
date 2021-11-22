module Publication.Views exposing (..)

import Capsule
import Core.Types as Core
import Element exposing (Element)
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
                        , videoElement p
                        , if model.capsule.published == Capsule.Done then
                            Element.row [ Ui.wf, Ui.hf, Element.spacing 10 ]
                                [ Ui.newTabLink []
                                    { label = Element.text (Lang.watchVideo global.lang)
                                    , route = Route.Custom (global.videoRoot ++ "/" ++ model.capsule.id ++ "/")
                                    }
                                , Ui.iconButton [ Font.color Colors.navbar ]
                                    { onPress = Core.Copy (global.videoRoot ++ "/" ++ model.capsule.id ++ "/") |> Just
                                    , icon = Fa.link
                                    , text = Nothing
                                    , tooltip = Just (Lang.copyVideoUrl global.lang)
                                    }
                                ]

                          else
                            Element.none
                        , case model.capsule.published of
                            Capsule.Idle ->
                                Ui.primaryButton
                                    { onPress = Just (Core.PublicationMsg Publication.Publish)
                                    , label = Element.text (Lang.publishVideo global.lang)
                                    }

                            Capsule.Done ->
                                Ui.simpleButton
                                    { onPress = Just (Core.PublicationMsg Publication.Unpublish)
                                    , label = Element.text (Lang.unpublishVideo global.lang)
                                    }

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

                    Nothing ->
                        [ Element.text (Lang.videoNotProduced global.lang) ]

        privacyOption : Capsule.Privacy -> Html.Html Core.Msg
        privacyOption privacy =
            Html.option
                [ Html.Attributes.value (Capsule.privacyToString privacy)
                , Html.Attributes.selected (privacy == model.capsule.privacy)
                ]
                [ Html.text (Lang.privacy global.lang privacy) ]

        onPrivacyChange =
            Html.Events.onInput
                (\x ->
                    case Capsule.stringToPrivacy x of
                        Just p ->
                            Core.PublicationMsg (Publication.PrivacyChanged p)

                        _ ->
                            Core.Noop
                )

        settings =
            Element.column [ Ui.wf, Ui.hf, Element.spacing 10 ]
                [ Element.el Ui.formTitle (Element.text (Lang.videoSettings global.lang))
                , Element.el Ui.labelAttr (Element.text (Lang.privacySettings global.lang))
                , [ Capsule.Unlisted, Capsule.Public ]
                    |> List.map privacyOption
                    |> Html.select [ onPrivacyChange ]
                    |> Element.html
                    |> Element.el [ Element.paddingXY 0 2 ]
                , Input.checkbox []
                    { onChange = \x -> Core.PublicationMsg (Publication.PromptSubtitlesChanged x)
                    , icon = Input.defaultCheckbox
                    , checked = model.capsule.promptSubtitles
                    , label = Input.labelLeft Ui.labelAttr (Element.text (Lang.promptSubtitles global.lang))
                    }
                ]

        element =
            Element.row [ Element.padding 10, Element.spacing 10, Ui.wf ] [ video, settings ]
    in
    ( element, Nothing )


videoElement : String -> Element Core.Msg
videoElement path =
    Element.el [ Ui.wf, Ui.hf, Border.width 1, Border.color Colors.greyLighter ]
        (Element.html
            (Html.video
                [ Html.Attributes.controls True, Html.Attributes.class "wf" ]
                [ Html.source [ Html.Attributes.src path ] [] ]
            )
        )
