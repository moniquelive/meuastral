module HoroscopeView exposing (content)

import Horoscope exposing (Horoscope, HoroscopeId)
import Html as H exposing (Html, div)
import Html.Attributes as HA exposing (class)
import Html.Events as HE


content : (HoroscopeId -> msg) -> Maybe String -> Horoscope -> List Horoscope -> Html msg
content onSelect statusMessage selectedHoroscope horoscopes =
    div [ class "grid justify-items-center pt-3 box-content min-w-0 w-full" ]
        (case statusMessage of
            Just message ->
                [ statusCard message ]

            Nothing ->
                [ div [ class "meuastral-signs" ]
                    (horoscopeSymbols onSelect selectedHoroscope.id horoscopes)
                , horoscopeCard selectedHoroscope
                ]
        )


statusCard : String -> Html msg
statusCard message =
    div
        [ class "card w-full max-w-96 bg-base-100 shadow-xl"
        , HA.attribute "role" "status"
        ]
        [ H.article [ class "card-body" ]
            [ H.p [] [ H.text message ]
            ]
        ]


horoscopeCard : Horoscope -> Html msg
horoscopeCard horoscopeData =
    div
        [ class "card w-full max-w-96 bg-base-100 shadow-xl"
        , HA.id "horoscope-reading"
        , HA.tabindex -1
        , HA.attribute "aria-live" "polite"
        ]
        [ H.article [ class "card-body" ]
            [ H.h2 [ class "card-title" ] [ H.text horoscopeData.name ]
            , H.p [] [ H.text horoscopeData.resume ]
            ]
        ]


horoscopeSymbols : (HoroscopeId -> msg) -> HoroscopeId -> List Horoscope -> List (Html msg)
horoscopeSymbols onSelect selectedId horoscopes =
    List.map (horoscopeSymbol onSelect selectedId) horoscopes


horoscopeSymbol : (HoroscopeId -> msg) -> HoroscopeId -> Horoscope -> Html msg
horoscopeSymbol onSelect selectedId horoscopeData =
    H.button
        [ class "horoscope-symbol"
        , HA.type_ "button"
        , HA.title horoscopeData.name
        , HA.attribute "aria-label" horoscopeData.name
        , HA.attribute "aria-pressed" (boolAttribute (horoscopeData.id == selectedId))
        , HE.onClick (onSelect horoscopeData.id)
        ]
        [ H.i
            [ class ("ai " ++ horoscopeData.id)
            , HA.attribute "aria-hidden" "true"
            ]
            []
        , H.span [ class "horoscope-symbol__name" ] [ H.text horoscopeData.name ]
        ]


boolAttribute : Bool -> String
boolAttribute value =
    if value then
        "true"

    else
        "false"
