module Acquisition.Views exposing (subscriptions, view)

import Acquisition.Types as Acquisition
import Api
import Core.Types as Core
import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import FontAwesome
import Html
import Html.Attributes
import Keyboard
import LoggedIn.Types as LoggedIn
import Preparation.Views as Preparation
import Ui.Colors as Colors
import Ui.Icons
import Ui.Ui as Ui


mkmsg : Acquisition.Model -> Acquisition.Msg -> Core.Msg
mkmsg model msg =
    if model.cameraReady then
        Core.LoggedInMsg (LoggedIn.AcquisitionMsg msg)

    else
        Core.Noop


shortcuts : Acquisition.Model -> Keyboard.RawKey -> Core.Msg
shortcuts model msg =
    let
        raw =
            Keyboard.rawValue msg
    in
    case raw of
        " " ->
            mkmsg model
                (if model.recording then
                    Acquisition.StopRecording

                 else
                    Acquisition.StartRecording
                )

        "ArrowRight" ->
            mkmsg model Acquisition.NextSentence

        _ ->
            Core.Noop


subscriptions : Acquisition.Model -> Sub Core.Msg
subscriptions model =
    Sub.batch
        [ Keyboard.ups (shortcuts model)
        ]


view : Core.Global -> Api.Session -> Acquisition.Model -> Element Core.Msg
view _ _ model =
    let
        attributes =
            Element.height Element.fill
                :: (if model.cameraReady then
                        []

                    else
                        [ Element.htmlAttribute (Html.Attributes.style "visibility" "hidden") ]
                   )
    in
    Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.scrollbarY
        ]
        [ Preparation.leftColumnView model.details (Just model.gos)
        , Element.el (Element.width (Element.fillPortion 6) :: attributes) (centerView model)
        , Element.el (Element.width (Element.fillPortion 1) :: attributes) (rightColumn model)
        ]


centerView : Acquisition.Model -> Element Core.Msg
centerView model =
    Element.column [ Element.width Element.fill, Element.height Element.fill ]
        [ promptView model
        , slideView model
        ]


promptView : Acquisition.Model -> Element Core.Msg
promptView model =
    let
        promptAttributes : List (Element.Attribute Core.Msg)
        promptAttributes =
            [ Font.center
            , Element.centerX
            ]

        currentSlide : Maybe Api.Slide
        currentSlide =
            List.head (List.drop model.currentSlide (Maybe.withDefault [] model.slides))

        nextSlide : Maybe Api.Slide
        nextSlide =
            List.head (List.drop (model.currentSlide + 1) (Maybe.withDefault [] model.slides))

        getLine : Int -> Api.Slide -> Maybe String
        getLine n x =
            List.head (List.drop n (String.split "\n" x.prompt))

        currentSentence : Maybe String
        currentSentence =
            Maybe.withDefault Nothing (Maybe.map (getLine model.currentLine) currentSlide)

        nextSentenceCurrentSlide : Maybe String
        nextSentenceCurrentSlide =
            Maybe.withDefault Nothing (Maybe.map (getLine (model.currentLine + 1)) currentSlide)

        nextSentence : Maybe String
        nextSentence =
            case nextSentenceCurrentSlide of
                Nothing ->
                    Maybe.withDefault Nothing (Maybe.map List.head (Maybe.map (\x -> String.split "\n" x.prompt) nextSlide))

                x ->
                    x

        nextSlideIcon =
            if nextSentenceCurrentSlide == Nothing && nextSentence /= Nothing then
                Element.html
                    (Html.span [ Html.Attributes.style "padding-right" "10px" ]
                        [ FontAwesome.iconWithOptions FontAwesome.arrowCircleRight FontAwesome.Solid [] []
                        ]
                    )

            else
                Element.none

        promptText =
            case currentSentence of
                Just h ->
                    Element.el
                        (Font.size 35 :: Font.color Colors.white :: promptAttributes)
                        (Element.paragraph [] [ Element.text h ])

                _ ->
                    Element.none

        nextPromptText =
            case nextSentence of
                Just h ->
                    Element.row
                        (Font.size 25 :: Font.color Colors.grey :: promptAttributes)
                        [ Element.paragraph [] [ nextSlideIcon, Element.text h ] ]

                _ ->
                    Element.none

        help =
            Element.column [ Element.width Element.fill, Element.height Element.fill, Element.padding 5, Element.spacing 20 ]
                [ Element.paragraph [] [ Element.text "Enregistrer : espace" ]
                , Element.paragraph [] [ Element.text "Finir l'enregistrement : espace" ]
                , Element.paragraph [] [ Element.text "Prochaine ligne : flèche à droite" ]
                ]

        totalSlides =
            List.length (Maybe.withDefault [] model.slides)

        totalLines =
            Maybe.withDefault [] model.slides
                |> List.map (.prompt >> String.lines >> List.length)
                |> List.foldl (+) 0

        -- Some mattpiz wizardry
        currentLine =
            Maybe.withDefault [] model.slides
                |> List.take model.currentSlide
                |> List.map (.prompt >> String.lines >> List.length)
                |> List.foldl (+) (model.currentLine + 1)

        status : Element Core.Msg
        status =
            Input.button []
                { label =
                    Element.column [ Element.padding 5, Border.color Colors.primary, Border.width 2, Border.rounded 5 ]
                        [ if model.recording then
                            Element.row [ Element.width Element.fill, Element.spacing 10 ]
                                [ Element.el
                                    [ Font.size 25, Font.color (Element.rgb255 255 0 0) ]
                                    (Element.row [ Ui.blink ]
                                        [ Ui.Icons.buttonFromIcon FontAwesome.circle
                                        , Element.el [ Element.paddingEach { left = 5, bottom = 0, top = 0, right = 0 } ]
                                            (Element.text "REC")
                                        ]
                                    )
                                ]

                          else
                            Element.row [ Element.width Element.fill, Element.spacing 10 ]
                                [ Element.el
                                    []
                                    (Element.row []
                                        [ Element.el [ Font.size 25 ] (Ui.Icons.buttonFromIcon FontAwesome.stopCircle)
                                        , Element.el [ Element.paddingEach { left = 5, bottom = 0, top = 0, right = 0 } ]
                                            (Element.text "Enregistrement arrêté")
                                        ]
                                    )
                                ]
                        ]
                , onPress =
                    Just
                        (mkmsg model
                            (if model.recording then
                                Acquisition.StopRecording

                             else
                                Acquisition.StartRecording
                            )
                        )
                }

        info =
            Element.row [ Element.padding 10, Element.spacing 30, Element.width Element.fill ]
                [ status
                , Element.el [ Element.width Element.fill ] Element.none
                , Element.text ("Slide " ++ String.fromInt (model.currentSlide + 1) ++ " / " ++ String.fromInt totalSlides)
                , Element.text ("Ligne " ++ String.fromInt currentLine ++ " / " ++ String.fromInt totalLines)
                ]
    in
    Element.row
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ Element.el [ Element.width (Element.fillPortion 1), Element.height Element.fill ] help
        , Element.column
            [ Element.width (Element.fillPortion 3)
            , Element.height Element.fill
            ]
            [ Element.column
                [ Element.width Element.fill
                , Element.height Element.fill
                , Background.color Colors.black
                , Element.padding 10
                , Element.spacing 20
                ]
                [ promptText, nextPromptText ]
            , info
            ]
        , Element.el [ Element.width (Element.fillPortion 1), Element.height Element.fill ] Element.none
        ]


slideView : Acquisition.Model -> Element Core.Msg
slideView model =
    case List.head (List.drop model.currentSlide (Maybe.withDefault [] model.slides)) of
        Just h ->
            Element.el
                [ Input.focusedOnLoad
                , Element.width Element.fill
                , Element.height (Element.fillPortion 2)
                , Element.htmlAttribute
                    (Html.Attributes.style "background"
                        ("center / contain content-box no-repeat url(" ++ h.asset.asset_path ++ ")")
                    )
                ]
                Element.none

        _ ->
            Element.none


rightColumn : Acquisition.Model -> Element Core.Msg
rightColumn model =
    let
        recordView : Int -> Acquisition.Record -> Element Core.Msg
        recordView index record =
            Element.row [ Element.spacing 10 ]
                [ Element.text (String.fromInt (index + 1))
                , Ui.primaryButtonWithTooltip (msg record)
                    (if model.currentVideo == Just index && not model.watchingWebcam then
                        "◼"

                     else
                        "▶"
                    )
                    (if model.currentVideo == Just index && not model.watchingWebcam then
                        "Revenir à la webcam"

                     else
                        "Lire l'enregistrement"
                    )
                , Acquisition.UploadStream (url model.details.capsule.id model.gos) index
                    |> LoggedIn.AcquisitionMsg
                    |> Core.LoggedInMsg
                    |> Just
                    |> (\x -> Ui.primaryButtonWithTooltip x "✔" "Valider cet enregistrement")
                ]

        msg : Acquisition.Record -> Maybe Core.Msg
        msg i =
            if model.recording then
                Nothing

            else if model.currentVideo == Just i.id && not model.watchingWebcam then
                Just (Core.LoggedInMsg (LoggedIn.AcquisitionMsg Acquisition.GoToWebcam))

            else
                Just (Core.LoggedInMsg (LoggedIn.AcquisitionMsg (Acquisition.GoToStream i.id)))
    in
    Element.column [ Element.width Element.fill, Element.height Element.fill ]
        [ Element.html (Html.video [ Html.Attributes.class "wf", Html.Attributes.id elementId ] [])
        , Element.column [ Element.width Element.fill, Element.height Element.fill, Element.padding 10, Element.spacing 10 ]
            [ Element.el [ Element.centerX ] (Element.text "Enregistrements")
            , Element.column
                [ Element.width Element.fill, Element.height Element.fill, Element.scrollbarY ]
                (List.indexedMap recordView (List.reverse model.records))
            ]
        ]



-- CONSTANTS AND UTILS


text : Acquisition.Record -> String
text record =
    if record.new then
        "enregistrement #" ++ String.fromInt record.id

    else
        " ancien enregistrement"


url : Int -> Int -> String
url capsuleId gosId =
    "/api/capsule/" ++ String.fromInt capsuleId ++ "/" ++ String.fromInt gosId ++ "/upload_record"


elementId : String
elementId =
    "video"
