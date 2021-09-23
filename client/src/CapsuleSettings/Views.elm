module CapsuleSettings.Views exposing (..)

import Capsule exposing (Capsule)
import CapsuleSettings.Types as CapsuleSettings
import Core.Types as Core
import Element exposing (Element)
import Element.Font as Font
import Element.Input as Input
import FontAwesome as Fa
import Html
import Html.Attributes
import Html.Events
import Lang exposing (Lang)
import Ui.Colors as Colors
import Ui.Utils as Ui
import User exposing (User)


view : Core.Global -> User -> CapsuleSettings.Model -> ( Element Core.Msg, Maybe (Element Core.Msg) )
view global _ model =
    let
        header : (Lang -> String) -> Element Core.Msg
        header lang =
            Element.el [ Element.padding 10, Font.bold ] (Element.text (lang global.lang))

        table =
            Element.table [ Ui.wf ]
                { data = List.map Just model.capsule.users ++ [ Nothing ]
                , columns =
                    [ { header = header Lang.username
                      , width = Element.fill
                      , view = viewUsername global model
                      }
                    , { header = header Lang.role
                      , width = Element.fill
                      , view = viewRole global model
                      }
                    , { header = Element.none
                      , width = Element.shrink
                      , view = remove global model.capsule
                      }
                    ]
                }

        content =
            Element.row [ Ui.wf, Ui.hf, Element.padding 10 ]
                [ Element.el [ Ui.wfp 1, Ui.hf ] Element.none
                , Element.column [ Ui.wfp 1, Ui.hf, Element.spacing 10 ]
                    [ Element.el Ui.formTitle (Element.text (Lang.people global.lang))
                    , Element.el [ Element.spacing 10, Ui.wf, Ui.hf ] table
                    ]
                , Element.el [ Ui.wfp 1 ] Element.none
                ]
    in
    ( content, Nothing )


viewUsername : Core.Global -> CapsuleSettings.Model -> Maybe Capsule.User -> Element Core.Msg
viewUsername global model u =
    case u of
        Nothing ->
            Element.el [ Element.padding 10 ]
                (Input.text []
                    { label = Input.labelHidden ""
                    , onChange = \x -> Core.CapsuleSettingsMsg (CapsuleSettings.ShareUsernameChanged x)
                    , placeholder = Just (Input.placeholder [] (Element.text (Lang.usernameOrEmail global.lang)))
                    , text = model.username
                    }
                )

        Just user ->
            Element.el [ Element.padding 10 ] (Element.text user.username)


viewRole : Core.Global -> CapsuleSettings.Model -> Maybe Capsule.User -> Element Core.Msg
viewRole global model u =
    case u of
        Nothing ->
            let
                options : List Capsule.Role
                options =
                    [ Capsule.Read, Capsule.Write ]

                optionToHtml : Capsule.Role -> Html.Html Core.Msg
                optionToHtml option =
                    let
                        selected =
                            Html.Attributes.selected (option == model.role)
                    in
                    Html.option [ selected, Html.Attributes.value (Capsule.encodeRole option) ]
                        [ Html.text (Lang.roleView global.lang option) ]

                onChange =
                    Html.Events.onInput
                        (\x ->
                            case Capsule.decodeRoleString x of
                                Just r ->
                                    Core.CapsuleSettingsMsg (CapsuleSettings.ShareRoleChanged r)

                                _ ->
                                    Core.Noop
                        )
            in
            options
                |> List.map optionToHtml
                |> Html.select [ onChange ]
                |> Element.html
                |> Element.el [ Element.centerY ]

        Just user ->
            if model.capsule.role /= Capsule.Owner || user.role == Capsule.Owner then
                Element.el [ Element.padding 10 ] (Element.text (Lang.roleView global.lang user.role))

            else
                let
                    options : List Capsule.Role
                    options =
                        [ Capsule.Read, Capsule.Write ]

                    optionToHtml : Capsule.Role -> Html.Html Core.Msg
                    optionToHtml option =
                        let
                            selected =
                                Html.Attributes.selected (option == user.role)
                        in
                        Html.option [ selected, Html.Attributes.value (Capsule.encodeRole option) ]
                            [ Html.text (Lang.roleView global.lang option) ]

                    onChange =
                        Html.Events.onInput
                            (\x ->
                                case Capsule.decodeRoleString x of
                                    Just r ->
                                        Core.CapsuleSettingsMsg (CapsuleSettings.ChangeRole user r)

                                    _ ->
                                        Core.Noop
                            )
                in
                options
                    |> List.map optionToHtml
                    |> Html.select [ onChange ]
                    |> Element.html
                    |> Element.el [ Element.centerY ]


remove : Core.Global -> Capsule -> Maybe Capsule.User -> Element Core.Msg
remove _ capsule u =
    case u of
        Nothing ->
            Element.el [ Element.padding 10, Element.centerY ]
                (Ui.iconButton
                    [ Font.color Colors.navbar ]
                    { onPress = Just (Core.CapsuleSettingsMsg CapsuleSettings.ShareConfirm)
                    , icon = Fa.check
                    , text = Nothing
                    , tooltip = Nothing
                    }
                )

        Just user ->
            if capsule.role /= Capsule.Owner || user.role == Capsule.Owner then
                Element.none

            else
                Element.el [ Element.padding 10 ]
                    (Ui.iconButton [ Font.color Colors.navbar ]
                        { onPress = Just (Core.CapsuleSettingsMsg (CapsuleSettings.RemoveUser user))
                        , icon = Fa.times
                        , text = Nothing
                        , tooltip = Nothing
                        }
                    )
