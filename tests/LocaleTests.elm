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
        , test "Portuguese interface copy uses correct spelling" <|
            \_ ->
                let
                    copy =
                        Locale.copy (Locale.fromString "pt-BR")
                in
                [ copy.birthdayTitle, copy.ascentMasterTitle ]
                    |> Expect.equal [ "Data do meu aniversário", "Mestre ascensionado" ]
        ]
