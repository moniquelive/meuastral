module AscentMastersTests exposing (all, all_attributes, for_birthday, ray_number_edge_cases)

import AscentMasters as AM
import Date exposing (fromCalendarDate)
import Expect
import Locale
import Test exposing (Test, describe, test)
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
        , test "English master name" <| \_ -> AM.master_name_for (Locale.fromString "en-US") subject |> Expect.equal "Master Hilarion"
        , test "English archangel name" <| \_ -> AM.archangel_name_for (Locale.fromString "en-US") subject |> Expect.equal "Raphael"
        , test "English master details" <| \_ -> AM.master_details_for (Locale.fromString "en-US") subject |> Expect.equal "Master Hilarion is associated with truth, healing, and clear investigation. In tradition he is linked with the Apostle Paul and with a spiritual sanctuary over the island of Crete."
        , test "English ray details" <| \_ -> AM.ray_details_for (Locale.fromString "en-US") subject |> Expect.equal "The Green Ray represents truth, abundance, and healing. People connected with this ray often feel drawn to research, science, health, medicine, nursing, and healing work."
        ]


for_birthday : Test
for_birthday =
    describe "For Birthday"
        [ test "known date M" <|
            \_ ->
                case fromCalendarDate 1977 May 3 |> AM.for_birthday of
                    Just c ->
                        AM.number c |> Expect.equal "5"

                    Nothing ->
                        Expect.fail "Should not be Nothing"
        , test "known date C" <|
            \_ ->
                case fromCalendarDate 1982 Mar 31 |> AM.for_birthday of
                    Just c ->
                        AM.number c |> Expect.equal "2"

                    Nothing ->
                        Expect.fail "Should not be Nothing"
        ]


ray_number_edge_cases : Test
ray_number_edge_cases =
    describe "Ray number edge cases"
        [ test "sum digits that exceeds 7" <|
            \_ ->
                case fromCalendarDate 1999 Dec 31 |> AM.for_birthday of
                    Just c ->
                        AM.number c |> Expect.equal "1"

                    Nothing ->
                        Expect.fail "Should not be Nothing"
        , test "date that reduces to 1" <|
            \_ ->
                case fromCalendarDate 2000 Jan 1 |> AM.for_birthday of
                    Just c ->
                        AM.number c |> Expect.equal "4"

                    Nothing ->
                        Expect.fail "Should not be Nothing"
        ]


all : Test
all =
    describe "AscentMasters"
        [ all_attributes
        , for_birthday
        , ray_number_edge_cases
        ]
