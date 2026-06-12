module AscentMasterViewTests exposing (all)

import AscentMasterView
import AscentMasters as AM
import Expect
import Locale
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector exposing (text)


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
        ]
