module AscentMastersTests exposing (..)

import Array exposing (..)
import AscentMasters as AM
import Date exposing (..)
import Expect
import Test exposing (..)
import Time exposing (Month(..))


subject : AM.CosmicRay
subject =
    AM.test_subject


all_attributes : Test
all_attributes =
    describe "All attributes"
        [ test "Number" <| \_ -> AM.number subject |> Expect.equal "5"
        , test "Color name" <| \_ -> AM.color_name subject |> Expect.equal "green"
        , test "Master name" <| \_ -> (AM.master_name <| subject) |> Expect.equal "Mestre Hilarion"
        , test "Archangel name" <| \_ -> AM.archangel_name subject |> Expect.equal "Rafael"
        ]


for_birthday : Test
for_birthday =
    describe "For Birthday"
        [ test "known date M" <|
            \_ ->
                case Date.fromCalendarDate 1977 May 3 |> AM.for_birthday of
                    Just c ->
                        AM.number c
                            |> Expect.equal "5"

                    Nothing ->
                        Expect.fail "Should not be Nothing"
        , test "known date C" <|
            \_ ->
                case Date.fromCalendarDate 1982 Mar 31 |> AM.for_birthday of
                    Just c ->
                        AM.number c
                            |> Expect.equal "2"

                    Nothing ->
                        Expect.fail "Should not be Nothing"
        ]
