module Main exposing (..)

import Array
import Browser
import Date exposing (..)
import DatePicker exposing (Msg(..))
import DatePickerProps exposing (pickerProps)
import Html
    exposing
        ( Html
        , a
        , article
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
        , span
        , text
        )
import Html.Attributes exposing (alt, attribute, class, href, src, target)
import Html.Events exposing (onClick)
import Http
import Json.Decode as D
import Task
import Time exposing (Month(..), Weekday(..))



---- MODEL ----


type alias Horoscope =
    { id : String
    , name : String
    , resume : String
    }


defaultHoroscope : Horoscope
defaultHoroscope =
    Horoscope "" "" ""


type alias Model =
    { year : Int
    , datePickerData : DatePicker.Model
    , selectedDate : Maybe Date
    , horoscopes : List Horoscope
    , selectedHoroscope : Horoscope
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
      , horoscopes = []
      , selectedHoroscope = defaultHoroscope
      }
    , Cmd.batch
        [ Cmd.map DatePickerMsg datePickerInitCmd
        , whatYearIsIt |> Task.perform GotYear
        , Http.get
            { url = "https://www.terra.com.br/feeder/horoscopo/card-sign-pt?type=json&country=br&jsonp=false"
            , expect = Http.expectJson GotHoroscope horoscopeDecoder
            }
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
    | GotHoroscope (Result Http.Error (List Horoscope))
    | SelectHoroscope Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotYear yyyy ->
            ( { model | year = yyyy }, Cmd.none )

        DatePickerMsg datePickerMsg ->
            DatePicker.update datePickerMsg model.datePickerData
                -- set the data returned from datePickerUpdate. Don't discard the command!
                |> (\( data, cmd ) ->
                        ( { model | selectedHoroscope = horoscopeFromDate data.selectedDate model.horoscopes, datePickerData = data, selectedDate = data.selectedDate }
                        , Cmd.map DatePickerMsg cmd
                        )
                   )

        GotHoroscope result ->
            case result of
                Err _ ->
                    ( model, Cmd.none )

                Ok horoscopes ->
                    ( { model | selectedHoroscope = horoscopeOrDefault 0 horoscopes, horoscopes = horoscopes }, Cmd.none )

        SelectHoroscope index ->
            ( { model | selectedHoroscope = horoscopeOrDefault index model.horoscopes }, Cmd.none )


horoscopeFromDate : Maybe Date -> List Horoscope -> Horoscope
horoscopeFromDate date horoscopes =
    case date of
        Nothing ->
            defaultHoroscope

        Just dt ->
            let
                year =
                    Date.year dt

                fcd =
                    Date.fromCalendarDate

                sf =
                    Tuple.second >> Tuple.first

                ss =
                    Tuple.second >> Tuple.second

                dateRanges =
                    [ ( "aquarius", ( fcd year Jan 21, fcd year Feb 19 ) )
                    , ( "pisces", ( fcd year Feb 20, fcd year Mar 20 ) )
                    , ( "aries", ( fcd year Mar 21, fcd year Apr 20 ) )
                    , ( "taurus", ( fcd year Apr 21, fcd year May 21 ) )
                    , ( "gemini", ( fcd year May 22, fcd year Jun 21 ) )
                    , ( "cancer", ( fcd year Jun 22, fcd year Jul 22 ) )
                    , ( "leo", ( fcd year Jul 23, fcd year Aug 21 ) )
                    , ( "virgo", ( fcd year Aug 22, fcd year Sep 23 ) )
                    , ( "libra", ( fcd year Sep 24, fcd year Oct 23 ) )
                    , ( "scorpio", ( fcd year Oct 24, fcd year Nov 22 ) )
                    , ( "sagittarius", ( fcd year Nov 23, fcd year Dec 22 ) )
                    , ( "capricorn", ( fcd year Dec 23, fcd year Dec 31 ) )
                    , ( "capricorn", ( fcd year Jan 1, fcd year Jan 20 ) )
                    ]
            in
            dateRanges
                |> List.filter (\e -> Date.isBetween (sf e) (ss e) dt)
                |> List.head
                |> Maybe.map Tuple.first
                |> Maybe.withDefault ""
                |> (\id -> List.filter (\z -> z.id == id) horoscopes)
                |> List.head
                |> Maybe.withDefault
                    defaultHoroscope


horoscopeOrDefault : Int -> List Horoscope -> Horoscope
horoscopeOrDefault index horoscopes =
    horoscopes
        |> Array.fromList
        |> Array.get index
        |> Maybe.withDefault
            defaultHoroscope



---- VIEW ----


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



---- VIEW Helpers ----


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
    let
        horoscopeView =
            div [ class "card w-full bg-base-100 shadow-xl" ]
                [ article [ class "card-body" ]
                    [ h2 [ class "card-title" ] [ text model.selectedHoroscope.name ]
                    , p [] [ text model.selectedHoroscope.resume ]
                    ]
                ]

        symbolsView =
            model.horoscopes
                |> List.indexedMap
                    (\index h ->
                        a [ onClick (SelectHoroscope index), href "#" ]
                            [ i [ class ("ai " ++ h.id) ] [] ]
                    )
    in
    section sectionAttributes
        [ sectionTitle "Horóscopo"
        , hr [] []
        , div [ class "place-self-center pt-3 w-96 box-content" ]
            [ horoscopeView
            , div [ class "flex justify-center flex-wrap py-4 gap-3 lg:gap-2" ] symbolsView
            ]
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
    [ class "p-4 grid" ]


sectionTitle : String -> Html Msg
sectionTitle title =
    h2 [ class "text-xl" ] [ text title ]



---- JSON Processing ----


horoscopeDecoder : D.Decoder (List Horoscope)
horoscopeDecoder =
    D.field "signs_list"
        (D.list
            (D.map3 Horoscope
                (D.field "id" D.string)
                (D.field "name" D.string)
                (D.field "resume" D.string)
            )
        )
