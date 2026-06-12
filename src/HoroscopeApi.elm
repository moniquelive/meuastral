module HoroscopeApi exposing (decoder, request, url)

import Horoscope exposing (Horoscope)
import Http
import Json.Decode as D
import Locale exposing (Locale)


url : Locale -> String
url locale =
    "/api/horoscope?locale=" ++ Locale.toQueryParam locale


request : Locale -> (Result Http.Error (List Horoscope) -> msg) -> Cmd msg
request locale toMsg =
    Http.get
        { url = url locale
        , expect = Http.expectJson toMsg decoder
        }


decoder : D.Decoder (List Horoscope)
decoder =
    D.field "signs_list"
        (D.list
            (D.map3 Horoscope
                (D.field "id" D.string)
                (D.field "name" D.string)
                (D.field "resume" D.string)
            )
        )
