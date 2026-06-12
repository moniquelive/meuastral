module HoroscopeView exposing (content)

import Horoscope exposing (Horoscope, HoroscopeId)
import Html as H exposing (Html, div)
import Html.Attributes as HA exposing (class)
import Html.Events as HE
import Json.Decode as D


content : (HoroscopeId -> msg) -> Maybe String -> Horoscope -> List Horoscope -> Html msg
content onSelect statusMessage selectedHoroscope horoscopes =
    div [ class "place-self-center pt-3 box-content" ]
        (case statusMessage of
            Just message ->
                [ statusCard message ]

            Nothing ->
                [ horoscopeCard selectedHoroscope
                , div [ class "flex justify-center flex-wrap py-4 gap-3 lg:gap-2" ]
                    (horoscopeSymbols onSelect horoscopes)
                ]
        )


statusCard : String -> Html msg
statusCard message =
    div [ class "card lg:w-96 bg-base-100 shadow-xl" ]
        [ H.article [ class "card-body" ]
            [ H.p [] [ H.text message ]
            ]
        ]


horoscopeCard : Horoscope -> Html msg
horoscopeCard horoscopeData =
    div [ class "card lg:w-96 bg-base-100 shadow-xl" ]
        [ H.article [ class "card-body" ]
            [ H.h2 [ class "card-title" ] [ H.text horoscopeData.name ]
            , H.p [] [ H.text horoscopeData.resume ]
            ]
        ]


horoscopeSymbols : (HoroscopeId -> msg) -> List Horoscope -> List (Html msg)
horoscopeSymbols onSelect horoscopes =
    List.map (horoscopeSymbol onSelect) horoscopes


horoscopeSymbol : (HoroscopeId -> msg) -> Horoscope -> Html msg
horoscopeSymbol onSelect horoscopeData =
    H.a
        [ HA.href "#"
        , HE.preventDefaultOn "click" (D.succeed ( onSelect horoscopeData.id, True ))
        ]
        [ H.i [ class ("ai " ++ horoscopeData.id) ] [] ]
