-- vim: tw=0


module Main exposing (..)

import Array
import Browser
import Chart as C
import Chart.Attributes as CA
import Date exposing (..)
import DatePicker exposing (Msg(..))
import DatePickerProps exposing (pickerProps)
import Html as H exposing (Html, div)
import Html.Attributes as HA exposing (class)
import Html.Events as HE
import Http
import Json.Decode as D
import Ports
import Round as R
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


type alias Datum =
    { x : Float
    , y : Float
    }


type alias Model =
    { today : Date
    , datePickerData : DatePicker.Model
    , selectedDate : Date
    , horoscopes : List Horoscope
    , selectedHoroscope : Horoscope
    }


init : Maybe String -> ( Model, Cmd Msg )
init userBirthday =
    let
        defaultCmds =
            [ Date.today |> Task.perform GotToday
            , Http.get
                { url = "https://www.terra.com.br/feeder/horoscopo/card-sign-pt?type=json&country=br&jsonp=false"
                , expect = Http.expectJson GotHoroscope horoscopeDecoder
                }
            ]

        userBirthdayResult =
            Maybe.map Date.fromIsoString userBirthday
                |> Maybe.andThen Result.toMaybe
    in
    case userBirthdayResult of
        Nothing ->
            let
                ( datePickerData, datePickerInitCmd ) =
                    DatePicker.init "my-datepicker-id"
            in
            ( { today = Date.fromRataDie 1
              , datePickerData = datePickerData
              , selectedDate = Date.fromRataDie 1
              , horoscopes = []
              , selectedHoroscope = defaultHoroscope
              }
            , Cmd.batch
                (Cmd.map DatePickerMsg datePickerInitCmd :: defaultCmds)
            )

        Just userDoB ->
            let
                datePickerData =
                    DatePicker.initFromDate "my-datepicker-id" userDoB
            in
            ( { today = userDoB
              , datePickerData = datePickerData
              , selectedDate = userDoB
              , horoscopes = []
              , selectedHoroscope = defaultHoroscope
              }
            , Cmd.batch defaultCmds
            )



---- PROGRAM ----


main : Program (Maybe String) Model Msg
main =
    Browser.element
        { view = view
        , init = \flags -> init flags
        , update = update
        , subscriptions = always Sub.none
        }



---- UPDATE ----


type Msg
    = GotToday Date
    | DatePickerMsg DatePicker.Msg
    | GotHoroscope (Result Http.Error (List Horoscope))
    | SelectHoroscope Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotToday today ->
            ( { model | today = today }, Cmd.none )

        DatePickerMsg datePickerMsg ->
            DatePicker.update datePickerMsg model.datePickerData
                -- set the data returned from datePickerUpdate. Don't discard the command!
                |> (\( data, cmd ) ->
                        let
                            newBirthday =
                                Maybe.withDefault model.today data.selectedDate
                        in
                        ( { model
                            | selectedHoroscope = horoscopeFromDate newBirthday model.horoscopes
                            , datePickerData = data
                            , selectedDate = newBirthday
                          }
                        , Cmd.batch
                            [ Cmd.map DatePickerMsg cmd
                            , saveDoB newBirthday
                            ]
                        )
                   )

        GotHoroscope result ->
            case result of
                Err _ ->
                    Debug.log "got horoscope:" ( model, Cmd.none )

                Ok horoscopes ->
                    ( { model
                        | horoscopes = horoscopes
                        , selectedHoroscope = horoscopeFromDate model.selectedDate horoscopes
                      }
                    , Cmd.none
                    )

        SelectHoroscope index ->
            ( { model | selectedHoroscope = horoscopeOrDefault index model.horoscopes }, Cmd.none )


horoscopeFromDate : Date -> List Horoscope -> Horoscope
horoscopeFromDate date horoscopes =
    let
        year =
            Date.year date

        fcd =
            Date.fromCalendarDate

        from =
            Tuple.second >> Tuple.first

        to =
            Tuple.second >> Tuple.second

        horoscopeName tuple =
            Maybe.withDefault "" <|
                Maybe.map Tuple.first tuple
    in
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
        |> List.filter (\e -> Date.isBetween (from e) (to e) date)
        |> List.head
        |> horoscopeName
        |> (\name -> List.filter (\z -> z.id == name) horoscopes)
        |> List.head
        |> Maybe.withDefault
            defaultHoroscope


horoscopeOrDefault : Int -> List Horoscope -> Horoscope
horoscopeOrDefault index horoscopes =
    horoscopes
        |> Array.fromList
        |> Array.get index
        |> Maybe.withDefault defaultHoroscope



---- VIEW ----


view : Model -> Html Msg
view model =
    div [ class "flex flex-col h-screen overflow-hidden" ]
        [ H.header [ class "w-full flex justify-center items-center border-b border-grey p-3" ]
            [ H.img [ class "h-28", HA.src "logo.png", HA.alt "logo" ] [] ]
        , H.main_ [ class "flex-1 overflow-y-scroll p-4 content-center", HA.attribute "data-theme" "light" ]
            [ dob model
            , userInfo model
            , horoscope model
            , bio model
            , comments model
            ]
        , H.footer [ class "w-full border-t border-grey p-4 justify-between items-center flex" ]
            [ div []
                [ H.a
                    [ class "btn btn-circle mx-2"
                    , HA.href "https://www.facebook.com/meuastral/"
                    , HA.target "_blank"
                    ]
                    [ H.i [ class "fab fa-facebook-f fa-xl" ] [] ]
                , H.a
                    [ class "btn btn-circle mx-2"
                    , HA.href "https://twitter.com/MeuAstral_Com"
                    , HA.target "_blank"
                    ]
                    [ H.i [ class "fab fa-twitter fa-xl" ] [] ]
                ]
            , div [] [ H.p [] [ H.text (String.fromInt (Date.year model.today) ++ " - "), H.b [] [ H.text "MeuAstral.com" ] ] ]
            ]
        ]



---- VIEW Helpers ----


dob : Model -> Html Msg
dob model =
    H.section sectionAttributes
        [ sectionTitle "Data de Nascimento"
        , H.hr [] []
        , div [ class "flex place-content-center pt-4" ]
            [ DatePicker.view
                model.datePickerData
                pickerProps
                |> H.map DatePickerMsg
            ]
        ]


userInfo : Model -> Html Msg
userInfo model =
    H.section sectionAttributes
        [ div [ class "flex place-content-center" ]
            [ div [ class "card w-96 bg-neutral shadow-xl" ]
                [ div [ class "card-body text-neutral-content" ]
                    [ H.p []
                        [ H.text "As pessoas nascidas em "
                        , H.span [ class "font-bold" ] [ formatDob model ]
                        , H.text " possuem mais ou menos "
                        , H.span [ class "font-bold" ] [ daysSince model ]
                        , H.text " dias de vida."
                        ]
                    ]
                ]
            ]
        ]


daysSince : Model -> Html Msg
daysSince model =
    ageInDays model
        |> String.fromInt
        |> H.text


ageInDays : Model -> Int
ageInDays model =
    Date.diff Date.Days model.selectedDate model.today


formatDob : Model -> Html Msg
formatDob model =
    Date.format "d/M/y" model.selectedDate
        |> H.text


horoscope : Model -> Html Msg
horoscope model =
    let
        horoscopeView =
            div [ class "card w-96 bg-base-100 shadow-xl" ]
                [ H.article [ class "card-body" ]
                    [ H.h2 [ class "card-title" ] [ H.text model.selectedHoroscope.name ]
                    , H.p [] [ H.text model.selectedHoroscope.resume ]
                    ]
                ]

        symbolsView =
            model.horoscopes
                |> List.indexedMap
                    (\index h ->
                        H.a [ HE.onClick (SelectHoroscope index), HA.href "#" ]
                            [ H.i [ class ("ai " ++ h.id) ] [] ]
                    )
    in
    H.section sectionAttributes
        [ sectionTitle "Horóscopo"
        , H.hr [] []
        , div [ class "place-self-center pt-3 box-content" ]
            [ horoscopeView
            , div [ class "flex justify-center flex-wrap py-4 gap-3 lg:gap-2" ] symbolsView
            ]
        ]


bio : Model -> Html Msg
bio model =
    let
        val period =
            R.round 2 (100 * sin (2.0 * pi * toFloat (ageInDays model) / period))

        card period color label icon =
            div [ class "indicator" ]
                [ H.span [ class "indicator-item badge badge-lg py-3", HA.style "background" color ] [ H.text <| val period ++ "%" ]
                , div [ class "card card-compact w-96 bg-base-100 shadow-xl" ]
                    [ C.chart
                        [ CA.height 50
                        , CA.width 200
                        , CA.htmlAttrs [ HA.style "background" color ]
                        , CA.range [ CA.lowest -30 CA.exactly, CA.highest 0 CA.exactly ]
                        , CA.domain [ CA.lowest -1 CA.exactly, CA.highest 1 CA.exactly, CA.pad 2 2 ]
                        ]
                        [ C.series .x
                            [ C.interpolated .y
                                [ CA.monotone
                                , CA.width 1.5
                                , CA.color "white"
                                ]
                                []
                            ]
                            (bioSeries period model)
                        ]
                    , div [ class "card-body" ]
                        [ H.p [ class "text-center prose" ]
                            [ H.i [ class <| "fa-solid " ++ icon ++ " fa-xl", HA.style "color" color ] []
                            , H.span [] [ H.text " " ]
                            , H.text label
                            ]
                        ]
                    ]
                ]
    in
    H.section sectionAttributes
        [ sectionTitle "Biorritmo"
        , H.hr [] []
        , div [ class "flex justify-center flex-wrap py-4 gap-4 lg:gap-3" ]
            [ card 23 "hsl(var(--in))" "Físico" "fa-person-running"
            , card 28 "hsl(var(--er))" "Emocional" "fa-heart"
            , card 33 "hsl(var(--su))" "Intelectual" "fa-brain"
            ]
        ]


bioSeries : Float -> Model -> List { x : Float, y : Float }
bioSeries period model =
    let
        interval =
            30

        aid =
            ageInDays model

        bioDay : Float -> { x : Float, y : Float }
        bioDay n =
            { x = n - toFloat aid
            , y = sin (2.0 * pi * n / period)
            }
    in
    List.range (aid - interval) aid
        |> List.map toFloat
        |> List.map bioDay


comments : Model -> Html Msg
comments model =
    H.section sectionAttributes
        [ H.hr [] []
        , H.h2 [ class "flex justify-center flex-wrap py-4 gap-4 lg:gap-3 text-xl" ] [ H.text "Curtiu o MeuAstral.com? Deixe um recado, dúvida ou sugestão!" ]
        , H.div
            [ class "fb-comments"
            , HA.attribute "data-href" "meuastral.com"
            , HA.attribute "data-numposts" "2"
            , HA.attribute "data-width" ""
            ]
            []
        ]


sectionAttributes : List (H.Attribute Msg)
sectionAttributes =
    [ class "p-4 grid" ]


sectionTitle : String -> Html Msg
sectionTitle title =
    H.h2 [ class "text-xl" ] [ H.text title ]



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


saveDoB : Date -> Cmd msg
saveDoB birthday =
    birthday
        |> Date.toIsoString
        |> Ports.storeDoB
