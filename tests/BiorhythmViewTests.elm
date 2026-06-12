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
        ]
