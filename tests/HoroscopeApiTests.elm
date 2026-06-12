module HoroscopeApiTests exposing (all)

import Expect
import HoroscopeApi
import Json.Decode as D
import Locale
import Test exposing (Test, describe, test)


all : Test
all =
    describe "HoroscopeApi"
        [ test "decoder accepts normalized response" <|
            \_ ->
                D.decodeString HoroscopeApi.decoder """{"signs_list":[{"id":"aries","name":"Aries","resume":"A fresh start."}]}"""
                    |> Result.map (List.map .id)
                    |> Expect.equal (Ok [ "aries" ])
        , test "URL uses local endpoint and passes locale" <|
            \_ ->
                HoroscopeApi.url (Locale.fromString "en-US")
                    |> Expect.equal "/api/horoscope?locale=en-US"
        ]
