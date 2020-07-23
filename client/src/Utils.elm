module Utils exposing (headerView, resultToMsg)

import Api
import Core.Types as Core
import Element exposing (Element)
import Log exposing (debug)
import LoggedIn.Types as LoggedIn
import Ui.Attributes as Attributes
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
                    [ Ui.primaryButtonDisabled "Préparer"
                    , Ui.textButton msgAcquisition "Acquérir"
                    , Ui.textButton msgEdition "Éditer et Publier"
                    ]

                "acquisition" ->
                    [ Ui.textButton msgPreparation "Préparer"
                    , Ui.primaryButtonDisabled "Acquérir"
                    , Ui.textButton msgEdition "Éditer et Publier"
                    ]

                "edition" ->
                    [ Ui.textButton msgPreparation "Préparer"
                    , Ui.textButton msgAcquisition "Acquérir"
                    , Ui.primaryButtonDisabled "Éditer et Publier"
                    ]

                _ ->
                    [ Element.none ]
    in
    Element.column Attributes.boxAttributes
        [ Element.paragraph []
            [ Element.text <| "Capsule "
            , Element.text <| String.dropRight 38 details.capsule.name
            ]
        , Element.row [ Element.spacing 20 ]
            buttons
        ]
