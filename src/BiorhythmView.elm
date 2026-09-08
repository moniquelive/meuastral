module BiorhythmView exposing (content)

import Chart as C
import Chart.Attributes as CA
import Html as H exposing (Html, div)
import Html.Attributes as HA exposing (class)
import Locale
import Round as R


content : Locale.Locale -> Int -> Html msg
content locale ageInDays =
    let
        localizedCopy =
            Locale.copy locale
    in
    div []
        [ H.p [ class "meuastral-cycle-hint" ] [ H.text localizedCopy.cycleChartHint ]
        , div [ class "meuastral-cycles" ]
            [ bioCard 23 "var(--ma-cycle-physical)" localizedCopy.biorhythmPhysical localizedCopy.biorhythmPhysicalTooltip "🏃" ageInDays
            , bioCard 28 "var(--ma-cycle-emotional)" localizedCopy.biorhythmEmotional localizedCopy.biorhythmEmotionalTooltip "♥" ageInDays
            , bioCard 33 "var(--ma-cycle-intellectual)" localizedCopy.biorhythmIntellectual localizedCopy.biorhythmIntellectualTooltip "🧠" ageInDays
            ]
        ]


bioCard : Float -> String -> String -> String -> String -> Int -> Html msg
bioCard period color label tooltip icon ageInDays =
    H.article [ class "card meuastral-cycle" ]
        [ div [ class "meuastral-cycle__heading" ]
            [ H.h3 []
                [ H.span [ class "biorhythm-icon", HA.style "color" color, HA.attribute "aria-hidden" "true" ] [ H.text icon ]
                , H.text (" " ++ label)
                ]
            , H.strong [ class "meuastral-cycle__value" ] [ H.text (bioValue period ageInDays ++ "%") ]
            ]
        , bioChart period color ageInDays
        , H.p [ class "meuastral-cycle__description" ] [ H.text tooltip ]
        ]


bioChart : Float -> String -> Int -> Html msg
bioChart period color ageInDays =
    C.chart
        [ CA.height 50
        , CA.width 200
        , CA.htmlAttrs
            [ HA.style "background" color
            , HA.attribute "aria-hidden" "true"
            , HA.attribute "focusable" "false"
            ]
        , CA.range [ CA.lowest -30 CA.exactly, CA.highest 0 CA.exactly ]
        , CA.domain [ CA.lowest -1 CA.exactly, CA.highest 1 CA.exactly, CA.pad 2 2 ]
        ]
        [ C.series .x
            [ C.interpolated .y
                [ CA.monotone
                , CA.width 1.5
                , CA.color "white"
                ]
                []
            ]
            (bioSeries period ageInDays)
        ]


bioValue : Float -> Int -> String
bioValue period ageInDays =
    R.round 2 (100 * sin (2.0 * pi * toFloat ageInDays / period))


bioSeries : Float -> Int -> List { x : Float, y : Float }
bioSeries period ageInDays =
    let
        interval =
            30

        bioDay : Float -> { x : Float, y : Float }
        bioDay n =
            { x = n - toFloat ageInDays
            , y = sin (2.0 * pi * n / period)
            }
    in
    List.range (ageInDays - interval) ageInDays
        |> List.map toFloat
        |> List.map bioDay
