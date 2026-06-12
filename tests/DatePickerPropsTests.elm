module DatePickerPropsTests exposing (all)

import Date exposing (fromCalendarDate)
import DatePickerProps
import Expect
import Locale
import Test exposing (Test, describe, test)
import Time exposing (Month(..), Weekday(..))


all : Test
all =
    describe "DatePickerProps"
        [ test "Portuguese month and weekday labels remain the default" <|
            \_ ->
                [ DatePickerProps.monthDisplay (Locale.fromString "pt-BR") Mar
                , DatePickerProps.weekdaySymbol (Locale.fromString "pt-BR") Sat
                ]
                    |> Expect.equal [ "Março", "Sáb" ]
        , test "English month and weekday labels are localized" <|
            \_ ->
                [ DatePickerProps.monthDisplay (Locale.fromString "en-US") Mar
                , DatePickerProps.weekdaySymbol (Locale.fromString "en-US") Sat
                ]
                    |> Expect.equal [ "March", "Sat" ]
        , test "selected date display falls back to the index date" <|
            \_ ->
                DatePickerProps.selectedDateDisplay
                    (Locale.fromString "en-US")
                    Nothing
                    (fromCalendarDate 2026 Jun 12)
                    |> Expect.equal "Fri, June 12"
        , test "selected date display prefers the selected date" <|
            \_ ->
                DatePickerProps.selectedDateDisplay
                    (Locale.fromString "pt-BR")
                    (Just (fromCalendarDate 2026 Jun 12))
                    (fromCalendarDate 2026 Jan 1)
                    |> Expect.equal "Sex, 12 de Junho"
        ]
