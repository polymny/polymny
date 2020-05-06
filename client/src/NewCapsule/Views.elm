module NewCapsule.Views exposing (view)

import Core.Types as Core
import Element exposing (Element)
import Element.Input as Input
import LoggedIn.Types as LoggedIn
import NewCapsule.Types as NewCapsule
import Status
import Ui.Ui as Ui


view : NewCapsule.Model -> Element Core.Msg
view { status, name, title, description } =
    let
        submitOnEnter =
            case status of
                Status.Sent ->
                    []

                Status.Success () ->
                    []

                _ ->
                    [ Ui.onEnter NewCapsule.Submitted ]

        submitButton =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "Creating capsule..."

                Status.Success () ->
                    Ui.primaryButtonDisabled "Capsule created!"

                _ ->
                    Ui.primaryButton (Just NewCapsule.Submitted) "Create capsule"

        message =
            case status of
                Status.Error () ->
                    Just (Ui.errorModal "Capsule creation failed")

                Status.Success () ->
                    Just (Ui.successModal "Capsule created!")

                _ ->
                    Nothing

        header =
            Element.row [ Element.centerX ] [ Element.text "New capsule" ]

        fields =
            [ Input.text submitOnEnter
                { label = Input.labelAbove [] (Element.text "Capsule name")
                , onChange = NewCapsule.NameChanged
                , placeholder = Nothing
                , text = name
                }
            , Input.text submitOnEnter
                { label = Input.labelAbove [] (Element.text "Capsule Title")
                , onChange = NewCapsule.TitleChanged
                , placeholder = Nothing
                , text = title
                }
            , Input.text submitOnEnter
                { label = Input.labelAbove [] (Element.text "Capsule description")
                , onChange = NewCapsule.DescriptionChanged
                , placeholder = Nothing
                , text = description
                }
            , submitButton
            ]

        form =
            case message of
                Just m ->
                    header :: m :: fields

                Nothing ->
                    header :: fields
    in
    Element.map Core.LoggedInMsg <|
        Element.map LoggedIn.NewCapsuleMsg <|
            Element.column [ Element.centerX, Element.padding 10, Element.spacing 10 ]
                form
