module HoroscopeView exposing (content)

import Horoscope exposing (Horoscope)
import Html as H exposing (Html, div)
import Html.Attributes as HA exposing (class)
import Html.Events as HE
import Json.Decode as D


content : (Int -> msg) -> Horoscope -> List Horoscope -> Html msg
content onSelect selectedHoroscope horoscopes =
    div [ class "place-self-center pt-3 box-content" ]
        [ horoscopeCard selectedHoroscope
        , div [ class "flex justify-center flex-wrap py-4 gap-3 lg:gap-2" ]
            (horoscopeSymbols onSelect horoscopes)
        ]


horoscopeCard : Horoscope -> Html msg
horoscopeCard horoscopeData =
    div [ class "card lg:w-96 bg-base-100 shadow-xl" ]
        [ H.article [ class "card-body" ]
            [ H.h2 [ class "card-title" ] [ H.text horoscopeData.name ]
            , H.p [] [ H.text horoscopeData.resume ]
            ]
        ]


horoscopeSymbols : (Int -> msg) -> List Horoscope -> List (Html msg)
horoscopeSymbols onSelect horoscopes =
    horoscopes
        |> List.indexedMap (horoscopeSymbol onSelect)


horoscopeSymbol : (Int -> msg) -> Int -> Horoscope -> Html msg
horoscopeSymbol onSelect index horoscopeData =
    H.a
        [ HA.href "#"
        , HE.preventDefaultOn "click" (D.succeed ( onSelect index, True ))
        ]
        [ H.i [ class ("ai " ++ horoscopeData.id) ] [] ]
