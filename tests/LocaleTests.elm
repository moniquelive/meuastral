module LocaleTests exposing (all)

import Expect
import Locale
import Test exposing (Test, describe, test)


all : Test
all =
    describe "Locale"
        [ test "unknown locales fall back to Portuguese" <|
            \_ ->
                Locale.fromString "fr-FR"
                    |> Locale.toQueryParam
                    |> Expect.equal "pt-BR"
        , test "English browser locales resolve to English" <|
            \_ ->
                Locale.fromString "en-GB"
                    |> Locale.toQueryParam
                    |> Expect.equal "en-US"
        ]
