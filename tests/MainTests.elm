module MainTests exposing (all)

import Date
import DatePicker
import Expect
import Main exposing (Msg(..), WidgetTab(..))
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector exposing (text)
import Time exposing (Month(..))


initial : Main.Model
initial =
    Main.init { initialTab = "biorhythm", userBirthday = Nothing, locale = "en" }
        |> Tuple.first
        |> step (GotToday (Date.fromCalendarDate 2026 Sep 8))


step : Main.Msg -> Main.Model -> Main.Model
step msg model =
    Main.update msg model |> Tuple.first


all : Test
all =
    describe "Birthday and reading interactions"
        [ test "first visit asks for a birthday before calculating cycles" <|
            \_ ->
                Main.view initial
                    |> Query.fromHtml
                    |> Query.has [ text "Choose your birth date to discover this reading." ]
        , test "calendar navigation does not choose a birthday or close the picker" <|
            \_ ->
                initial
                    |> step ToggleDatePicker
                    |> step (DatePickerMsg (DatePicker.PreviousMonth (Date.fromCalendarDate 2026 Sep 8)))
                    |> (\model -> ( model.selectedDate, model.isDatePickerOpen ))
                    |> Expect.equal ( Nothing, True )
        , test "direct date entry commits only when applied" <|
            \_ ->
                initial
                    |> step ToggleDatePicker
                    |> step (EditBirthday "1990-06-15")
                    |> (\model -> ( model.selectedDate, (step ApplyBirthday model).selectedDate, (step ApplyBirthday model).isDatePickerOpen ))
                    |> Expect.equal ( Nothing, Just (Date.fromCalendarDate 1990 Jun 15), False )
        , test "future birthday is rejected without updating the reading" <|
            \_ ->
                initial
                    |> step (EditBirthday "2026-09-09")
                    |> step ApplyBirthday
                    |> (\model -> ( model.selectedDate, model.birthdayError ))
                    |> Expect.equal ( Nothing, True )
        , test "invalid birthday is rejected" <|
            \_ ->
                initial
                    |> step (EditBirthday "1990-02-31")
                    |> step ApplyBirthday
                    |> .birthdayError
                    |> Expect.equal True
        , test "closing the form leaves the existing birthday untouched" <|
            \_ ->
                initial
                    |> step (EditBirthday "1990-06-15")
                    |> step ApplyBirthday
                    |> step ToggleDatePicker
                    |> step (EditBirthday "2000-01-01")
                    |> step CloseDatePicker
                    |> .selectedDate
                    |> Expect.equal (Just (Date.fromCalendarDate 1990 Jun 15))
        , test "future stored birthday is ignored when the local date arrives" <|
            \_ ->
                Main.init { initialTab = "biorhythm", userBirthday = Just "2099-01-01", locale = "en" }
                    |> Tuple.first
                    |> step (GotToday (Date.fromCalendarDate 2026 Sep 8))
                    |> .selectedDate
                    |> Expect.equal Nothing
        , test "a late horoscope response preserves a manually chosen sign" <|
            \_ ->
                initial
                    |> step (SelectHoroscopeId "aries")
                    |> step (GotHoroscope (Ok [ { id = "aries", name = "Aries", resume = "A reading." } ]))
                    |> .selectedHoroscopeId
                    |> Expect.equal (Just "aries")
        ]
