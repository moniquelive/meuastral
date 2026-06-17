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
import Html.Events as HE
import Http
import Locale
import LocalizedDate
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
    , activeTab : WidgetTab
    , isDatePickerOpen : Bool
    }


type HoroscopeStatus
    = LoadingHoroscope
    | HoroscopeReady
    | HoroscopeUnavailable


type WidgetTab
    = HoroscopeTab
    | AscentMasterTab
    | BiorhythmTab


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
              , activeTab = HoroscopeTab
              , isDatePickerOpen = False
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
              , activeTab = HoroscopeTab
              , isDatePickerOpen = False
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
    | SelectWidgetTab WidgetTab
    | ToggleDatePicker


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
                            pickedCalendarDay =
                                case datePickerMsg of
                                    DateSelected _ _ ->
                                        model.datePickerData.selectionMode == data.selectionMode

                                    _ ->
                                        False

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
                            , isDatePickerOpen =
                                if pickedCalendarDay then
                                    False

                                else
                                    model.isDatePickerOpen
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

        SelectWidgetTab tab ->
            ( { model | activeTab = tab }, Cmd.none )

        ToggleDatePicker ->
            ( { model | isDatePickerOpen = not model.isDatePickerOpen }, Cmd.none )


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
    div [ class "meuastral-widget min-w-0", HA.attribute "data-theme" "light" ]
        [ dobControl model
        , tabNavigation model
        , widgetTabContent model

        -- , comments model -- ninho de spam :(
        ]



---- VIEW Helpers ----


dobControl : Model -> Html Msg
dobControl model =
    let
        localizedCopy =
            Locale.copy model.locale
    in
    H.section [ class "meuastral-date-control min-w-0" ]
        [ H.button
            [ class "meuastral-date-toggle"
            , HA.type_ "button"
            , HA.attribute "aria-expanded" (boolAttribute model.isDatePickerOpen)
            , HE.onClick ToggleDatePicker
            ]
            [ H.span [ class "meuastral-date-toggle__label" ] [ H.text localizedCopy.birthdayTitle ]
            , H.span [ class "meuastral-date-toggle__value" ] [ formatDob model ]
            , H.span [ class "meuastral-date-toggle__meta" ]
                [ H.text localizedCopy.bornOnPrefix
                , H.span [ class "font-bold" ] [ formatDob model ]
                , H.text localizedCopy.daysMiddle
                , H.span [ class "font-bold" ] [ daysSince model ]
                , H.text localizedCopy.daysSuffix
                ]
            , H.span [ class "meuastral-date-toggle__action" ] [ H.text localizedCopy.changeBirthdayLabel ]
            ]
        , if model.isDatePickerOpen then
            div [ class "meuastral-date-picker" ]
                [ DatePicker.view
                    model.datePickerData
                    (pickerProps model.locale)
                    |> H.map DatePickerMsg
                ]

          else
            H.text ""
        ]


tabNavigation : Model -> Html Msg
tabNavigation model =
    let
        localizedCopy =
            Locale.copy model.locale
    in
    H.nav
        [ class "meuastral-tabs"
        , HA.attribute "role" "tablist"
        , HA.attribute "aria-label" "MeuAstral reading sections"
        ]
        [ tabButton model.activeTab HoroscopeTab localizedCopy.horoscopeTitle
        , tabButton model.activeTab AscentMasterTab localizedCopy.ascentMasterTitle
        , tabButton model.activeTab BiorhythmTab localizedCopy.biorhythmTitle
        ]


tabButton : WidgetTab -> WidgetTab -> String -> Html Msg
tabButton activeTab tab label =
    H.button
        [ class
            (if activeTab == tab then
                "meuastral-tab meuastral-tab--active"

             else
                "meuastral-tab"
            )
        , HA.type_ "button"
        , HA.attribute "role" "tab"
        , HA.attribute "aria-selected" (boolAttribute (activeTab == tab))
        , HE.onClick (SelectWidgetTab tab)
        ]
        [ H.text label ]


widgetTabContent : Model -> Html Msg
widgetTabContent model =
    H.section
        [ class "meuastral-tab-panel min-w-0"
        , HA.attribute "role" "tabpanel"
        ]
        [ case model.activeTab of
            HoroscopeTab ->
                horoscopePanel model

            AscentMasterTab ->
                ascentMasterPanel model

            BiorhythmTab ->
                biorhythmPanel model
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
        |> Maybe.map (LocalizedDate.numeric model.locale)
        |> Maybe.withDefault "--"
        |> H.text


horoscopePanel : Model -> Html Msg
horoscopePanel model =
    let
        localizedCopy =
            Locale.copy model.locale
    in
    HoroscopeView.content SelectHoroscopeId
        (horoscopeStatusMessage localizedCopy model.horoscopeStatus)
        (selectedHoroscope model)
        model.horoscopes


ascentMasterPanel : Model -> Html Msg
ascentMasterPanel model =
    AscentMasterView.content model.locale model.ascentMaster


biorhythmPanel : Model -> Html Msg
biorhythmPanel model =
    BiorhythmView.content model.locale (ageInDays model)


boolAttribute : Bool -> String
boolAttribute value =
    if value then
        "true"

    else
        "false"



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


horoscopeStatusMessage : Locale.Copy -> HoroscopeStatus -> Maybe String
horoscopeStatusMessage localizedCopy status =
    case status of
        LoadingHoroscope ->
            Just localizedCopy.horoscopeLoading

        HoroscopeReady ->
            Nothing

        HoroscopeUnavailable ->
            Just localizedCopy.horoscopeUnavailable


saveDoB : Date -> Cmd msg
saveDoB birthday =
    birthday
        |> Date.toIsoString
        |> Ports.storeDoB
