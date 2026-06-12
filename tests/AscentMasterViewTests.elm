module AscentMasterViewTests exposing (all)

import AscentMasterView
import AscentMasters as AM
import Expect
import Html.Attributes as HA
import Locale
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector exposing (attribute, text)


all : Test
all =
    describe "AscentMasterView"
        [ test "renders Portuguese card copy by default" <|
            \_ ->
                AscentMasterView.content (Locale.fromString "pt-BR") (Just AM.test_subject)
                    |> Query.fromHtml
                    |> Query.has [ text "Mestre Hilarion", text "Arcanjo Rafael" ]
        , test "renders English card copy for English locale" <|
            \_ ->
                AscentMasterView.content (Locale.fromString "en-US") (Just AM.test_subject)
                    |> Query.fromHtml
                    |> Query.has [ text "Master Hilarion", text "Archangel Raphael" ]
        , test "renders optimized image attributes" <|
            \_ ->
                AscentMasterView.content (Locale.fromString "en-US") (Just AM.test_subject)
                    |> Query.fromHtml
                    |> Query.has
                        [ attribute (HA.src "/5-hilarion.webp")
                        , attribute (HA.alt "Master Hilarion")
                        , attribute (HA.width 512)
                        , attribute (HA.height 512)
                        , attribute (HA.attribute "loading" "lazy")
                        , attribute (HA.attribute "decoding" "async")
                        , attribute (HA.src "/5-arcanjo-rafael.webp")
                        , attribute (HA.alt "Archangel Raphael")
                        ]
        ]
