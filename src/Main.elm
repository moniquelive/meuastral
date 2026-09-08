-- vim: tw=0


module Main exposing (Model, Msg(..), WidgetTab(..), init, main, update, view)

import AscentMasterView
import AscentMasters as AM exposing (CosmicRay)
import BiorhythmView
import Browser exposing (element)
import Browser.Dom
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
import Json.Decode as Decode
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
    , birthdayInput : String
    , birthdayError : Bool
    , isDatePickerOpen : Bool
    }


type HoroscopeStatus
    = LoadingHoroscope
    | RetryingHoroscope
    | HoroscopeReady
    | HoroscopeUnavailable


type WidgetTab
    = HoroscopeTab
    | AscentMasterTab
    | BiorhythmTab


widgetTabFromString : String -> WidgetTab
widgetTabFromString value =
    case value of
        "biorhythm" ->
            BiorhythmTab

        "master" ->
            AscentMasterTab

        _ ->
            HoroscopeTab


type alias Flags =
    { initialTab : String
    , userBirthday : Maybe String
    , locale : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        locale =
            Locale.fromString flags.locale

        initialTab =
            widgetTabFromString flags.initialTab

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
              , activeTab = initialTab
              , birthdayInput = Maybe.withDefault "" flags.userBirthday
              , birthdayError = False
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
              , activeTab = initialTab
              , birthdayInput = Maybe.withDefault "" flags.userBirthday
              , birthdayError = False
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
    | EditBirthday String
    | ApplyBirthday
    | CloseDatePicker
    | RetryHoroscope
    | FocusFinished (Result Browser.Dom.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotToday today ->
            let
                newModel =
                    { model
                        | today = Just today
                        , selectedDate =
                            model.selectedDate
                                |> Maybe.andThen
                                    (\date ->
                                        if DatePickerProps.canSelectBirthday (Just today) date then
                                            Just date

                                        else
                                            Nothing
                                    )
                    }

                effectiveDate =
                    selectedDateOrToday newModel
            in
            ( { newModel
                | selectedHoroscopeId = preferredHoroscopeId model effectiveDate
                , ascentMaster = Maybe.andThen AM.for_birthday newModel.selectedDate
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
                        in
                        if pickedCalendarDay then
                            case data.selectedDate of
                                Just birthday ->
                                    if DatePickerProps.canSelectBirthday model.today birthday then
                                        applyBirthday birthday { model | datePickerData = data }

                                    else
                                        ( model, Cmd.none )

                                Nothing ->
                                    ( model, Cmd.none )

                        else
                            ( { model | datePickerData = data }, Cmd.map DatePickerMsg cmd )
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
                        , selectedHoroscopeId = preferredHoroscopeId model (selectedDateOrToday model)
                      }
                    , if model.horoscopeStatus == RetryingHoroscope && not (List.isEmpty horoscopes) then
                        Browser.Dom.focus "horoscope-reading" |> Task.attempt FocusFinished

                      else
                        Cmd.none
                    )

        SelectHoroscopeId horoscopeId ->
            ( { model | selectedHoroscopeId = Just horoscopeId }, Cmd.none )

        SelectWidgetTab tab ->
            ( { model | activeTab = tab }, Cmd.none )

        ToggleDatePicker ->
            if model.isDatePickerOpen then
                update CloseDatePicker model

            else
                ( { model | isDatePickerOpen = True, birthdayInput = Maybe.map Date.toIsoString model.selectedDate |> Maybe.withDefault "", birthdayError = False }
                , Browser.Dom.focus "birthday-input" |> Task.attempt FocusFinished
                )

        EditBirthday value ->
            ( { model | birthdayInput = value, birthdayError = False }, Cmd.none )

        ApplyBirthday ->
            case Date.fromIsoString model.birthdayInput of
                Ok birthday ->
                    if DatePickerProps.canSelectBirthday model.today birthday then
                        applyBirthday birthday model

                    else
                        ( { model | birthdayError = True }, Cmd.none )

                Err _ ->
                    ( { model | birthdayError = True }, Cmd.none )

        CloseDatePicker ->
            ( { model | isDatePickerOpen = False }, Browser.Dom.focus "birthday-toggle" |> Task.attempt FocusFinished )

        RetryHoroscope ->
            ( { model | horoscopeStatus = RetryingHoroscope }, HoroscopeApi.request model.locale GotHoroscope )

        FocusFinished _ ->
            ( model, Cmd.none )


applyBirthday : Date -> Model -> ( Model, Cmd Msg )
applyBirthday birthday model =
    ( { model
        | selectedDate = Just birthday
        , selectedHoroscopeId = horoscopeIdForDate (Just birthday)
        , ascentMaster = AM.for_birthday birthday
        , datePickerData = DatePicker.initFromDate "my-datepicker-id" birthday
        , birthdayInput = Date.toIsoString birthday
        , birthdayError = False
        , isDatePickerOpen = False
      }
    , Cmd.batch [ saveDoB birthday, Browser.Dom.focus "birthday-toggle" |> Task.attempt FocusFinished ]
    )


preferredHoroscopeId : Model -> Maybe Date -> Maybe HoroscopeId
preferredHoroscopeId model date =
    case model.selectedHoroscopeId of
        Just sign ->
            Just sign

        Nothing ->
            horoscopeIdForDate date


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
    div [ class "meuastral-widget min-w-0" ]
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
            , HA.id "birthday-toggle"
            , HA.type_ "button"
            , HA.attribute "aria-expanded" (boolAttribute model.isDatePickerOpen)
            , HA.attribute "aria-controls" "meuastral-date-picker"
            , HE.onClick ToggleDatePicker
            ]
            [ H.span [ class "meuastral-date-toggle__label" ] [ H.text localizedCopy.birthdayTitle ]
            , H.span [ class "meuastral-date-toggle__value" ]
                [ if model.selectedDate == Nothing then
                    H.text localizedCopy.chooseBirthdayLabel

                  else
                    formatDob model
                ]
            , H.span [ class "meuastral-date-toggle__meta" ]
                (if model.selectedDate == Nothing then
                    [ H.text localizedCopy.birthdayHint ]

                 else
                    [ daysSince model, H.text localizedCopy.daysSuffix ]
                )
            , H.span [ class "meuastral-date-toggle__action" ]
                [ H.text
                    (if model.isDatePickerOpen then
                        localizedCopy.cancelLabel

                     else if model.selectedDate == Nothing then
                        localizedCopy.chooseDateAction

                     else
                        localizedCopy.changeBirthdayLabel
                    )
                ]
            ]
        , div
            [ HA.id "meuastral-date-picker", HA.hidden (not model.isDatePickerOpen) ]
            (if model.isDatePickerOpen then
                [ H.form
                    [ class "meuastral-date-form"
                    , HE.onSubmit ApplyBirthday
                    , HE.on "keydown"
                        (Decode.field "key" Decode.string
                            |> Decode.andThen
                                (\key ->
                                    if key == "Escape" then
                                        Decode.succeed CloseDatePicker

                                    else
                                        Decode.fail "Not Escape"
                                )
                        )
                    ]
                    [ H.label [ HA.for "birthday-input" ] [ H.text localizedCopy.birthdayInputLabel ]
                    , H.input
                        [ HA.id "birthday-input"
                        , HA.type_ "date"
                        , HA.required True
                        , HA.max (Maybe.map Date.toIsoString model.today |> Maybe.withDefault "")
                        , HA.value model.birthdayInput
                        , HE.onInput EditBirthday
                        , HA.attribute "aria-describedby" "birthday-hint"
                        , HA.attribute "aria-invalid" (boolAttribute model.birthdayError)
                        ]
                        []
                    , H.p [ HA.id "birthday-hint" ]
                        [ H.text
                            (if model.birthdayError then
                                localizedCopy.invalidBirthday

                             else
                                localizedCopy.birthdayHint
                            )
                        ]
                    , div [ class "meuastral-date-form__actions" ]
                        [ H.button [ HA.type_ "submit", class "meuastral-action" ] [ H.text localizedCopy.applyBirthdayLabel ]
                        , H.button [ HA.type_ "button", class "meuastral-action meuastral-action--secondary", HE.onClick CloseDatePicker ] [ H.text localizedCopy.cancelLabel ]
                        ]
                    ]
                , H.details [ class "meuastral-calendar" ]
                    [ H.summary [] [ H.text localizedCopy.calendarLabel ]
                    , H.p [ class "meuastral-calendar-hint" ] [ H.text localizedCopy.calendarHint ]
                    , div [ class "meuastral-date-picker" ]
                        [ DatePicker.view model.datePickerData (pickerProps model.locale model.today) |> H.map DatePickerMsg ]
                    ]
                ]

             else
                []
            )
        ]


tabNavigation : Model -> Html Msg
tabNavigation model =
    let
        localizedCopy =
            Locale.copy model.locale
    in
    H.div
        [ class "meuastral-tabs"
        , HA.attribute "role" "group"
        , HA.attribute "aria-label" localizedCopy.readingSectionsLabel
        ]
        [ tabButton model.activeTab HoroscopeTab localizedCopy.horoscopeTitle
        , tabButton model.activeTab AscentMasterTab localizedCopy.masterTabLabel
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
        , HA.attribute "aria-pressed" (boolAttribute (activeTab == tab))
        , HE.onClick (SelectWidgetTab tab)
        ]
        [ H.text label ]


widgetTabContent : Model -> Html Msg
widgetTabContent model =
    H.section
        [ class "meuastral-tab-panel min-w-0" ]
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
    div [ class "meuastral-horoscope" ]
        [ H.p [ class "meuastral-reading-date" ]
            [ H.text (localizedCopy.readingDateLabel ++ " " ++ (Maybe.map (LocalizedDate.numeric model.locale) model.today |> Maybe.withDefault "…")) ]
        , if model.horoscopeStatus == HoroscopeReady then
            H.p [ class "meuastral-sign-hint" ] [ H.text localizedCopy.chooseSignLabel ]

          else
            H.text ""
        , HoroscopeView.content SelectHoroscopeId
            (horoscopeStatusMessage localizedCopy model.horoscopeStatus)
            (selectedHoroscope model)
            model.horoscopes
        , if model.horoscopeStatus == HoroscopeUnavailable || model.horoscopeStatus == RetryingHoroscope then
            H.button [ HA.type_ "button", class "meuastral-action", HE.onClick RetryHoroscope, HA.disabled (model.horoscopeStatus == RetryingHoroscope) ] [ H.text localizedCopy.retryLabel ]

          else
            H.text ""
        ]


ascentMasterPanel : Model -> Html Msg
ascentMasterPanel model =
    if model.selectedDate == Nothing then
        birthdayPrompt model

    else
        AscentMasterView.content model.locale model.ascentMaster


biorhythmPanel : Model -> Html Msg
biorhythmPanel model =
    if model.selectedDate == Nothing then
        birthdayPrompt model

    else
        BiorhythmView.content model.locale (ageInDays model)


birthdayPrompt : Model -> Html Msg
birthdayPrompt model =
    div [ class "meuastral-empty" ]
        [ H.p [] [ H.text (Locale.copy model.locale).birthdayRequired ]
        , H.button [ HA.type_ "button", class "meuastral-action", HE.onClick ToggleDatePicker ] [ H.text (Locale.copy model.locale).chooseBirthdayLabel ]
        ]


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

        RetryingHoroscope ->
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
