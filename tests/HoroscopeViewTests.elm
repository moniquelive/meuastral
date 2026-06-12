module HoroscopeViewTests exposing (all)

import Expect
import Horoscope exposing (Horoscope)
import HoroscopeView
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector exposing (text)


all : Test
all =
    describe "HoroscopeView"
        [ test "shows a status message instead of a blank horoscope card" <|
            \_ ->
                HoroscopeView.content identity
                    (Just "The daily horoscope is unavailable right now.")
                    emptyHoroscope
                    []
                    |> Query.fromHtml
                    |> Query.has [ text "The daily horoscope is unavailable right now." ]
        , test "shows horoscope content when data is available" <|
            \_ ->
                HoroscopeView.content identity
                    Nothing
                    aries
                    [ aries ]
                    |> Query.fromHtml
                    |> Query.has [ text "Aries", text "Start something new." ]
        ]


emptyHoroscope : Horoscope
emptyHoroscope =
    { id = "", name = "", resume = "" }


aries : Horoscope
aries =
    { id = "aries", name = "Aries", resume = "Start something new." }
