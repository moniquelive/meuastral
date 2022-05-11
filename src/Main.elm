module Main exposing (..)

import Browser
import Html
    exposing
        ( Html
        , a
        , b
        , div
        , footer
        , h2
        , header
        , hr
        , i
        , img
        , main_
        , p
        , section
        , text
        )
import Html.Attributes exposing (alt, attribute, class, href, src, target)
import Task
import Time



---- MODEL ----


type alias Model =
    { year : Int }


init : ( Model, Cmd Msg )
init =
    ( Model 0, Cmd.none )



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> ( Model 2022, whatYearIsIt |> Task.perform GotYear )
        , update = update
        , subscriptions = always Sub.none
        }


whatYearIsIt : Task.Task Never Int
whatYearIsIt =
    Task.map2 Time.toYear Time.here Time.now



---- UPDATE ----


type Msg
    = GotYear Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotYear yyyy ->
            ( { model | year = yyyy }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div [ class "flex flex-col h-screen overflow-hidden" ]
        [ header [ class "w-full flex justify-center items-center border-b border-grey p-3" ]
            [ img [ class "h-28", src "logo.png", alt "logo" ] [] ]
        , main_ [ class "flex-1 overflow-y-scroll p-4 content-center", attribute "data-theme" "light" ]
            [ dob
            , userInfo
            , horoscope
            , bio
            , comments
            ]
        , footer [ class "w-full border-t border-grey p-4 justify-between items-center flex" ]
            [ div []
                [ a
                    [ class "btn btn-circle mx-2"
                    , href "https://www.facebook.com/meuastral/"
                    , target "_blank"
                    ]
                    [ i [ class "fab fa-facebook-f fa-xl" ] [] ]
                , a
                    [ class "btn btn-circle mx-2"
                    , href "https://twitter.com/MeuAstral_Com"
                    , target "_blank"
                    ]
                    [ i [ class "fab fa-twitter fa-xl" ] [] ]
                ]
            , div [] [ p [] [ text (String.fromInt model.year ++ " - "), b [] [ text "MeuAstral.com" ] ] ]
            ]
        ]


dob : Html Msg
dob =
    section sectionAttributes
        [ sectionTitle "Data de Nascimento"
        , hr [] []
        ]


userInfo : Html Msg
userInfo =
    section sectionAttributes
        [ text "user info" ]


horoscope : Html Msg
horoscope =
    section sectionAttributes
        [ sectionTitle "Horóscopo"
        , hr [] []
        ]


bio : Html Msg
bio =
    section sectionAttributes
        [ sectionTitle "Biorritmo"
        , hr [] []
        ]


comments : Html Msg
comments =
    section sectionAttributes
        [ hr [] []
        , sectionTitle "Curtiu o MeuAstral.com? Deixe um recado, dúvida ou sugestão!"
        ]


sectionAttributes : List (Html.Attribute Msg)
sectionAttributes =
    [ class "p-4" ]


sectionTitle : String -> Html Msg
sectionTitle title =
    h2 [ class "text-xl" ] [ text title ]
