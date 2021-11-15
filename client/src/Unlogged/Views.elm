module Unlogged.Views exposing (..)

import Browser
import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Lang exposing (Lang)
import Route
import Status
import Ui.BottomBar as Ui
import Ui.Colors as Colors
import Ui.Navbar as Ui
import Ui.Utils as Ui
import Unlogged.Types as Unlogged
import Utils exposing (checkEmail)


view : Maybe Unlogged.Model -> Browser.Document Unlogged.Msg
view fullModel =
    { title = "Polymny"
    , body = [ Element.layout [ Ui.hf, Font.size 18 ] (viewContent fullModel) ]
    }


viewContent : Maybe Unlogged.Model -> Element Unlogged.Msg
viewContent model =
    case model of
        Just m ->
            Element.column
                [ Background.color Colors.whiteBis
                , Ui.wf
                , Ui.hf
                , Font.family [ Font.typeface "Cantarell" ]
                ]
                [ Ui.navbar m.global Nothing Nothing |> Element.map (\_ -> Unlogged.Noop)
                , Element.el [ Ui.hf, Ui.wf ] (content m)
                , Ui.bottomBar Unlogged.LangChanged m.global Nothing
                ]

        Nothing ->
            Element.none


content : Unlogged.Model -> Element Unlogged.Msg
content { global, page } =
    let
        element =
            case page of
                Unlogged.Login form ->
                    loginForm global.registrationDisabled global.lang form

                Unlogged.SignUp form ->
                    signUpForm global.lang form

                Unlogged.ForgotPassword form ->
                    forgotPasswordForm global.lang form

                Unlogged.ResetPassword form ->
                    resetPassword global.lang form

                Unlogged.Activated ->
                    activated global.lang

                Unlogged.ValidateInvitation form ->
                    validateInvitationForm global.lang form
    in
    Element.row [ Ui.wf ]
        [ Element.el [ Ui.wfp 2 ] Element.none
        , Element.column [ Element.spacing 10, Ui.wfp 1 ] [ element ]
        , Element.el [ Ui.wfp 2 ] Element.none
        ]


loginForm : Bool -> Lang -> Unlogged.LoginForm -> Element Unlogged.Msg
loginForm registrationDisabled lang form =
    let
        msg =
            case form.status of
                Status.NotSent ->
                    Just Unlogged.LoginSubmitted

                Status.Error ->
                    Just Unlogged.LoginSubmitted

                _ ->
                    Nothing

        submitOnEnter =
            case msg of
                Just m ->
                    [ Ui.onEnter m ]

                _ ->
                    []

        errorMessage =
            case form.status of
                Status.Error ->
                    Ui.error (Element.text (Lang.loginFailed lang))

                _ ->
                    Element.none

        submitButton =
            Element.el [ Element.centerX ]
                (Ui.primaryButton
                    { label =
                        case form.status of
                            Status.Sent ->
                                Ui.spinner

                            _ ->
                                Element.text (Lang.login lang)
                    , onPress = msg
                    }
                )

        fields =
            [ errorMessage
            , Input.username submitOnEnter
                { label = Input.labelLeft [] Element.none
                , onChange = Unlogged.LoginUsernameChanged
                , placeholder = Just (Input.placeholder [] (Element.text (Lang.username lang)))
                , text = form.username
                }
            , Input.currentPassword submitOnEnter
                { label = Input.labelLeft [] Element.none
                , onChange = Unlogged.LoginPasswordChanged
                , placeholder = Just (Input.placeholder [] (Element.text (Lang.password lang)))
                , text = form.password
                , show = False
                }
            , submitButton
            , Element.row [ Element.spacing 10, Element.centerX ]
                [ Ui.linkButton []
                    { onPress = Just (Unlogged.GoToPage (Unlogged.ForgotPassword Unlogged.initForgotPasswordForm))
                    , label = Element.text (Lang.forgotYourPassword lang)
                    }
                , if not registrationDisabled then
                    Ui.linkButton []
                        { onPress = Just (Unlogged.GoToPage (Unlogged.SignUp Unlogged.initSignUpForm))
                        , label = Element.text (Lang.notRegisteredYet lang)
                        }

                  else
                    Element.none
                ]
            ]
    in
    Element.column [ Element.padding 10, Element.spacing 10 ] fields


signUpForm : Lang -> Unlogged.SignUpForm -> Element Unlogged.Msg
signUpForm lang form =
    let
        emailSyntax =
            checkEmail form.email

        passwordMatch =
            form.password == form.repeatPassword

        usernameAtLeast3 =
            String.length form.username > 3

        errorMessages =
            [ maybe (not passwordMatch) (Lang.passwordsDontMatch lang)
            , maybe (not emailSyntax) (Lang.invalidEmail lang)
            , maybe (not usernameAtLeast3) (Lang.usernameMustBeAtLeast3 lang)
            , maybe (not form.acceptConditions) (Lang.mustAcceptConditions lang)
            ]
                |> List.filterMap (\x -> x)

        errorElement =
            case ( form.status, form.showMessage, not (List.isEmpty errorMessages) ) of
                ( _, True, True ) ->
                    Ui.error
                        (Element.column
                            [ Element.spacing 10 ]
                            [ Element.text (Lang.errorsInSignUpForm lang)
                            , errorMessages
                                |> List.map Element.text
                                |> Element.column [ Element.paddingXY 20 0 ]
                            ]
                        )

                _ ->
                    Element.none

        msg =
            case ( form.status, List.isEmpty errorMessages ) of
                ( Status.NotSent, True ) ->
                    Just Unlogged.SignUpSubmitted

                ( Status.Error, True ) ->
                    Just Unlogged.SignUpSubmitted

                _ ->
                    Just Unlogged.SignUpShowMessage

        submitOnEnter =
            case msg of
                Just m ->
                    [ Ui.onEnter m ]

                _ ->
                    []

        submitButton =
            case form.status of
                Status.Success ->
                    Element.none

                _ ->
                    Element.el [ Element.centerX ]
                        (Ui.primaryButton
                            { label =
                                case form.status of
                                    Status.Sent ->
                                        Ui.spinner

                                    _ ->
                                        Element.text (Lang.signUp lang)
                            , onPress = msg
                            }
                        )

        fields =
            [ errorElement
            , Input.username submitOnEnter
                { label = Input.labelLeft [] Element.none
                , onChange = Unlogged.SignUpUsernameChanged
                , placeholder = Just (Input.placeholder [] (Element.text (Lang.username lang)))
                , text = form.username
                }
            , Input.email submitOnEnter
                { label = Input.labelLeft [] Element.none
                , onChange = Unlogged.SignUpEmailChanged
                , placeholder = Just (Input.placeholder [] (Element.text (Lang.emailAddress lang)))
                , text = form.email
                }
            , Input.newPassword submitOnEnter
                { label = Input.labelLeft [] Element.none
                , onChange = Unlogged.SignUpPasswordChanged
                , placeholder = Just (Input.placeholder [] (Element.text (Lang.password lang)))
                , text = form.password
                , show = False
                }
            , Input.newPassword submitOnEnter
                { label = Input.labelLeft [] Element.none
                , onChange = Unlogged.SignUpRepeatPasswordChanged
                , placeholder = Just (Input.placeholder [] (Element.text (Lang.repeatPassword lang)))
                , text = form.repeatPassword
                , show = False
                }
            , Input.checkbox []
                { label = Input.labelRight [] (Element.text (Lang.acceptConditions lang))
                , onChange = Unlogged.SignUpConditionsChanged
                , icon = Input.defaultCheckbox
                , checked = form.acceptConditions
                }
            , Input.checkbox []
                { label = Input.labelRight [] (Element.text (Lang.registerNewsletter lang))
                , onChange = Unlogged.SignUpRegisterNewsletterChanged
                , icon = Input.defaultCheckbox
                , checked = form.registerNewsletter
                }
            , submitButton
            ]
    in
    Element.column [ Element.padding 10, Element.spacing 10 ] fields


forgotPasswordForm : Lang -> Unlogged.ForgotPasswordForm -> Element Unlogged.Msg
forgotPasswordForm lang form =
    let
        msg =
            case form.status of
                Status.NotSent ->
                    Just Unlogged.ForgotPasswordSubmitted

                Status.Error ->
                    Just Unlogged.ForgotPasswordSubmitted

                _ ->
                    Nothing

        submitOnEnter =
            case msg of
                Just m ->
                    [ Ui.onEnter m ]

                _ ->
                    []

        errorMessage =
            case form.status of
                Status.Error ->
                    Ui.error (Element.text (Lang.noSuchEmail lang))

                Status.Success ->
                    Ui.success (Element.text (Lang.mailSent lang))

                _ ->
                    Element.none

        submitButton =
            case form.status of
                Status.Success ->
                    Element.none

                _ ->
                    Element.el [ Element.centerX ]
                        (Ui.primaryButton
                            { label =
                                case form.status of
                                    Status.Sent ->
                                        Ui.spinner

                                    _ ->
                                        Element.text (Lang.askNewPassword lang)
                            , onPress = msg
                            }
                        )

        fields =
            Element.column [ Element.spacing 10 ]
                [ errorMessage
                , Input.username submitOnEnter
                    { label = Input.labelLeft [] Element.none
                    , onChange = Unlogged.ForgotPasswordEmailChanged
                    , placeholder = Just (Input.placeholder [] (Element.text (Lang.emailAddress lang)))
                    , text = form.email
                    }
                , submitButton
                ]
    in
    Element.el [ Element.padding 10 ] fields


resetPassword : Lang -> Unlogged.ResetPasswordForm -> Element Unlogged.Msg
resetPassword lang form =
    let
        msg =
            case form.status of
                Status.NotSent ->
                    Just Unlogged.ResetPasswordSubmitted

                _ ->
                    Nothing

        submitOnEnter =
            case msg of
                Just m ->
                    [ Ui.onEnter m ]

                _ ->
                    []

        submitButton =
            Element.el [ Element.centerX ]
                (Ui.primaryButton
                    { label =
                        case form.status of
                            Status.Sent ->
                                Ui.spinner

                            _ ->
                                Element.text (Lang.changePassword lang)
                    , onPress = msg
                    }
                )

        fields =
            Element.column [ Element.spacing 10 ]
                [ Input.newPassword submitOnEnter
                    { label = Input.labelLeft [] Element.none
                    , onChange = Unlogged.ResetPasswordChanged
                    , placeholder = Just (Input.placeholder [] (Element.text (Lang.newPassword lang)))
                    , text = form.newPassword
                    , show = False
                    }
                , submitButton
                ]
    in
    Element.el [ Element.padding 10 ] fields


maybe : Bool -> a -> Maybe a
maybe check value =
    if check then
        Just value

    else
        Nothing


activated : Lang -> Element Unlogged.Msg
activated lang =
    Element.column [ Element.spacing 10, Element.padding 10 ]
        [ Ui.success (Element.text (Lang.accountActivated lang))
        , Element.el [ Element.centerX ] (Ui.primaryLink { route = Route.Home, label = Element.text (Lang.goToPolymny lang) })
        ]


validateInvitationForm : Lang -> Unlogged.ValidateInvitationForm -> Element Unlogged.Msg
validateInvitationForm lang form =
    let
        passwordMatch =
            form.password == form.repeatPassword

        errorMessages =
            [ maybe (not passwordMatch) (Lang.passwordsDontMatch lang)
            ]
                |> List.filterMap (\x -> x)

        errorElement =
            case ( form.status, form.showMessage, not (List.isEmpty errorMessages) ) of
                ( _, True, True ) ->
                    Ui.error
                        (Element.column
                            [ Element.spacing 10 ]
                            [ Element.text (Lang.errorsInSignUpForm lang)
                            , errorMessages
                                |> List.map Element.text
                                |> Element.column [ Element.paddingXY 20 0 ]
                            ]
                        )

                _ ->
                    Element.none

        msg =
            case ( form.status, List.isEmpty errorMessages ) of
                ( Status.NotSent, True ) ->
                    Just Unlogged.ValidateInvitationSubmitted

                ( Status.Error, True ) ->
                    Just Unlogged.ValidateInvitationSubmitted

                _ ->
                    Just Unlogged.ValidateInvitationShowMessage

        submitOnEnter =
            case msg of
                Just m ->
                    [ Ui.onEnter m ]

                _ ->
                    []

        submitButton =
            case form.status of
                Status.Success ->
                    Element.none

                _ ->
                    Element.el [ Element.centerX ]
                        (Ui.primaryButton
                            { label =
                                case form.status of
                                    Status.Sent ->
                                        Ui.spinner

                                    _ ->
                                        Element.text (Lang.signUp lang)
                            , onPress = msg
                            }
                        )

        header =
            Element.el Ui.formTitle <|
                Element.text (Lang.enterPasswords lang)

        fields =
            [ header
            , errorElement
            , Input.newPassword
                submitOnEnter
                { label = Input.labelLeft [] Element.none
                , onChange = Unlogged.ValidateInvitationPasswordChanged
                , placeholder = Just (Input.placeholder [] (Element.text (Lang.password lang)))
                , text = form.password
                , show = False
                }
            , Input.newPassword submitOnEnter
                { label = Input.labelLeft [] Element.none
                , onChange = Unlogged.ValidateInvitationRepeatPasswordChanged
                , placeholder = Just (Input.placeholder [] (Element.text (Lang.repeatPassword lang)))
                , text = form.repeatPassword
                , show = False
                }
            , submitButton
            ]
    in
    Element.column [ Element.padding 10, Element.spacing 10 ] fields
