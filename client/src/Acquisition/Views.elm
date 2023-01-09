module Acquisition.Views exposing (view)

{-| The main view for the acquisition page.

@docs view

-}

import Acquisition.Types as Acquisition
import App.Types as App
import Config exposing (Config)
import Data.User exposing (User)
import Element exposing (Element)
import Element.Font as Font
import Ui.Elements as Ui
import Ui.Graphics as Ui
import Ui.Utils as Ui


{-| The view function for the preparation page.
-}
view : Config -> User -> Acquisition.Model -> ( Element App.Msg, Element App.Msg )
view config user model =
    let
        videoTitle =
            Element.el [ Font.bold ] (Element.text "Video devices")

        video =
            config.clientConfig.devices.video
                |> List.map
                    (\x ->
                        x.label
                            ++ (if x.available then
                                    " (available)"

                                else
                                    " (unavailable)"
                               )
                    )
                |> List.map Element.text
                |> Element.column [ Ui.s 10, Ui.pb 10 ]

        audioTitle =
            Element.el [ Font.bold ] (Element.text "Audio devices")

        audio =
            config.clientConfig.devices.audio
                |> List.map
                    (\x ->
                        x.label
                            ++ (if x.available then
                                    " (available)"

                                else
                                    " (unavailable)"
                               )
                    )
                |> List.map Element.text
                |> Element.column [ Ui.s 10, Ui.pb 10 ]

        content =
            Element.column [ Ui.p 10, Ui.s 10 ] [ videoTitle, video, audioTitle, audio ]
    in
    ( content, Element.none )
