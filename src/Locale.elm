module Locale exposing (Copy, Locale, copy, fromString, toQueryParam)


type Locale
    = PtBR
    | EnUS


type alias Copy =
    { birthdayTitle : String
    , changeBirthdayLabel : String
    , rayLabel : String
    , masterTabLabel : String
    , chooseDateAction : String
    , calendarLabel : String
    , cycleChartHint : String
    , chooseBirthdayLabel : String
    , birthdayHint : String
    , birthdayInputLabel : String
    , applyBirthdayLabel : String
    , cancelLabel : String
    , invalidBirthday : String
    , calendarHint : String
    , retryLabel : String
    , chooseSignLabel : String
    , readingDateLabel : String
    , birthdayRequired : String
    , bornOnPrefix : String
    , daysMiddle : String
    , daysSuffix : String
    , horoscopeTitle : String
    , horoscopeLoading : String
    , horoscopeUnavailable : String
    , readingSectionsLabel : String
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
            { birthdayTitle = "Data do meu aniversário"
            , changeBirthdayLabel = "Alterar data"
            , rayLabel = "Raio"
            , masterTabLabel = "Mestre"
            , chooseDateAction = "Escolher data"
            , calendarLabel = "Escolher no calendário"
            , cycleChartHint = "As curvas mostram os últimos 30 dias; os valores são de hoje."
            , chooseBirthdayLabel = "Escolha sua data"
            , birthdayHint = "Sua data fica apenas neste dispositivo."
            , birthdayInputLabel = "Data de nascimento"
            , applyBirthdayLabel = "Usar esta data"
            , cancelLabel = "Fechar"
            , invalidBirthday = "Escolha uma data válida até hoje."
            , calendarHint = "Ou use o calendário abaixo. Toque no ano para mudar mais rápido."
            , retryLabel = "Tentar novamente"
            , chooseSignLabel = "Escolha seu signo"
            , readingDateLabel = "Leitura de"
            , birthdayRequired = "Escolha sua data de nascimento para descobrir esta leitura."
            , bornOnPrefix = "As pessoas nascidas em "
            , daysMiddle = " possuem mais ou menos "
            , daysSuffix = " dias de vida."
            , horoscopeTitle = "Horóscopo"
            , horoscopeLoading = "Carregando horóscopo diário..."
            , horoscopeUnavailable = "O horóscopo diário não está disponível agora. Tente novamente em instantes."
            , readingSectionsLabel = "Seções da consulta do MeuAstral"
            , ascentMasterTitle = "Mestre ascensionado"
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
            , rayLabel = "Ray"
            , masterTabLabel = "Master"
            , chooseDateAction = "Choose date"
            , calendarLabel = "Choose on the calendar"
            , cycleChartHint = "Curves show the last 30 days; values are for today."
            , chooseBirthdayLabel = "Choose your birth date"
            , birthdayHint = "Your date stays on this device."
            , birthdayInputLabel = "Birth date"
            , applyBirthdayLabel = "Use this date"
            , cancelLabel = "Close"
            , invalidBirthday = "Choose a valid date on or before today."
            , calendarHint = "Or use the calendar below. Select the year to change it faster."
            , retryLabel = "Try again"
            , chooseSignLabel = "Choose your sign"
            , readingDateLabel = "Reading for"
            , birthdayRequired = "Choose your birth date to discover this reading."
            , bornOnPrefix = "People born on "
            , daysMiddle = " have about "
            , daysSuffix = " days of life."
            , horoscopeTitle = "Horoscope"
            , horoscopeLoading = "Loading daily horoscope..."
            , horoscopeUnavailable = "The daily horoscope is unavailable right now. Please try again shortly."
            , readingSectionsLabel = "MeuAstral reading sections"
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
