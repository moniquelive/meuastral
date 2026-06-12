module LocalizedDate exposing (numeric)

import Date exposing (Date)
import Locale exposing (Locale)


numeric : Locale -> Date -> String
numeric locale date =
    case Locale.toQueryParam locale of
        "en-US" ->
            monthDayYear date

        _ ->
            dayMonthYear date


dayMonthYear : Date -> String
dayMonthYear date =
    [ Date.day date
    , Date.monthNumber date
    , Date.year date
    ]
        |> List.map String.fromInt
        |> String.join "/"


monthDayYear : Date -> String
monthDayYear date =
    [ Date.monthNumber date
    , Date.day date
    , Date.year date
    ]
        |> List.map String.fromInt
        |> String.join "/"
