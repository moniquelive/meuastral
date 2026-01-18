module BiorhythmView exposing (content)

import Chart as C
import Chart.Attributes as CA
import Html as H exposing (Html, div)
import Html.Attributes as HA exposing (class)
import Round as R


content : Int -> Html msg
content ageInDays =
    div [ class "flex justify-center flex-wrap py-4 gap-4 lg:gap-3" ]
        [ bioCard 23 "hsl(var(--in))" "Físico" "fa-person-running" ageInDays
        , bioCard 28 "hsl(var(--er))" "Emocional" "fa-heart" ageInDays
        , bioCard 33 "hsl(var(--su))" "Intelectual" "fa-brain" ageInDays
        ]


bioCard : Float -> String -> String -> String -> Int -> Html msg
bioCard period color label icon ageInDays =
    div [ class "indicator" ]
        [ H.span [ class "indicator-item badge badge-lg py-3", HA.style "background" color ]
            [ H.text (bioValue period ageInDays ++ "%") ]
        , div [ class "card card-compact w-80 lg:w-96 bg-base-100 shadow-xl" ]
            [ bioChart period color ageInDays
            , div [ class "card-body" ]
                [ H.p [ class "text-center prose" ]
                    [ H.i [ class ("fa-solid " ++ icon ++ " fa-xl"), HA.style "color" color ] []
                    , H.span [] [ H.text " " ]
                    , H.text label
                    ]
                ]
            ]
        ]


bioChart : Float -> String -> Int -> Html msg
bioChart period color ageInDays =
    C.chart
        [ CA.height 50
        , CA.width 200
        , CA.htmlAttrs [ HA.style "background" color ]
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
