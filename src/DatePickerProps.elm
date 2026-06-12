module DatePickerProps exposing (monthDisplay, pickerProps, selectedDateDisplay, weekdaySymbol)

import Date exposing (Date)
import DatePicker exposing (Msg(..))
import Locale exposing (Locale)
import Time exposing (Month(..), Weekday(..))


pickerProps : Locale -> DatePicker.Props
pickerProps locale =
    let
        props =
            DatePicker.defaultProps
    in
    { props
        | hideFooter = True
        , daySymbol = weekdaySymbol locale
        , monthDisplay = monthDisplay locale
        , selectedDateDisplay = selectedDateDisplay locale
    }


monthDisplay : Locale -> Month -> String
monthDisplay locale month =
    case Locale.toQueryParam locale of
        "en-US" ->
            enUSMonth month

        _ ->
            ptBRMonth month


weekdaySymbol : Locale -> Weekday -> String
weekdaySymbol locale weekday =
    case Locale.toQueryParam locale of
        "en-US" ->
            enUSWeekday weekday

        _ ->
            ptBRWeekday weekday


selectedDateDisplay : Locale -> Maybe Date -> Date -> String
selectedDateDisplay locale maybeDate date =
    Maybe.map (shortDate locale) maybeDate
        |> Maybe.withDefault (shortDate locale date)


shortDate : Locale -> Date -> String
shortDate locale date =
    case Locale.toQueryParam locale of
        "en-US" ->
            enUSShortDate date

        _ ->
            ptBRShortDate date


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


enUSMonth : Month -> String
enUSMonth month =
    case month of
        Jan ->
            "January"

        Feb ->
            "February"

        Mar ->
            "March"

        Apr ->
            "April"

        May ->
            "May"

        Jun ->
            "June"

        Jul ->
            "July"

        Aug ->
            "August"

        Sep ->
            "September"

        Oct ->
            "October"

        Nov ->
            "November"

        Dec ->
            "December"


ptBRWeekday : Weekday -> String
ptBRWeekday weekday =
    case weekday of
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


enUSWeekday : Weekday -> String
enUSWeekday weekday =
    case weekday of
        Sun ->
            "Sun"

        Mon ->
            "Mon"

        Tue ->
            "Tue"

        Wed ->
            "Wed"

        Thu ->
            "Thu"

        Fri ->
            "Fri"

        Sat ->
            "Sat"


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


enUSShortDate : Date -> String
enUSShortDate date =
    let
        day =
            Date.day date

        month =
            Date.month date

        weekday =
            Date.weekday date
    in
    enUSWeekday weekday
        ++ ", "
        ++ enUSMonth month
        ++ " "
        ++ String.fromInt day
