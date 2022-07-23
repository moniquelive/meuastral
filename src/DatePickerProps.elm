module DatePickerProps exposing (pickerProps)

import Date exposing (..)
import DatePicker exposing (Msg(..))
import Time exposing (Month(..), Weekday(..))


pickerProps : DatePicker.Props
pickerProps =
    let
        props =
            DatePicker.defaultProps
    in
    { props
        | hideFooter = True
        , daySymbol = ptBRWeekday
        , monthDisplay = ptBRMonth
        , selectedDateDisplay = ptBRSelectedDate
    }


ptBRMonth : Month -> String
ptBRMonth month =
    case month of
        Jan ->
            "Janeiro"

        Feb ->
            "Fevereiro"

        Mar ->
            "Março"

        Apr ->
            "Abril"

        May ->
            "Maio"

        Jun ->
            "Junho"

        Jul ->
            "Julho"

        Aug ->
            "Agosto"

        Sep ->
            "Setembro"

        Oct ->
            "Outubro"

        Nov ->
            "Novembro"

        Dec ->
            "Dezembro"


ptBRWeekday : Weekday -> String
ptBRWeekday day =
    case day of
        Sun ->
            "Dom"

        Mon ->
            "Seg"

        Tue ->
            "Ter"

        Wed ->
            "Qua"

        Thu ->
            "Qui"

        Fri ->
            "Sex"

        Sat ->
            "Sáb"


ptBRShortDate : Date -> String
ptBRShortDate date =
    let
        day =
            Date.day date

        month =
            Date.month date

        weekday =
            Date.weekday date
    in
    ptBRWeekday weekday
        ++ ", "
        ++ String.fromInt day
        ++ " de "
        ++ ptBRMonth month


ptBRSelectedDate : Maybe Date -> Date -> String
ptBRSelectedDate maybeDate date =
    Maybe.map ptBRShortDate maybeDate
        |> Maybe.withDefault (ptBRShortDate date)
