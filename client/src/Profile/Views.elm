module Profile.Views exposing (..)

{-| This module contains the views for the profile page.
-}

import App.Types as App
import Config exposing (Config)
import Data.Types as Data
import Data.User as Data exposing (User)
import Element exposing (Color, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Http
import Lang exposing (Lang)
import Material.Icons as Icons
import Material.Icons.Types exposing (Icon)
import Profile.Types as Profile
import RemoteData
import Simple.Transition as Transition
import Strings
import Ui.Colors as Colors
import Ui.Elements as Ui exposing (title)
import Ui.Graphics as Ui
import Ui.Utils as Ui
import Utils


{-| The view function for the profile page.
-}
view : Config -> User -> Profile.Model -> ( Element App.Msg, Element App.Msg )
view config user model =
    let
        lang : Lang
        lang =
            config.clientState.lang

        logo : Element App.Msg
        logo =
            case user.plan of
                Data.Admin ->
                    Ui.logoRed 100

                Data.PremiumLvl1 ->
                    Ui.logoBlue 100

                _ ->
                    Ui.logo 100

        titles : List String
        titles =
            [ Strings.uiProfile lang
            , Strings.uiProfileChangeEmail lang
            , Strings.uiProfileChangePassword lang
            , Strings.uiProfileDeleteAccount lang
            ]

        actions : List (Ui.Action App.Msg)
        actions =
            List.map (Ui.Msg << App.ProfileMsg << Profile.TabChanged)
                [ Profile.initInfo
                , Profile.initChangeEmail
                , Profile.initChangePassword
                , Profile.initDeleteAccount
                ]

        icons =
            [ Icons.person
            , Icons.mail
            , Icons.password
            , Icons.delete_forever
            ]

        -- Create the selector
        selectorColor : Color
        selectorColor =
            Colors.greyBackground

        backgroundColor : Color
        backgroundColor =
            Colors.green2

        buttonHeight : Int
        buttonHeight =
            50

        roundRadius : Int
        roundRadius =
            buttonHeight // 2

        selectorIndex : Int
        selectorIndex =
            case model of
                Profile.Info ->
                    0

                Profile.ChangeEmail _ ->
                    1

                Profile.ChangePassword _ ->
                    2

                Profile.DeleteAccount _ ->
                    3

        selectorMove : Float
        selectorMove =
            toFloat <| selectorIndex * buttonHeight - roundRadius

        selector : Element App.Msg
        selector =
            Element.column
                [ Element.htmlAttribute <| Html.Attributes.style "position" "absolute"
                , Ui.wf
                , Ui.hpx (buttonHeight + buttonHeight)
                , Element.moveDown selectorMove
                , Ui.zIndex 1
                , Element.htmlAttribute <|
                    Transition.properties [ Transition.transform 200 [ Transition.easeInOut ] ]
                ]
                [ Element.el [ Background.color selectorColor, Ui.wf ] <|
                    Element.el
                        [ Ui.hpx roundRadius
                        , Ui.rbr roundRadius
                        , Background.color backgroundColor
                        , Ui.wf
                        , Border.innerShadow
                            { offset = ( -11.0, 0.0 )
                            , size = -10.0
                            , blur = 10.0
                            , color = Colors.alpha 0.3
                            }
                        ]
                        Element.none
                , Element.el
                    [ Ui.wf
                    , Ui.hf
                    , Background.color selectorColor
                    , Ui.rl buttonHeight
                    ]
                    Element.none
                , Element.el [ Background.color selectorColor, Ui.wf ] <|
                    Element.el
                        [ Ui.hpx roundRadius
                        , Ui.rtr roundRadius
                        , Background.color backgroundColor
                        , Ui.wf
                        , Border.innerShadow
                            { offset = ( -11.0, 0.0 )
                            , size = -10.0
                            , blur = 10.0
                            , color = Colors.alpha 0.3
                            }
                        ]
                        Element.none
                ]

        side : Element App.Msg
        side =
            Element.column [ Ui.wfp 1, Ui.hf, Ui.s roundRadius ]
                [ Element.column [ Ui.wf, Ui.pt 30 ]
                    [ Element.el [ Ui.cx ] logo
                    , Element.el [ Ui.cx, Font.bold, Font.size 24 ] <| Element.text user.username
                    ]
                , Element.column [ Ui.wf ]
                    (selector
                        :: List.map3
                            (\title action icon ->
                                Ui.navigationElement action [] <|
                                    Element.row [ Ui.px 20, Ui.hpx buttonHeight, Ui.s 10, Ui.zIndex 1 ]
                                        [ Element.el [] <| Ui.icon 20 icon
                                        , Element.text title
                                        ]
                            )
                            titles
                            actions
                            icons
                    )
                , Element.el [ Ui.pr 20, Ui.wf, Ui.ab ] <|
                    Ui.secondary
                        [ Ui.wf ]
                        { action = Ui.Msg App.Logout
                        , label = Element.text <| Strings.loginLogout lang
                        }
                ]

        ( content, popup ) =
            case model of
                Profile.Info ->
                    info config user

                Profile.ChangeEmail s ->
                    changeEmail config user model s

                Profile.ChangePassword s ->
                    changePassword config user model s

                Profile.DeleteAccount s ->
                    deleteAccount config user model s

        finalContent : Element App.Msg
        finalContent =
            Element.column
                [ Ui.s 30
                , Background.color selectorColor
                , Ui.r 10
                , Ui.p 20
                , Ui.wfp 5
                , Ui.hf
                , Border.shadow
                    { offset = ( 0.0, 0.0 )
                    , size = 1
                    , blur = 10
                    , color = Colors.alpha 0.3
                    }
                ]
                [ Element.el [ Font.bold, Font.size 22 ] <|
                    Element.text <|
                        case Utils.get titles selectorIndex of
                            Just title ->
                                title

                            Nothing ->
                                ""
                , Element.el [ Ui.pl 30, Ui.wf ] content
                ]
    in
    ( Element.el [ Ui.wf, Ui.hf ] <|
        Element.row
            [ Ui.cx
            , Ui.cy
            , Ui.wpx 800
            , Ui.hpx 600
            , Ui.r 10
            , Ui.p 20
            , Background.color backgroundColor
            , Border.shadow
                { offset = ( 0.0, 0.0 )
                , size = 1
                , blur = 10
                , color = Colors.alpha 0.3
                }
            ]
            [ side
            , finalContent
            ]
    , popup
    )


{-| The info view, that displays global information on the user.
-}
info : Config -> User -> ( Element App.Msg, Element App.Msg )
info config user =
    let
        lang : Lang
        lang =
            config.clientState.lang

        storageBar : Element App.Msg
        storageBar =
            let
                barHeight : Int
                barHeight =
                    10

                storage : Float
                storage =
                    List.concatMap .capsules user.projects
                        |> List.filter (\c -> c.role == Data.Owner)
                        |> List.map .diskUsage
                        |> List.sum
                        |> toFloat
                        |> (\x -> x / toFloat user.quota / 1000)

                storageColor : Element.Attribute App.Msg
                storageColor =
                    Background.gradient
                        { angle = pi
                        , steps =
                            [ Colors.green2
                            , Colors.green2
                            , Colors.green2
                            , Colors.green2
                            , Colors.green2
                            , Colors.green2
                            , Colors.green2
                            , Colors.green2
                            , Colors.green2
                            , Colors.orange
                            , Colors.orange
                            , Colors.red
                            , Colors.red
                            ]
                        }

                bar : Element App.Msg
                bar =
                    Element.el
                        [ Ui.wf
                        , Ui.hpx 1000
                        , Element.moveUp ((1000.0 - toFloat barHeight) * storage)
                        , Ui.wf
                        , storageColor
                        ]
                        Element.none
            in
            Element.el
                [ Ui.p 3
                , Ui.wpx 300
                , Ui.hpx (barHeight + 2 * 3)
                , Ui.r 20
                , Background.color <| Colors.alpha 0.1
                , Border.shadow
                    { size = 1
                    , blur = 8
                    , color = Colors.alpha 0.1
                    , offset = ( 0, 0 )
                    }
                ]
            <|
                Element.el
                    [ Ui.wf
                    , Element.htmlAttribute <| Html.Attributes.style "overflow" "hidden"
                    , Ui.r 15
                    , Ui.hpx barHeight
                    ]
                <|
                    Element.el
                        [ Ui.wpx (round (storage * (300.0 - 2.0 * 3.0)))
                        , Ui.hpx barHeight
                        , Element.htmlAttribute <| Html.Attributes.style "overflow" "hidden"
                        , Ui.r 5
                        ]
                        bar

        storageInfo : Element App.Msg
        storageInfo =
            let
                storage : Float
                storage =
                    List.concatMap .capsules user.projects
                        |> List.filter (\c -> c.role == Data.Owner)
                        |> List.map .diskUsage
                        |> List.sum
                        |> toFloat
                        |> (\x -> x / 1000)
            in
            Element.row
                [ Ui.wf ]
                [ Element.el [ Font.bold ] <|
                    Element.text <|
                        Strings.uiStorage lang
                , Element.el [ Ui.ar ] <|
                    Element.text <|
                        String.fromFloat storage
                            ++ " "
                            ++ Strings.uiGB lang
                , Element.el [ Font.color Colors.greyFontDisabled ] <|
                    Element.text <|
                        " "
                            ++ Strings.uiOf lang
                            ++ " "
                            ++ String.fromInt user.quota
                            ++ " "
                            ++ Strings.uiGB lang
                ]
    in
    ( Element.column [ Ui.ab, Ui.s 4 ]
        [ storageInfo
        , storageBar
        ]
    , Element.none
    )


{-| The view that lets users change their email..
-}
changeEmail : Config -> User -> Profile.Model -> Profile.ChangeEmailModel -> ( Element App.Msg, Element App.Msg )
changeEmail config user _ m =
    let
        -- Shortcut for lang
        lang =
            config.clientState.lang

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
            Input.email newEmailAttr
                { label = Input.labelAbove titleAttr <| Element.text <| Strings.dataUserNewEmailAddress lang
                , onChange = \x -> App.ProfileMsg <| Profile.ChangeEmailNewEmailChanged x
                , placeholder = Nothing
                , text = m.newEmail
                }

        -- Helper info to create the button to request the email address change
        ( newEmailButtonText, outcomeInfo, canSend ) =
            case m.data of
                RemoteData.Loading _ ->
                    ( Ui.spinningSpinner [] 20
                    , Element.none
                    , False
                    )

                RemoteData.Success _ ->
                    ( Element.text <| Strings.uiConfirm lang
                    , Strings.loginMailSent lang
                        ++ "."
                        |> Ui.paragraph []
                        |> Ui.successModal [ Ui.wf ]
                    , False
                    )

                RemoteData.Failure _ ->
                    ( Element.text <| Strings.uiConfirm lang
                    , Strings.loginUnknownError lang
                        ++ "."
                        |> Ui.paragraph []
                        |> Ui.errorModal [ Ui.wf ]
                    , True
                    )

                RemoteData.NotAsked ->
                    ( Element.text <| Strings.uiConfirm lang
                    , Element.none
                    , True
                    )

        -- Button to request the email address change
        newEmailButton =
            Utils.tern (newEmailValid && canSend)
                Ui.primary
                Ui.secondary
                [ Ui.wf ]
                { action = Utils.tern (newEmailValid && canSend) (Ui.Msg <| App.ProfileMsg <| Profile.ChangeEmailConfirm) Ui.None
                , label = newEmailButtonText
                }

        -- Content
        content =
            Element.column [ Ui.wf, Ui.s 30 ]
                [ username
                , email
                , Element.column [ Ui.wf, Ui.s 10 ]
                    [ newEmail
                    , newEmailErrorMsg
                    ]
                , newEmailButton
                , outcomeInfo
                ]
    in
    ( content, Element.none )


{-| View that lets the user change their password.
-}
changePassword : Config -> User -> Profile.Model -> Profile.ChangePasswordModel -> ( Element App.Msg, Element App.Msg )
changePassword config _ _ m =
    let
        lang =
            config.clientState.lang

        -- Current password field
        currentPassword =
            Input.currentPassword []
                { onChange = \x -> App.ProfileMsg <| Profile.ChangePasswordCurrentPasswordChanged x
                , label = Input.labelAbove titleAttr <| Element.text <| Strings.loginCurrentPassword lang
                , placeholder = Nothing
                , show = False
                , text = m.currentPassword
                }

        -- New password field
        newPassword =
            Input.newPassword passwordAttr
                { onChange = \x -> App.ProfileMsg <| Profile.ChangePasswordNewPasswordChanged x
                , label = Input.labelAbove titleAttr <| Element.text <| Strings.loginNewPassword lang
                , placeholder = Nothing
                , show = False
                , text = m.newPassword
                }

        length =
            String.length m.newPassword

        strength =
            Utils.passwordStrength m.newPassword

        ( passwordAttr, passwordError, passwordAccepted ) =
            if length < 6 then
                ( [ Ui.b 1, Border.color Colors.red ]
                , Strings.loginPasswordTooShort lang
                    |> Element.text
                    |> Element.el [ Font.color Colors.red ]
                , False
                )

            else if strength < Utils.minPasswordStrength then
                ( [ Ui.b 1, Border.color Colors.red ]
                , Strings.loginInsufficientPasswordComplexity lang
                    |> Element.text
                    |> Element.el [ Font.color Colors.red ]
                , False
                )

            else if strength < Utils.minPasswordStrength + 1 then
                ( []
                , Strings.loginAcceptablePasswordComplexity lang
                    |> Element.text
                    |> Element.el [ Font.color Colors.orange ]
                , True
                )

            else
                ( []
                , Strings.loginStrongPasswordComplexity lang
                    |> Element.text
                    |> Element.el [ Font.color Colors.green2 ]
                , True
                )

        -- Password strength element
        passwordStrengthElement =
            Utils.passwordStrengthElement m.newPassword

        ( newPasswordRepeatAttr, newPasswordRepeatError, newPasswordRepeatAccepted ) =
            if m.newPassword == m.newPasswordRepeat then
                ( [ Ui.b 1, Border.color Colors.greyBorder ], Element.none, True )

            else
                ( [ Ui.b 1, Border.color Colors.red ]
                , Strings.loginPasswordsDontMatch lang
                    |> Element.text
                    |> Element.el [ Font.color Colors.red ]
                , True
                )

        -- New password repeat
        newPasswordRepeat =
            Input.newPassword newPasswordRepeatAttr
                { onChange = \x -> App.ProfileMsg <| Profile.ChangePasswordNewPasswordRepeatChanged x
                , label = Input.labelAbove titleAttr <| Element.text <| Strings.loginRepeatPassword lang
                , placeholder = Nothing
                , show = False
                , text = m.newPasswordRepeat
                }

        -- Helper info to create the button to request the password change
        ( changePasswordButtonText, outcomeMessage, canSend ) =
            case m.data of
                RemoteData.Loading _ ->
                    ( Ui.spinningSpinner [] 20
                    , Element.none
                    , False
                    )

                RemoteData.Success _ ->
                    ( Element.text <| Strings.uiConfirm lang
                    , Strings.loginPasswordChanged lang
                        ++ "."
                        |> Ui.paragraph []
                        |> Ui.successModal [ Ui.wf ]
                    , False
                    )

                RemoteData.Failure (Http.BadStatus 401) ->
                    ( Element.text <| Strings.uiConfirm lang
                    , Strings.loginWrongPassword lang
                        ++ "."
                        |> Ui.paragraph []
                        |> Ui.errorModal [ Ui.wf ]
                    , True
                    )

                RemoteData.Failure _ ->
                    ( Element.text <| Strings.uiConfirm lang
                    , Strings.loginUnknownError lang
                        ++ "."
                        |> Ui.paragraph []
                        |> Ui.errorModal [ Ui.wf ]
                    , True
                    )

                RemoteData.NotAsked ->
                    ( Element.text <| Strings.uiConfirm lang
                    , Element.none
                    , True
                    )

        -- Button to request the password change
        changePasswordButton =
            Utils.tern (canSend && passwordAccepted && newPasswordRepeatAccepted)
                Ui.primary
                Ui.secondary
                [ Ui.wf ]
                { action =
                    Utils.tern
                        (canSend && passwordAccepted && newPasswordRepeatAccepted)
                        (Ui.Msg <| App.ProfileMsg <| Profile.ChangePasswordConfirm)
                        Ui.None
                , label = changePasswordButtonText
                }

        -- Content
        content =
            Element.column [ Ui.wf, Ui.s 30 ]
                [ currentPassword
                , Element.column [ Ui.wf, Ui.s 10 ]
                    [ newPassword
                    , passwordStrengthElement
                    , passwordError
                    ]
                , Element.column [ Ui.wf, Ui.s 10 ]
                    [ newPasswordRepeat
                    , newPasswordRepeatError
                    ]
                , changePasswordButton
                , outcomeMessage
                ]
    in
    ( content, Element.none )


{-| View that lets the user delete their account.
-}
deleteAccount : Config -> User -> Profile.Model -> Profile.DeleteAccountModel -> ( Element App.Msg, Element App.Msg )
deleteAccount config _ _ m =
    let
        lang =
            config.clientState.lang

        -- Current password field
        currentPassword =
            Input.currentPassword []
                { onChange = \x -> App.ProfileMsg <| Profile.DeleteAccountPasswordChanged x
                , label = Input.labelAbove titleAttr <| Element.text <| Strings.dataUserPassword lang
                , placeholder = Nothing
                , show = False
                , text = m.password
                }

        -- Helper info to create the button to request the account deletion
        ( deleteAccountButtonText, outcomeMessage, canSend ) =
            case m.data of
                RemoteData.Loading _ ->
                    ( Ui.spinningSpinner [] 20
                    , Element.none
                    , False
                    )

                RemoteData.Success _ ->
                    ( Element.text <| Strings.loginDeleteAccount lang
                    , Strings.loginPasswordChanged lang
                        ++ "."
                        |> Ui.paragraph []
                        |> Ui.successModal [ Ui.wf ]
                    , False
                    )

                RemoteData.Failure (Http.BadStatus 401) ->
                    ( Element.text <| Strings.loginDeleteAccount lang
                    , Strings.loginWrongPassword lang
                        ++ "."
                        |> Ui.paragraph []
                        |> Ui.errorModal [ Ui.wf ]
                    , True
                    )

                RemoteData.Failure _ ->
                    ( Element.text <| Strings.loginDeleteAccount lang
                    , Strings.loginUnknownError lang
                        ++ "."
                        |> Ui.paragraph []
                        |> Ui.errorModal [ Ui.wf ]
                    , True
                    )

                RemoteData.NotAsked ->
                    ( Element.text <| Strings.loginDeleteAccount lang
                    , Element.none
                    , True
                    )

        -- Button to request the password change
        deleteAccountButton =
            Utils.tern canSend
                Ui.primary
                Ui.secondary
                [ Ui.wf ]
                { action =
                    Utils.tern
                        canSend
                        (Ui.Msg <| App.ProfileMsg <| Profile.DeleteAccountConfirm)
                        Ui.None
                , label = deleteAccountButtonText
                }

        -- Account deletion confirm popup
        popup =
            if m.showPopup then
                Ui.popup 1 (Strings.uiWarning lang) <|
                    Element.column [ Ui.wf, Ui.hf ]
                        [ Ui.paragraph [ Ui.cy ] <| Strings.loginConfirmDeleteAccount lang ++ "."
                        , Element.row [ Ui.s 10, Ui.ab, Ui.ar ]
                            [ Ui.secondary [] { label = Element.text <| Strings.uiCancel lang, action = Ui.Msg <| App.ProfileMsg <| Profile.DeleteAccountCancel }
                            , Ui.primary [] { label = Element.text <| Strings.uiConfirm lang, action = Ui.Msg <| App.ProfileMsg <| Profile.DeleteAccountConfirmTwice }
                            ]
                        ]

            else
                Element.none

        -- Content
        content =
            Element.column [ Ui.wf, Ui.s 30 ]
                [ currentPassword
                , deleteAccountButton
                , outcomeMessage
                ]
    in
    ( content, popup )


{-| Column to navigate in tabs.
-}
tabs : Config -> User -> Profile.Model -> Element App.Msg
tabs config _ _ =
    let
        lang =
            config.clientState.lang

        link : String -> Profile.Model -> Element App.Msg
        link label tab =
            Ui.link []
                { action = Ui.Msg <| App.ProfileMsg <| Profile.TabChanged tab
                , label = label
                }
    in
    Element.el [ Ui.p 10, Ui.wf, Ui.hf ] <|
        Element.column [ Ui.wf, Ui.hf, Ui.s 10, Ui.br 1, Border.color Colors.greyBorder ]
            [ Element.el [ Font.bold, Font.size 23 ] <| Element.text <| Strings.navigationSettings lang
            , link (Strings.dataUserEmailAddress lang) Profile.initChangeEmail
            , link (Strings.dataUserPassword lang) Profile.initChangePassword
            , link (Strings.loginDeleteAccount lang) Profile.initDeleteAccount
            ]


{-| Title attributes.
-}
titleAttr : List (Element.Attribute msg)
titleAttr =
    [ Font.size 20, Font.bold, Ui.pb 5 ]
