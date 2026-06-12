-- vim: tw=0


module Main exposing (main)

import AscentMasterView
import AscentMasters as AM exposing (CosmicRay)
import BiorhythmView
import Browser exposing (element)
import Date exposing (Date, Unit(..))
import DatePicker exposing (Msg(..))
import DatePickerProps exposing (pickerProps)
import Dict
import Horoscope exposing (Horoscope, HoroscopeId, defaultHoroscope)
import HoroscopeApi
import HoroscopeRanges
import HoroscopeView
import Html as H exposing (Html, div)
import Html.Attributes as HA exposing (class)
import Http
import Locale
import Ports
import Task
import Time exposing (Month(..), Weekday(..))



---- MODEL ----


type alias Model =
    { today : Maybe Date
    , datePickerData : DatePicker.Model
    , selectedDate : Maybe Date
    , horoscopes : List Horoscope
    , horoscopeStatus : HoroscopeStatus
    , selectedHoroscopeId : Maybe HoroscopeId
    , ascentMaster : Maybe CosmicRay
    , locale : Locale.Locale
    }


type HoroscopeStatus
    = LoadingHoroscope
    | HoroscopeReady
    | HoroscopeUnavailable


type alias Flags =
    { userBirthday : Maybe String
    , locale : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        locale =
            Locale.fromString flags.locale

        defaultCmds =
            [ Date.today |> Task.perform GotToday
            , HoroscopeApi.request locale GotHoroscope
            ]

        userBirthdayResult =
            Maybe.map Date.fromIsoString flags.userBirthday
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
              , horoscopeStatus = LoadingHoroscope
              , selectedHoroscopeId = Nothing
              , ascentMaster = Nothing
              , locale = locale
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
              , horoscopeStatus = LoadingHoroscope
              , selectedHoroscopeId = Nothing
              , ascentMaster = AM.for_birthday userDoB
              , locale = locale
              }
            , Cmd.batch defaultCmds
            )



---- PROGRAM ----


main : Program Flags Model Msg
main =
    element
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
    | SelectHoroscopeId HoroscopeId


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotToday today ->
            let
                newModel =
                    { model | today = Just today }

                effectiveDate =
                    selectedDateOrToday newModel
            in
            ( { newModel
                | selectedHoroscopeId = horoscopeIdForDate effectiveDate
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
                            | selectedHoroscopeId = horoscopeIdForDate newBirthday
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
                    ( { model | horoscopeStatus = HoroscopeUnavailable }, Cmd.none )

                Ok horoscopes ->
                    ( { model
                        | horoscopes = horoscopes
                        , horoscopeStatus =
                            if List.isEmpty horoscopes then
                                HoroscopeUnavailable

                            else
                                HoroscopeReady
                        , selectedHoroscopeId = horoscopeIdForDate (selectedDateOrToday model)
                      }
                    , Cmd.none
                    )

        SelectHoroscopeId horoscopeId ->
            ( { model | selectedHoroscopeId = Just horoscopeId }, Cmd.none )


selectedDateOrToday : Model -> Maybe Date
selectedDateOrToday model =
    case model.selectedDate of
        Just date ->
            Just date

        Nothing ->
            model.today


horoscopeIdForDate : Maybe Date -> Maybe HoroscopeId
horoscopeIdForDate maybeDate =
    Maybe.andThen horoscopeIdFromDate maybeDate


horoscopeIdFromDate : Date -> Maybe HoroscopeId
horoscopeIdFromDate date =
    let
        from =
            Tuple.second >> Tuple.first

        to =
            Tuple.second >> Tuple.second

        horoscopeName tuple =
            Maybe.map Tuple.first tuple
    in
    HoroscopeRanges.ranges (Date.year date)
        |> List.filter (\e -> Date.isBetween (from e) (to e) date)
        |> List.head
        |> horoscopeName


selectedHoroscope : Model -> Horoscope
selectedHoroscope model =
    model.selectedHoroscopeId
        |> Maybe.andThen (\id -> Dict.get id (horoscopeIndex model.horoscopes))
        |> Maybe.withDefault defaultHoroscope


horoscopeIndex : List Horoscope -> Dict.Dict HoroscopeId Horoscope
horoscopeIndex horoscopes =
    Dict.fromList (List.map (\entry -> ( entry.id, entry )) horoscopes)



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
    let
        localizedCopy =
            Locale.copy model.locale
    in
    H.section sectionAttributes
        [ sectionTitle localizedCopy.birthdayTitle
        , H.hr [] []
        , div [ class "flex place-content-center pt-4" ]
            [ DatePicker.view
                model.datePickerData
                (pickerProps model.locale)
                |> H.map DatePickerMsg
            ]
        ]


userInfo : Model -> Html Msg
userInfo model =
    let
        localizedCopy =
            Locale.copy model.locale
    in
    H.section sectionAttributes
        [ div [ class "flex place-content-center" ]
            [ div [ class "card lg:w-96 bg-neutral shadow-xl" ]
                [ div [ class "card-body text-neutral-content" ]
                    [ H.p []
                        [ H.text localizedCopy.bornOnPrefix
                        , H.span [ class "font-bold" ] [ formatDob model ]
                        , H.text localizedCopy.daysMiddle
                        , H.span [ class "font-bold" ] [ daysSince model ]
                        , H.text localizedCopy.daysSuffix
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
    let
        localizedCopy =
            Locale.copy model.locale
    in
    H.section sectionAttributes
        [ sectionTitle localizedCopy.horoscopeTitle
        , H.hr [] []
        , HoroscopeView.content SelectHoroscopeId
            (horoscopeStatusMessage localizedCopy model.horoscopeStatus)
            (selectedHoroscope model)
            model.horoscopes
        ]


ascent_master : Model -> Html Msg
ascent_master model =
    let
        localizedCopy =
            Locale.copy model.locale
    in
    H.section sectionAttributes
        [ sectionTitle localizedCopy.ascentMasterTitle
        , H.hr [] []
        , AscentMasterView.content model.locale model.ascentMaster
        ]


bio : Model -> Html Msg
bio model =
    let
        localizedCopy =
            Locale.copy model.locale
    in
    H.section sectionAttributes
        [ sectionTitle localizedCopy.biorhythmTitle
        , H.hr [] []
        , BiorhythmView.content (ageInDays model)
        ]



-- comments : Model -> Html Msg
-- comments _ =
--     H.section sectionAttributes
--         [ H.hr [] []
--         , H.h2 [ class "flex justify-center flex-wrap py-4 gap-4 lg:gap-3 text-xl" ] [ H.text "Curtiu o MeuAstral.com? Deixe um recado, dúvida ou sugestão!" ]
--         , H.div [ class "flex justify-center" ]
--             [ H.div
--                 [ class "fb-comments"
--                 , HA.attribute "data-href" "https://developers.facebook.com/docs/plugins/comments#configurator"
--                 , HA.attribute "data-numposts" "5"
--                 , HA.attribute "data-lazy" "true"
--                 ]
--                 []
--             ]
--         ]


sectionAttributes : List (H.Attribute Msg)
sectionAttributes =
    [ class "p-4 grid" ]


sectionTitle : String -> Html Msg
sectionTitle title =
    H.h2 [ class "text-xl" ] [ H.text title ]


horoscopeStatusMessage : Locale.Copy -> HoroscopeStatus -> Maybe String
horoscopeStatusMessage localizedCopy status =
    case status of
        LoadingHoroscope ->
            Just localizedCopy.horoscopeLoading

        HoroscopeReady ->
            Nothing

        HoroscopeUnavailable ->
            Just localizedCopy.horoscopeUnavailable


footerYear : Maybe Date -> String
footerYear maybeDate =
    Maybe.map (Date.year >> String.fromInt) maybeDate
        |> Maybe.withDefault "--"


saveDoB : Date -> Cmd msg
saveDoB birthday =
    birthday
        |> Date.toIsoString
        |> Ports.storeDoB
