module Main exposing (..)

import Browser
import Date exposing (..)
import DatePicker exposing (Msg(..))
import DatePickerProps exposing (pickerProps)
import Html
    exposing
        ( Html
        , a
        , b
        , button
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
        , span
        , text
        )
import Html.Attributes exposing (alt, attribute, class, href, src, target)
import Task
import Time exposing (Month(..), Weekday(..))



---- MODEL ----


type alias Model =
    { year : Int
    , datePickerData : DatePicker.Model
    , selectedDate : Maybe Date
    }


init : ( Model, Cmd Msg )
init =
    let
        ( datePickerData, datePickerInitCmd ) =
            DatePicker.init "my-datepicker-id"
    in
    ( { year = 0
      , datePickerData = datePickerData
      , selectedDate = Nothing
      }
    , Cmd.batch
        [ Cmd.map DatePickerMsg datePickerInitCmd
        , whatYearIsIt |> Task.perform GotYear
        ]
    )



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }


whatYearIsIt : Task.Task Never Int
whatYearIsIt =
    Task.map2 Time.toYear Time.here Time.now



---- UPDATE ----


type Msg
    = GotYear Int
    | DatePickerMsg DatePicker.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotYear yyyy ->
            ( { model | year = yyyy }, Cmd.none )

        DatePickerMsg datePickerMsg ->
            DatePicker.update datePickerMsg model.datePickerData
                -- set the data returned from datePickerUpdate. Don't discard the command!
                |> (\( data, cmd ) ->
                        ( { model | datePickerData = data, selectedDate = data.selectedDate }
                        , Cmd.map DatePickerMsg cmd
                        )
                   )


view : Model -> Html Msg
view model =
    div [ class "flex flex-col h-screen overflow-hidden" ]
        [ header [ class "w-full flex justify-center items-center border-b border-grey p-3" ]
            [ img [ class "h-28", src "logo.png", alt "logo" ] [] ]
        , main_ [ class "flex-1 overflow-y-scroll p-4 content-center", attribute "data-theme" "light" ]
            [ dob model
            , userInfo model
            , horoscope model
            , bio model
            , comments model
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


dob : Model -> Html Msg
dob model =
    section sectionAttributes
        [ sectionTitle "Data de Nascimento"
        , hr [] []
        , div [ class "flex place-content-center pt-4" ]
            [ DatePicker.view
                model.datePickerData
                pickerProps
                |> Html.map DatePickerMsg
            ]
        ]


userInfo : Model -> Html Msg
userInfo model =
    section sectionAttributes
        [ div [ class "flex place-content-center" ]
            [ div [ class "card w-96 bg-neutral shadow-xl" ]
                [ div [ class "card-body text-neutral-content" ]
                    [ p []
                        [ text "As pessoas nascidas em "
                        , span [ class "font-bold" ] [ formatDob model ]
                        , text " possuem mais ou menos "
                        , span [ class "font-bold" ] [ daysSince model ]
                        , text " dias de vida."
                        ]
                    ]
                ]
            ]
        ]


daysSince : Model -> Html Msg
daysSince model =
    case model.selectedDate of
        Nothing ->
            text "..."

        Just selectedDate ->
            case model.datePickerData.today of
                Nothing ->
                    text "..."

                Just today ->
                    Date.diff Date.Days selectedDate today
                        |> String.fromInt
                        |> text


formatDob : Model -> Html Msg
formatDob model =
    case model.selectedDate of
        Nothing ->
            text "..."

        Just d ->
            text <| Date.format "d/M/y" d


horoscope : Model -> Html Msg
horoscope model =
    section sectionAttributes
        [ sectionTitle "Horóscopo"
        , hr [] []
        ]


bio : Model -> Html Msg
bio model =
    section sectionAttributes
        [ sectionTitle "Biorritmo"
        , hr [] []
        ]


comments : Model -> Html Msg
comments model =
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
