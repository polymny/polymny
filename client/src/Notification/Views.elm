module Notification.Views exposing (view)

import Core.Types as Core
import Element exposing (Element)
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Notification.Types as Notification exposing (Notification)
import Ui.Colors as Colors


view : Int -> Notification -> Element Core.Msg
view id notification =
    let
        ( icon, fontStyle ) =
            if notification.read then
                ( Element.el [ Font.color Colors.grey ] (Element.text "●"), Font.regular )

            else
                ( Element.el [ Font.color Colors.primary ] (Element.text "⬤"), Font.bold )

        label =
            Element.row
                [ Element.width Element.fill
                , Border.widthEach { top = 1, bottom = 0, left = 0, right = 0 }
                , Border.color Colors.black
                , Element.paddingXY 0 5
                ]
                [ icon
                , Element.column
                    [ Element.width Element.fill
                    , Element.padding 5
                    , Element.spacing 10
                    ]
                    [ Element.paragraph [ fontStyle ] [ Element.text notification.title ]
                    , Element.paragraph [ fontStyle ] [ Element.text notification.content ]
                    ]
                ]
    in
    if notification.read then
        label

    else
        Input.button
            [ Element.width Element.fill ]
            { label = label
            , onPress = Just (Core.NotificationMsg (Core.MarkNotificationRead id))
            }
