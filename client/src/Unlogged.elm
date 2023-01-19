module Unlogged exposing (..)

{-| Module that makes the login form available as a standalone element.
-}

import Browser
import Config
import Element
import Element.Font as Font
import Html exposing (Html)
import Json.Decode as Decode
import Ui.Colors as Colors
import Ui.Utils as Ui
import Unlogged.Types as Unlogged
import Unlogged.Updates as Unlogged
import Unlogged.Views as Unlogged


{-| A main app for displaying the login form in another page (such as our portal).
-}
main : Program Decode.Value (Maybe Unlogged.Model) Unlogged.Msg
main =
    Browser.element
        { init = initStandalone
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        }


{-| Initializes the model for a standalone use.
-}
initStandalone : Decode.Value -> ( Maybe Unlogged.Model, Cmd Unlogged.Msg )
initStandalone flags =
    let
        serverConfig =
            Decode.decodeValue (Decode.field "global" (Decode.field "serverConfig" Config.decodeServerConfig)) flags

        clientConfig =
            Decode.decodeValue (Decode.field "global" (Decode.field "clientConfig" Config.decodeClientConfig)) flags

        clientState =
            Config.initClientState Nothing (clientConfig |> Result.toMaybe |> Maybe.andThen .lang)
    in
    case ( clientConfig, serverConfig ) of
        ( Ok c, Ok s ) ->
            ( Just <| Unlogged.init { serverConfig = s, clientConfig = c, clientState = clientState } Nothing
            , Cmd.none
            )

        _ ->
            ( Nothing, Cmd.none )


{-| Sup.
-}
view : Maybe Unlogged.Model -> Html Unlogged.Msg
view model =
    case model of
        Just m ->
            Element.layout
                [ Ui.wf
                , Ui.hf
                , Font.size 18
                , Font.family
                    [ Font.typeface "Urbanist"
                    , Font.typeface "Ubuntu"
                    , Font.typeface "Cantarell"
                    ]
                , Font.color Colors.greyFont
                ]
                (Unlogged.view m)

        _ ->
            Element.layout [] (Element.text "oops")


{-| Sup.
-}
update : Unlogged.Msg -> Maybe Unlogged.Model -> ( Maybe Unlogged.Model, Cmd Unlogged.Msg )
update msg model =
    case model of
        Just m ->
            Unlogged.update msg m |> Tuple.mapFirst Just

        _ ->
            ( Nothing, Cmd.none )
