-- vim: tw=0


module Main exposing (main)

import Array
import AscentMasterView
import AscentMasters as AM exposing (CosmicRay)
import BiorhythmView
import Browser
import Date exposing (..)
import DatePicker exposing (Msg(..))
import DatePickerProps exposing (pickerProps)
import HoroscopeView
import Html as H exposing (Html, div)
import Html.Attributes as HA exposing (class)
import Http
import Json.Decode as D
import Ports
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
    { today : Maybe Date
    , datePickerData : DatePicker.Model
    , selectedDate : Maybe Date
    , horoscopes : List Horoscope
    , selectedHoroscope : Horoscope
    , ascentMaster : Maybe CosmicRay
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
            ( { today = Nothing
              , datePickerData = datePickerData
              , selectedDate = Nothing
              , horoscopes = []
              , selectedHoroscope = defaultHoroscope
              , ascentMaster = Nothing
              }
            , Cmd.batch
                (Cmd.map DatePickerMsg datePickerInitCmd :: defaultCmds)
            )

        Just userDoB ->
            let
                datePickerData =
                    DatePicker.initFromDate "my-datepicker-id" userDoB
            in
            ( { today = Nothing
              , datePickerData = datePickerData
              , selectedDate = Just userDoB
              , horoscopes = []
              , selectedHoroscope = defaultHoroscope
              , ascentMaster = AM.for_birthday userDoB
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
            let
                updatedModel =
                    { model | today = Just today }

                effectiveDate =
                    selectedDateOrToday updatedModel
            in
            ( { updatedModel
                | selectedHoroscope = horoscopeFromMaybeDate effectiveDate updatedModel.horoscopes
                , ascentMaster = Maybe.andThen AM.for_birthday effectiveDate
              }
            , Cmd.none
            )

        DatePickerMsg datePickerMsg ->
            DatePicker.update datePickerMsg model.datePickerData
                -- set the data returned from datePickerUpdate. Don't discard the command!
                |> (\( data, cmd ) ->
                        let
                            newBirthday =
                                case data.selectedDate of
                                    Just date ->
                                        Just date

                                    Nothing ->
                                        model.today
                        in
                        ( { model
                            | selectedHoroscope = horoscopeFromMaybeDate newBirthday model.horoscopes
                            , datePickerData = data
                            , selectedDate = newBirthday
                            , ascentMaster = Maybe.andThen AM.for_birthday newBirthday
                          }
                        , Cmd.batch
                            [ Cmd.map DatePickerMsg cmd
                            , case data.selectedDate of
                                Just birthday ->
                                    saveDoB birthday

                                Nothing ->
                                    Cmd.none
                            ]
                        )
                   )

        GotHoroscope result ->
            case result of
                Err _ ->
                    ( model, Cmd.none )

                Ok horoscopes ->
                    ( { model
                        | horoscopes = horoscopes
                        , selectedHoroscope = horoscopeFromMaybeDate (selectedDateOrToday model) horoscopes
                      }
                    , Cmd.none
                    )

        SelectHoroscope index ->
            ( { model | selectedHoroscope = horoscopeOrDefault index model.horoscopes }
            , Cmd.none
            )


selectedDateOrToday : Model -> Maybe Date
selectedDateOrToday model =
    case model.selectedDate of
        Just date ->
            Just date

        Nothing ->
            model.today


horoscopeFromMaybeDate : Maybe Date -> List Horoscope -> Horoscope
horoscopeFromMaybeDate maybeDate horoscopes =
    Maybe.map (\date -> horoscopeFromDate date horoscopes) maybeDate
        |> Maybe.withDefault defaultHoroscope


horoscopeFromDate : Date -> List Horoscope -> Horoscope
horoscopeFromDate date horoscopes =
    let
        from =
            Tuple.second >> Tuple.first

        to =
            Tuple.second >> Tuple.second

        horoscopeName tuple =
            Maybe.withDefault "" <|
                Maybe.map Tuple.first tuple
    in
    horoscopeRanges (Date.year date)
        |> List.filter (\e -> Date.isBetween (from e) (to e) date)
        |> List.head
        |> horoscopeName
        |> (\name -> List.filter (\z -> z.id == name) horoscopes)
        |> List.head
        |> Maybe.withDefault defaultHoroscope


horoscopeRanges : Int -> List ( String, ( Date, Date ) )
horoscopeRanges year =
    let
        fcd =
            Date.fromCalendarDate
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
            , ascent_master model
            , bio model

            -- , comments model -- ninho de spam :(
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
            , div []
                [ H.p []
                    [ H.text (footerYear model.today ++ " - ")
                    , H.b [] [ H.text "MeuAstral.com" ]
                    ]
                ]
            ]
        ]



---- VIEW Helpers ----


dob : Model -> Html Msg
dob model =
    H.section sectionAttributes
        [ sectionTitle "Data do meu Aniversário"
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
            [ div [ class "card lg:w-96 bg-neutral shadow-xl" ]
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
    Maybe.map2 (Date.diff Date.Days) (selectedDateOrToday model) model.today
        |> Maybe.withDefault 0


formatDob : Model -> Html Msg
formatDob model =
    selectedDateOrToday model
        |> Maybe.map (Date.format "d/M/y")
        |> Maybe.withDefault "--"
        |> H.text


horoscope : Model -> Html Msg
horoscope model =
    H.section sectionAttributes
        [ sectionTitle "Horóscopo"
        , H.hr [] []
        , HoroscopeView.content SelectHoroscope model.selectedHoroscope model.horoscopes
        ]


ascent_master : Model -> Html Msg
ascent_master model =
    H.section sectionAttributes
        [ sectionTitle "Mestre Ascencionado"
        , H.hr [] []
        , AscentMasterView.content model.ascentMaster
        ]


bio : Model -> Html Msg
bio model =
    H.section sectionAttributes
        [ sectionTitle "Biorritmo"
        , H.hr [] []
        , BiorhythmView.content (ageInDays model)
        ]


comments : Model -> Html Msg
comments _ =
    H.section sectionAttributes
        [ H.hr [] []
        , H.h2 [ class "flex justify-center flex-wrap py-4 gap-4 lg:gap-3 text-xl" ] [ H.text "Curtiu o MeuAstral.com? Deixe um recado, dúvida ou sugestão!" ]
        , H.div [ class "flex justify-center" ]
            [ H.div
                [ class "fb-comments"
                , HA.attribute "data-href" "https://developers.facebook.com/docs/plugins/comments#configurator"
                , HA.attribute "data-numposts" "5"
                , HA.attribute "data-lazy" "true"
                ]
                []
            ]
        ]


sectionAttributes : List (H.Attribute Msg)
sectionAttributes =
    [ class "p-4 grid" ]


sectionTitle : String -> Html Msg
sectionTitle title =
    H.h2 [ class "text-xl" ] [ H.text title ]


footerYear : Maybe Date -> String
footerYear maybeDate =
    Maybe.map (Date.year >> String.fromInt) maybeDate
        |> Maybe.withDefault "--"



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
