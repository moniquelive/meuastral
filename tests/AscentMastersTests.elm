module AscentMastersTests exposing (..)

import Array exposing (Array)
import AscentMasters exposing (Archangel(..), Color(..), Master(..))
import Date exposing (Date)
import Expect
import Test exposing (..)
import Time exposing (Month(..))


sumDigits : Test
sumDigits =
    describe "sumDigits"
        [ test "Zero" <| \() -> 0 |> AscentMasters.sumDigits |> Expect.equal 0
        , test "Single digit" <| \() -> 9 |> AscentMasters.sumDigits |> Expect.equal 9
        , test "Regular numbers" <| \() -> 11111 |> AscentMasters.sumDigits |> Expect.equal 5
        , test "Different numbers" <| \() -> 12345 |> AscentMasters.sumDigits |> Expect.equal 15
        ]


rayNumber : Test
rayNumber =
    describe "rayNumber"
        [ test "Ray 5" <| \() -> 1 + 9 + 7 + 7 + 0 + 5 + 0 + 3 |> AscentMasters.rayNumber |> Expect.equal 5
        , test "Ray 2" <| \() -> 1 + 9 + 8 + 2 + 0 + 3 + 3 + 1 |> AscentMasters.rayNumber |> Expect.equal 2
        , test "Ray 7" <| \() -> 1 + 9 + 8 + 2 + 0 + 3 + 2 + 9 |> AscentMasters.rayNumber |> Expect.equal 7
        , test "Ray 1 w/ carry" <| \() -> 1 + 9 + 8 + 2 + 0 + 3 + 2 + 1 |> AscentMasters.rayNumber |> Expect.equal 1
        , test "Ray 2 w/ carry" <| \() -> 1 + 9 + 8 + 2 + 0 + 3 + 2 + 2 |> AscentMasters.rayNumber |> Expect.equal 2
        ]


color_name : Test
color_name =
    describe "color_name"
        [ test "green" <| \_ -> AscentMasters.color_name AscentMasters.Green |> Expect.equal "green" ]


master_to_str : Test
master_to_str =
    describe "master_to_str"
        [ test "El Morya" <| \_ -> AscentMasters.master_name AscentMasters.ElMorya |> Expect.equal "Mestre El Morya" ]


archangel_to_str : Test
archangel_to_str =
    describe "archangel_to_str"
        [ test "Gabriel" <| \_ -> AscentMasters.archangel_name AscentMasters.Gabriel |> Expect.equal "Gabriel" ]


ascent_masters : Test
ascent_masters =
    describe "ascent_masters"
        [ test "known date" <|
            \_ ->
                (AscentMasters.for_birthday <| Date.fromCalendarDate 1977 May 3)
                    |> Expect.equal (Array.get (5 - 1) AscentMasters.rays)
        , test "known date 2" <|
            \_ ->
                (AscentMasters.for_birthday <| Date.fromCalendarDate 1982 Mar 31)
                    |> Expect.equal (Array.get (2 - 1) AscentMasters.rays)
        ]
