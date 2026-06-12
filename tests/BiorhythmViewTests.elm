module BiorhythmViewTests exposing (all)

import BiorhythmView
import Html.Attributes as HA
import Locale
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector exposing (attribute, text)


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
        , test "renders Portuguese cycle tooltips by default" <|
            \_ ->
                BiorhythmView.content (Locale.fromString "pt-BR") 0
                    |> Query.fromHtml
                    |> Query.has
                        [ attribute (HA.attribute "data-tip" "Indica energia vital, disposição e ritmos do corpo.")
                        , attribute (HA.attribute "data-tip" "Indica sensibilidade, humor e equilíbrio afetivo.")
                        , attribute (HA.attribute "data-tip" "Indica clareza mental, foco e raciocínio.")
                        ]
        , test "renders English cycle tooltips for English locale" <|
            \_ ->
                BiorhythmView.content (Locale.fromString "en-US") 0
                    |> Query.fromHtml
                    |> Query.has
                        [ attribute (HA.attribute "data-tip" "Shows physical energy, vitality, and body rhythms.")
                        , attribute (HA.attribute "data-tip" "Shows sensitivity, mood, and emotional balance.")
                        , attribute (HA.attribute "data-tip" "Shows mental clarity, focus, and reasoning.")
                        ]
        ]
