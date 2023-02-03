module Settings.Views exposing (..)

{-| This module contains the views for the settings page.
-}

import App.Types as App
import Config exposing (Config)
import Data.User as Data exposing (User)
import Element exposing (Element)
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import RemoteData
import Settings.Types as Settings
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui
import Ui.Utils as Ui
import Utils


{-| The view function for the settings page.
-}
view : Config -> User -> Settings.Model -> ( Element App.Msg, Element App.Msg )
view config user model =
    let
        ( content, popup ) =
            case model of
                Settings.Info s ->
                    info config user model s
    in
    ( Element.row [ Ui.wf, Ui.hf ]
        [ Element.el [ Ui.wfp 2 ] Element.none
        , Element.el [ Ui.wfp 1, Ui.hf ] <| tabs config user model
        , Element.el [ Ui.wfp 5, Ui.hf ] <| content
        , Element.el [ Ui.wfp 2 ] Element.none
        ]
    , popup
    )


{-| The view of the info tab.
-}
info : Config -> User -> Settings.Model -> Settings.InfoModel -> ( Element App.Msg, Element App.Msg )
info config user model m =
    let
        -- Shortcut for lang
        lang =
            config.clientState.lang

        -- Title attributes
        titleAttr =
            [ Font.size 20, Font.bold, Ui.pb 5 ]

        -- Field with the username
        username =
            Input.username
                [ Font.color Colors.greyFontDisabled
                , Element.htmlAttribute <| Html.Attributes.disabled True
                ]
                { label = Input.labelAbove titleAttr <| Element.text <| Strings.dataUserUsername lang
                , onChange = \_ -> App.Noop
                , placeholder = Nothing
                , text = user.username
                }

        -- Field with the email address
        email =
            Input.email
                [ Font.color Colors.greyFontDisabled
                , Element.htmlAttribute <| Html.Attributes.disabled True
                ]
                { label = Input.labelAbove titleAttr <| Element.text <| Strings.dataUserCurrentEmailAddress lang
                , onChange = \_ -> App.Noop
                , placeholder = Nothing
                , text = user.email
                }

        -- Helper to create the new email field
        ( newEmailValid, newEmailAttr, newEmailErrorMsg ) =
            if Utils.checkEmail m.newEmail then
                ( True, [ Ui.b 1, Border.color Colors.greyBorder ], Element.none )

            else
                ( False
                , [ Ui.b 1, Border.color Colors.red ]
                , Strings.loginIncorrectEmailAddress lang
                    ++ "."
                    |> Element.text
                    |> Element.el [ Font.color Colors.red ]
                )

        -- New email field
        newEmail =
            Element.column [ Ui.s 5 ]
                [ Input.email newEmailAttr
                    { label = Input.labelAbove titleAttr <| Element.text <| Strings.dataUserNewEmailAddress lang
                    , onChange = \x -> App.SettingsMsg <| Settings.InfoNewEmailChanged x
                    , placeholder = Nothing
                    , text = m.newEmail
                    }
                , newEmailErrorMsg
                ]

        -- Button to request the email address change
        ( newEmailButtonText, canSend ) =
            case m.data of
                RemoteData.Loading _ ->
                    ( Ui.spinningSpinner [] 20, False )

                RemoteData.Success _ ->
                    ( Element.text <| Strings.loginMailSent lang, False )

                _ ->
                    ( Element.text <| Strings.uiConfirm lang, True )

        newEmailButton =
            Utils.tern newEmailValid
                Ui.primaryGeneric
                Ui.secondaryGeneric
                [ Ui.wf ]
                { action = Utils.tern (newEmailValid && canSend) (Ui.Msg <| App.SettingsMsg <| Settings.InfoNewEmailConfirm) Ui.None
                , label = newEmailButtonText
                }

        -- Content
        content =
            Element.column [ Ui.s 30 ]
                [ username
                , email
                , Element.column [ Ui.s 10 ]
                    [ newEmail
                    , newEmailButton
                    ]
                ]
    in
    ( Element.el [ Ui.p 10 ] content
    , Element.none
    )


{-| Column to navigate in tabs.
-}
tabs : Config -> User -> Settings.Model -> Element App.Msg
tabs config user model =
    Element.el [ Ui.p 10, Ui.wf, Ui.hf ] <|
        Element.column [ Ui.wf, Ui.hf, Ui.s 10, Ui.br 1, Border.color Colors.greyBorder ]
            [ Element.text "yo" ]
