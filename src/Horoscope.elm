module Horoscope exposing (Horoscope, HoroscopeId, defaultHoroscope)


type alias Horoscope =
    { id : String
    , name : String
    , resume : String
    }


type alias HoroscopeId =
    String


defaultHoroscope : Horoscope
defaultHoroscope =
    Horoscope "" "" ""
