module BiorhythmViewTests exposing (all)

import BiorhythmView
import Locale
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector exposing (text)


all : Test
all =
    describe "BiorhythmView"
        [ test "renders Portuguese cycle labels by default" <|
            \_ ->
                BiorhythmView.content (Locale.fromString "pt-BR") 0
                    |> Query.fromHtml
                    |> Query.has [ text "Físico", text "Emocional", text "Intelectual" ]
        , test "renders English cycle labels for English locale" <|
            \_ ->
                BiorhythmView.content (Locale.fromString "en-US") 0
                    |> Query.fromHtml
                    |> Query.has [ text "Physical", text "Emotional", text "Intellectual" ]
        , test "renders Portuguese cycle explanations by default" <|
            \_ ->
                BiorhythmView.content (Locale.fromString "pt-BR") 0
                    |> Query.fromHtml
                    |> Query.has
                        [ text "Indica energia vital, disposição e ritmos do corpo."
                        , text "Indica sensibilidade, humor e equilíbrio afetivo."
                        , text "Indica clareza mental, foco e raciocínio."
                        ]
        , test "renders English cycle explanations for English locale" <|
            \_ ->
                BiorhythmView.content (Locale.fromString "en-US") 0
                    |> Query.fromHtml
                    |> Query.has
                        [ text "Shows physical energy, vitality, and body rhythms."
                        , text "Shows sensitivity, mood, and emotional balance."
                        , text "Shows mental clarity, focus, and reasoning."
                        ]
        ]
