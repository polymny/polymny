module Capsule.Views exposing (..)

import Api
import Capsule.Types as Capsule
import Colors
import Core.Types as Core
import Dialog
import DnDList
import DnDList.Groups
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import File exposing (File)
import Html
import Html.Attributes
import LoggedIn.Types as LoggedIn
import Status
import Ui


view : Api.Session -> Capsule.Model -> Element Core.Msg
view session { details, slides, uploadForm, editPrompt, slideModel, gosModel } =
    let
        calculateOffset : Int -> Int
        calculateOffset index =
            slides |> List.map (\l -> List.length l) |> List.take index |> List.foldl (+) 0

        dialogConfig =
            if editPrompt.visible then
                Just (configPromptModal editPrompt)

            else
                Nothing
    in
    Element.el
        [ Element.padding 10
        , Element.mapAttribute Core.LoggedInMsg <|
            Element.mapAttribute LoggedIn.CapsuleMsg <|
                Element.mapAttribute Capsule.EditPromptMsg <|
                    Element.inFront (Dialog.view dialogConfig)
        ]
        (Element.row (Element.scrollbarX :: designAttributes)
            [ capsuleInfoView session details uploadForm
            , Element.column
                (Element.scrollbarX
                    :: Element.width Element.fill
                    :: Element.centerX
                    :: Element.alignTop
                    :: Background.color Colors.dangerLight
                    :: designAttributes
                )
                [ Element.el [ Element.centerX ] (Element.text "Timeline présentation")
                , Element.row (Element.scrollbarX :: Background.color Colors.dangerDark :: designAttributes)
                    (List.indexedMap (\i -> capsuleGosView gosModel slideModel (calculateOffset i) i) slides)
                ]
            ]
        )


designAttributes : List (Element.Attribute msg)
designAttributes =
    [ Element.padding 10
    , Element.width Element.fill
    , Border.rounded 5
    , Border.width 1
    , Border.color Colors.grey
    ]


designGosAttributes : List (Element.Attribute msg)
designGosAttributes =
    [ Element.padding 10
    , Element.width Element.fill
    , Element.alignTop
    , Border.rounded 5
    , Border.width 1
    , Border.color Colors.grey
    , Background.color Colors.grey
    ]


capsuleInfoView : Api.Session -> Api.CapsuleDetails -> Capsule.UploadForm -> Element Core.Msg
capsuleInfoView session capsuleDetails form =
    Element.column [ Element.centerX, Element.alignTop, Element.spacing 10, Element.padding 10 ]
        [ Element.column []
            [ Element.el [ Font.size 20 ] (Element.text "Infos sur la capsule")
            , Element.el [ Font.size 14 ] (Element.text ("Loaded capsule is  " ++ capsuleDetails.capsule.name))
            , Element.el [ Font.size 14 ] (Element.text ("Title :   " ++ capsuleDetails.capsule.title))
            , Element.el [ Font.size 14 ] (Element.text ("Desritpion:  " ++ capsuleDetails.capsule.description))
            ]
        , loggedInUploadSlideShowView session form
        ]



-- DRAG N DROP VIEWS


type DragOptions
    = Drag
    | Drop
    | Ghost
    | EventLess



-- GOS VIEWS


capsuleGosView : DnDList.Model -> DnDList.Groups.Model -> Int -> Int -> List Capsule.MaybeSlide -> Element Core.Msg
capsuleGosView gosModel slideModel offset gosIndex gos =
    case Capsule.gosSystem.info gosModel of
        Just { dragIndex } ->
            if dragIndex /= gosIndex then
                genericGosView Drop gosModel slideModel offset gosIndex gos

            else
                genericGosView EventLess gosModel slideModel offset gosIndex gos

        _ ->
            genericGosView Drag gosModel slideModel offset gosIndex gos


gosGhostView : DnDList.Model -> DnDList.Groups.Model -> List Capsule.MaybeSlide -> Element Core.Msg
gosGhostView gosModel slideModel slides =
    case maybeDragGos gosModel slides of
        Just s ->
            genericGosView Ghost gosModel slideModel 0 0 s

        _ ->
            Element.none


maybeDragGos : DnDList.Model -> List Capsule.MaybeSlide -> Maybe (List Capsule.MaybeSlide)
maybeDragGos gosModel slides =
    let
        s =
            Capsule.regroupSlides slides
    in
    Capsule.gosSystem.info gosModel
        |> Maybe.andThen (\{ dragIndex } -> s |> List.drop dragIndex |> List.head)


genericGosView : DragOptions -> DnDList.Model -> DnDList.Groups.Model -> Int -> Int -> List Capsule.MaybeSlide -> Element Core.Msg
genericGosView options gosModel slideModel offset index gos =
    let
        gosId : String
        gosId =
            if options == Ghost then
                "gos-ghost"

            else
                "gos-" ++ String.fromInt index

        dragAttributes : List (Element.Attribute Core.Msg)
        dragAttributes =
            if options == Drag && not (Capsule.isJustGosId gos) then
                convertAttributes (Capsule.gosSystem.dragEvents index gosId)

            else
                []

        dropAttributes : List (Element.Attribute Core.Msg)
        dropAttributes =
            if options == Drop && not (Capsule.isJustGosId gos) then
                convertAttributes (Capsule.gosSystem.dropEvents index gosId)

            else
                []

        ghostAttributes : List (Element.Attribute Core.Msg)
        ghostAttributes =
            if options == Ghost then
                convertAttributes (Capsule.gosSystem.ghostStyles gosModel)

            else
                []

        eventLessAttributes : List (Element.Attribute Core.Msg)
        eventLessAttributes =
            if options == EventLess then
                [ Element.htmlAttribute (Html.Attributes.style "visibility" "hidden") ]

            else
                []

        slideDropAttributes : List (Element.Attribute Core.Msg)
        slideDropAttributes =
            convertAttributes (Capsule.slideSystem.dropEvents offset slideId)

        slideId : String
        slideId =
            if options == Ghost then
                "slide-ghost"

            else
                "slide-" ++ String.fromInt offset

        slides : List (Element Core.Msg)
        slides =
            List.indexedMap (designSlideView slideModel offset) gos
    in
    case gos of
        [ Capsule.GosId _ ] ->
            Element.column
                [ Element.htmlAttribute (Html.Attributes.id gosId)
                , Element.height Element.fill
                , Element.width (Element.px 50)
                ]
                [ Element.el
                    (Element.htmlAttribute (Html.Attributes.id slideId)
                        :: Element.width (Element.px 50)
                        :: Element.height (Element.px 300)
                        :: slideDropAttributes
                    )
                    Element.none
                ]

        _ ->
            Element.column
                (Element.htmlAttribute (Html.Attributes.id gosId)
                    :: Element.padding 10
                    :: Element.spacing 20
                    :: Element.centerX
                    :: dropAttributes
                    ++ ghostAttributes
                    ++ designGosAttributes
                )
                [ Element.row (Element.width Element.fill :: dragAttributes ++ eventLessAttributes)
                    [ Element.el
                        [ Element.padding 10
                        , Border.color Colors.danger
                        , Border.rounded 5
                        , Border.width 1
                        , Element.centerX
                        , Font.size 20
                        ]
                        (Element.text (String.fromInt index))
                    , Element.row [ Element.alignRight ] [ Ui.trashIcon ]
                    ]
                , Element.column (designAttributes ++ eventLessAttributes) slides
                ]



-- SLIDES VIEWS


slideGhostView : DnDList.Groups.Model -> List Capsule.MaybeSlide -> Element Core.Msg
slideGhostView slideModel slides =
    case maybeDragSlide slideModel slides of
        Capsule.JustSlide s ->
            genericDesignSlideView Ghost slideModel 0 0 (Capsule.JustSlide s)

        _ ->
            Element.none


designSlideView : DnDList.Groups.Model -> Int -> Int -> Capsule.MaybeSlide -> Element Core.Msg
designSlideView slideModel offset localIndex slide =
    case ( Capsule.slideSystem.info slideModel, maybeDragSlide slideModel ) of
        ( Just { dragIndex }, _ ) ->
            if offset + localIndex == dragIndex then
                genericDesignSlideView EventLess slideModel offset localIndex slide

            else
                genericDesignSlideView Drop slideModel offset localIndex slide

        _ ->
            genericDesignSlideView Drag slideModel offset localIndex slide


maybeDragSlide : DnDList.Groups.Model -> List Capsule.MaybeSlide -> Capsule.MaybeSlide
maybeDragSlide slideModel slides =
    let
        x =
            Capsule.slideSystem.info slideModel
                |> Maybe.andThen (\{ dragIndex } -> slides |> List.drop dragIndex |> List.head)
    in
    case x of
        Just (Capsule.JustSlide n) ->
            Capsule.JustSlide n

        _ ->
            Capsule.GosId -1


genericDesignSlideView : DragOptions -> DnDList.Groups.Model -> Int -> Int -> Capsule.MaybeSlide -> Element Core.Msg
genericDesignSlideView options slideModel offset localIndex s =
    let
        globalIndex : Int
        globalIndex =
            offset + localIndex

        slideId : String
        slideId =
            if options == Ghost then
                "slide-ghost"

            else
                "slide-" ++ String.fromInt globalIndex

        dragAttributes : List (Element.Attribute Core.Msg)
        dragAttributes =
            if options == Drag && Capsule.isJustSlide s then
                convertAttributes (Capsule.slideSystem.dragEvents globalIndex slideId)

            else
                []

        dropAttributes : List (Element.Attribute Core.Msg)
        dropAttributes =
            if options == Drop then
                convertAttributes (Capsule.slideSystem.dropEvents globalIndex slideId)

            else
                []

        ghostAttributes : List (Element.Attribute Core.Msg)
        ghostAttributes =
            if options == Ghost then
                convertAttributes (Capsule.slideSystem.ghostStyles slideModel)

            else
                []

        eventLessAttributes : List (Element.Attribute Core.Msg)
        eventLessAttributes =
            if options == EventLess then
                [ Element.htmlAttribute (Html.Attributes.style "visibility" "hidden") ]

            else
                []
    in
    case s of
        Capsule.GosId _ ->
            Element.none

        Capsule.JustSlide slide ->
            let
                promptMsg : Core.Msg
                promptMsg =
                    Core.LoggedInMsg (LoggedIn.CapsuleMsg (Capsule.EditPromptMsg (Capsule.EditPromptOpenDialog slide.id slide.prompt)))
            in
            Element.el
                (Element.htmlAttribute (Html.Attributes.id slideId) :: Element.width Element.fill :: dropAttributes ++ ghostAttributes)
                (Element.row
                    [ Element.padding 10
                    , Background.color Colors.white
                    , Border.rounded 5
                    , Border.width 1
                    ]
                    [ Element.column
                        (Element.padding 10
                            :: Element.alignTop
                            :: Border.rounded 5
                            :: Border.width 1
                            :: eventLessAttributes
                            ++ dragAttributes
                        )
                        [ viewSlideImage slide.asset.asset_path
                        , Element.paragraph [ Element.padding 10, Font.size 18 ]
                            [ Element.text "Additional Resources "
                            , Ui.linkButton
                                (Just Core.NewProjectClicked)
                                "Click here to Add aditional"
                            ]
                        , Element.el [] (Element.text ("DEBUG: slide_id = " ++ String.fromInt slide.id))
                        , Element.el [] (Element.text ("DEBUG: Slide position  = " ++ String.fromInt slide.position))
                        , Element.el [] (Element.text ("DEBUG: position in gos = " ++ String.fromInt slide.position_in_gos))
                        , Element.el [] (Element.text ("DEBUG: gos = " ++ String.fromInt slide.gos))
                        , Element.el [ Font.size 8 ] (Element.text (slide.asset.uuid ++ "_" ++ slide.asset.name))
                        ]
                    , Element.textColumn
                        (Background.color Colors.white
                            :: Element.alignTop
                            :: Element.spacing 10
                            :: Element.width
                                (Element.fill
                                    |> Element.maximum 500
                                    |> Element.minimum 200
                                )
                            :: eventLessAttributes
                        )
                        [ Element.el [ Element.centerX, Font.size 14 ] (Element.text "Prompteur")
                        , Element.el
                            [ Border.rounded 5
                            , Border.width 1
                            , Element.padding 5
                            , Font.size 12
                            , Element.scrollbarY
                            , Element.height (Element.px 150)
                            , Element.width (Element.px 200)
                            ]
                            (Element.text slide.prompt)
                        , Ui.editButton (Just promptMsg) "Modifier le prompteur"
                        ]
                    ]
                )


viewSlideImage : String -> Element Core.Msg
viewSlideImage url =
    Element.image [ Element.width (Element.px 200) ] { src = url, description = "One desc" }


configPromptModal : Capsule.EditPrompt -> Dialog.Config Capsule.EditPromptMsg
configPromptModal editPromptContent =
    { closeMessage = Just Capsule.EditPromptCloseDialog
    , maskAttributes = []
    , containerAttributes =
        [ Background.color Colors.white
        , Border.rounded 5
        , Element.centerX
        , Element.padding 10
        , Element.spacing 20
        , Element.width (Element.px 600)
        ]
    , headerAttributes = [ Font.size 24, Element.padding 5 ]
    , bodyAttributes = [ Background.color Colors.grey, Element.padding 20, Element.width Element.fill ]
    , footerAttributes = []
    , header = Just (Element.text "PROMPTER")
    , body = Just (bodyPromptModal editPromptContent)
    , footer = Nothing
    }


bodyPromptModal : Capsule.EditPrompt -> Element Capsule.EditPromptMsg
bodyPromptModal { status, prompt } =
    let
        submitButton =
            case status of
                Status.Sent ->
                    Ui.primaryButtonDisabled "Updating slide..."

                Status.Success () ->
                    Ui.primaryButtonDisabled "Slide updated"

                _ ->
                    Ui.primaryButton (Just Capsule.EditPromptSubmitted) "Update prompt"

        message =
            case status of
                Status.Error () ->
                    Just (Ui.errorModal "Slide update failed")

                Status.Success () ->
                    Just (Ui.successModal "Slide prommpt udpdated")

                _ ->
                    Nothing

        header =
            Element.row [ Element.centerX ] [ Element.text "Edit prompt" ]

        fields =
            [ Input.multiline [ Element.height (Element.px 400) ]
                { label = Input.labelAbove [] (Element.text "Prompteur:")
                , onChange = Capsule.EditPromptTextChanged
                , placeholder = Nothing
                , text = prompt
                , spellcheck = True
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
    Element.column
        [ Element.centerX
        , Element.padding 10
        , Element.spacing 10
        , Element.width Element.fill
        ]
        form


loggedInUploadSlideShowView : Api.Session -> Capsule.UploadForm -> Element Core.Msg
loggedInUploadSlideShowView _ form =
    Element.column
        [ Element.centerX
        , Element.spacing 10
        , Element.padding 10
        , Border.rounded 5
        , Border.width 1
        , Border.color Colors.grey
        ]
        [ Element.text "Choisir une présentation au format PDF"
        , uploadFormView form
        ]


uploadFormView : Capsule.UploadForm -> Element Core.Msg
uploadFormView form =
    Element.column [ Element.centerX, Element.spacing 20 ]
        [ Element.row
            [ Element.spacing 20
            , Element.centerX
            ]
            [ selectFileButton
            , fileNameElement form.file
            , uploadButton
            ]
        ]


fileNameElement : Maybe File -> Element Core.Msg
fileNameElement file =
    Element.text <|
        case file of
            Nothing ->
                "No file selected"

            Just realFile ->
                File.name realFile


selectFileButton : Element Core.Msg
selectFileButton =
    Element.map Core.LoggedInMsg <|
        Element.map LoggedIn.CapsuleMsg <|
            Element.map Capsule.UploadSlideShowMsg <|
                Ui.simpleButton (Just Capsule.UploadSlideShowSelectFileRequested) "Select file"


uploadButton : Element Core.Msg
uploadButton =
    Element.map Core.LoggedInMsg <|
        Element.map LoggedIn.CapsuleMsg <|
            Element.map Capsule.UploadSlideShowMsg <|
                Ui.primaryButton (Just Capsule.UploadSlideShowFormSubmitted) "Upload"


convertAttributes : List (Html.Attribute Capsule.DnDMsg) -> List (Element.Attribute Core.Msg)
convertAttributes attributes =
    List.map
        (\x -> Element.mapAttribute (\y -> Core.LoggedInMsg (LoggedIn.CapsuleMsg (Capsule.DnD y))) x)
        (List.map Element.htmlAttribute attributes)
