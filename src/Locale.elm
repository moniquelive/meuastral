module Locale exposing (Copy, Locale, copy, fromString, toQueryParam)


type Locale
    = PtBR
    | EnUS


type alias Copy =
    { birthdayTitle : String
    , changeBirthdayLabel : String
    , bornOnPrefix : String
    , daysMiddle : String
    , daysSuffix : String
    , horoscopeTitle : String
    , horoscopeLoading : String
    , horoscopeUnavailable : String
    , ascentMasterTitle : String
    , archangelPrefix : String
    , biorhythmTitle : String
    , biorhythmPhysical : String
    , biorhythmPhysicalTooltip : String
    , biorhythmEmotional : String
    , biorhythmEmotionalTooltip : String
    , biorhythmIntellectual : String
    , biorhythmIntellectualTooltip : String
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
            , changeBirthdayLabel = "Alterar data"
            , bornOnPrefix = "As pessoas nascidas em "
            , daysMiddle = " possuem mais ou menos "
            , daysSuffix = " dias de vida."
            , horoscopeTitle = "Horóscopo"
            , horoscopeLoading = "Carregando horóscopo diário..."
            , horoscopeUnavailable = "O horóscopo diário não está disponível agora. Tente novamente em instantes."
            , ascentMasterTitle = "Mestre Ascencionado"
            , archangelPrefix = "Arcanjo "
            , biorhythmTitle = "Biorritmo"
            , biorhythmPhysical = "Físico"
            , biorhythmPhysicalTooltip = "Indica energia vital, disposição e ritmos do corpo."
            , biorhythmEmotional = "Emocional"
            , biorhythmEmotionalTooltip = "Indica sensibilidade, humor e equilíbrio afetivo."
            , biorhythmIntellectual = "Intelectual"
            , biorhythmIntellectualTooltip = "Indica clareza mental, foco e raciocínio."
            }

        EnUS ->
            { birthdayTitle = "My Birthday"
            , changeBirthdayLabel = "Change date"
            , bornOnPrefix = "People born on "
            , daysMiddle = " have about "
            , daysSuffix = " days of life."
            , horoscopeTitle = "Horoscope"
            , horoscopeLoading = "Loading daily horoscope..."
            , horoscopeUnavailable = "The daily horoscope is unavailable right now. Please try again shortly."
            , ascentMasterTitle = "Ascended Master"
            , archangelPrefix = "Archangel "
            , biorhythmTitle = "Biorhythm"
            , biorhythmPhysical = "Physical"
            , biorhythmPhysicalTooltip = "Shows physical energy, vitality, and body rhythms."
            , biorhythmEmotional = "Emotional"
            , biorhythmEmotionalTooltip = "Shows sensitivity, mood, and emotional balance."
            , biorhythmIntellectual = "Intellectual"
            , biorhythmIntellectualTooltip = "Shows mental clarity, focus, and reasoning."
            }
