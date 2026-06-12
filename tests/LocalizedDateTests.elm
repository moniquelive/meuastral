module LocalizedDateTests exposing (all)

import Date exposing (fromCalendarDate)
import Expect
import Locale
import LocalizedDate
import Test exposing (Test, describe, test)
import Time exposing (Month(..))


all : Test
all =
    describe "LocalizedDate"
        [ test "formats Portuguese numeric dates as day/month/year" <|
            \_ ->
                fromCalendarDate 1977 May 3
                    |> LocalizedDate.numeric (Locale.fromString "pt-BR")
                    |> Expect.equal "3/5/1977"
        , test "formats English numeric dates as month/day/year" <|
            \_ ->
                fromCalendarDate 1977 May 3
                    |> LocalizedDate.numeric (Locale.fromString "en-US")
                    |> Expect.equal "5/3/1977"
        ]
