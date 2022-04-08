module App.Views exposing (view, viewSuccess, viewError)

{-| This module manages the views of the application.

@docs view, viewSuccess, viewError

-}

import App.Types as App
import Browser
import Element exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Home.Views as Home
import NewCapsule.Views as NewCapsule
import Preparation.Views as Preparation
import Ui.Colors as Colors
import Ui.Graphics as Ui
import Ui.Navbar as Ui
import Ui.Utils as Ui


{-| Returns the view of the model.
-}
view : Result App.Error App.Model -> Browser.Document App.Msg
view fullModel =
    { title = "Polymny Studio"
    , body =
        [ Element.layout
            [ Ui.wf
            , Ui.hf
            , Font.size 18
            , Font.family
                [ Font.typeface "Ubuntu"
                , Font.typeface "Cantarell"
                ]
            , Background.color Colors.greyBackground
            , Font.color Colors.greyFont
            ]
            (viewContent fullModel)
        ]
    }


{-| Stylizes all the content of the app.
-}
viewContent : Result App.Error App.Model -> Element App.Msg
viewContent fullModel =
    let
        ( content, popup ) =
            case fullModel of
                Ok model ->
                    viewSuccess model

                Err error ->
                    ( viewError error, Element.none )
    in
    Element.column [ Ui.wf, Ui.hf, Element.inFront popup ]
        [ Ui.navbar (fullModel |> Result.toMaybe |> Maybe.map .config) (fullModel |> Result.toMaybe |> Maybe.map .user)
        , Element.el [ Ui.wf, Ui.hf, Element.scrollbarY ] content
        , Ui.bottombar (fullModel |> Result.toMaybe |> Maybe.map .config)
        ]


{-| Returns the view if the model is correct.
-}
viewSuccess : App.Model -> ( Element App.Msg, Element App.Msg )
viewSuccess model =
    case model.page of
        App.Home ->
            Home.view model.config model.user

        App.NewCapsule m ->
            NewCapsule.view model.config model.user m

        App.Preparation m ->
            Preparation.view model.config model.user m


{-| Returns the view if the model is in error.
-}
viewError : App.Error -> Element App.Msg
viewError error =
    Element.text (App.errorToString error)
