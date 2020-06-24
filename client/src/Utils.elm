module Utils exposing (headerView, resultToMsg)

import Api
import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Log exposing (debug)
import LoggedIn.Types as LoggedIn
import Ui.Colors as Colors
import Ui.Ui as Ui


resultToMsg : (x -> msg) -> (e -> msg) -> Result e x -> msg
resultToMsg ifSuccess ifError result =
    case result of
        Ok x ->
            ifSuccess x

        Err e ->
            let
                err =
                    debug "Error" e
            in
            ifError err


headerView : String -> Api.CapsuleDetails -> Element Core.Msg
headerView active details =
    let
        msgPreparation =
            Just <|
                Core.LoggedInMsg <|
                    LoggedIn.PreparationClicked details

        msgAcquisition =
            Just <|
                Core.LoggedInMsg <|
                    LoggedIn.AcquisitionClicked details

        msgEdition =
            Just <|
                Core.LoggedInMsg <|
                    LoggedIn.EditionClicked details False

        buttons =
            case active of
                "preparation" ->
                    [ Ui.primaryButtonDisabled "Préparation"
                    , Ui.textButton msgAcquisition "Acquisition"
                    , Ui.textButton msgEdition "Édition"
                    ]

                "acquisition" ->
                    [ Ui.textButton msgPreparation "Préparation"
                    , Ui.primaryButtonDisabled "Acquisition"
                    , Ui.textButton msgEdition "Édition"
                    ]

                "edition" ->
                    [ Ui.textButton msgPreparation "Préparation"
                    , Ui.textButton msgAcquisition "Acquisition"
                    , Ui.primaryButtonDisabled "Edition"
                    ]

                _ ->
                    [ Element.none ]
    in
    Element.column
        [ Background.color Colors.whiteDark
        , Element.width
            Element.fill
        , Element.spacing 20
        , Element.padding 10
        , Border.color Colors.whiteDarker
        , Border.rounded 5
        , Border.width 1
        ]
        [ Element.paragraph []
            [ Element.text <| "Capsule "
            , Element.text <| String.left 20 details.capsule.name
            , Element.text <| " ( id = " ++ String.fromInt details.capsule.id ++ ")"
            ]
        , Element.row [ Element.spacing 20 ]
            buttons
        ]
