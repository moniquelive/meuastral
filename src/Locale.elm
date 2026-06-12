module Locale exposing (Copy, Locale, copy, fromString, toQueryParam)


type Locale
    = PtBR
    | EnUS


type alias Copy =
    { birthdayTitle : String
    , bornOnPrefix : String
    , daysMiddle : String
    , daysSuffix : String
    , horoscopeTitle : String
    , horoscopeLoading : String
    , horoscopeUnavailable : String
    , ascentMasterTitle : String
    , biorhythmTitle : String
    }


fromString : String -> Locale
fromString value =
    let
        normalized =
            String.toLower (String.trim value)
    in
    if normalized == "en" || String.startsWith "en-" normalized then
        EnUS

    else
        PtBR


toQueryParam : Locale -> String
toQueryParam locale =
    case locale of
        PtBR ->
            "pt-BR"

        EnUS ->
            "en-US"


copy : Locale -> Copy
copy locale =
    case locale of
        PtBR ->
            { birthdayTitle = "Data do meu Aniversário"
            , bornOnPrefix = "As pessoas nascidas em "
            , daysMiddle = " possuem mais ou menos "
            , daysSuffix = " dias de vida."
            , horoscopeTitle = "Horóscopo"
            , horoscopeLoading = "Carregando horóscopo diário..."
            , horoscopeUnavailable = "O horóscopo diário não está disponível agora. Tente novamente em instantes."
            , ascentMasterTitle = "Mestre Ascencionado"
            , biorhythmTitle = "Biorritmo"
            }

        EnUS ->
            { birthdayTitle = "My Birthday"
            , bornOnPrefix = "People born on "
            , daysMiddle = " have about "
            , daysSuffix = " days of life."
            , horoscopeTitle = "Horoscope"
            , horoscopeLoading = "Loading daily horoscope..."
            , horoscopeUnavailable = "The daily horoscope is unavailable right now. Please try again shortly."
            , ascentMasterTitle = "Ascended Master"
            , biorhythmTitle = "Biorhythm"
            }
