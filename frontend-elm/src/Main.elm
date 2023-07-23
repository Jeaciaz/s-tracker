module Main exposing (main)

import Browser
import Date
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as JD
import Json.Encode as JE
import RemoteData as RD
import Task
import Time
import Utils



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { delta : String
    , funnels : RD.WebData Funnels
    , spendings : RD.WebData Spendings
    , tz : Time.Zone
    , baseUrl : String
    }


type alias Funnel =
    { name : String
    , color : String
    , emoji : String
    , remaining : Float
    , limit : Float
    , daily : Float
    , id : String
    }


type alias Funnels =
    List Funnel


type alias Spending =
    { amount : Float
    , timestamp : Int
    , funnelId : String
    }


type alias Spendings =
    List Spending


type alias Flags =
  { baseUrl : String }

init : Flags -> ( Model, Cmd Msg )
init { baseUrl } =
    ( { delta = ""
      , funnels = RD.Loading
      , spendings = RD.Loading
      , tz = Time.utc
      , baseUrl = baseUrl
      }
    , Cmd.batch [ getData baseUrl, Task.perform AdjustTimeZone Time.here ]
    )


type Msg
    = UpdateDelta String
    | FunnelsResponse (RD.WebData Funnels)
    | SpendingsResponse (RD.WebData Spendings)
    | AdjustTimeZone Time.Zone
    | CreateSpending String
    | ReloadData


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateDelta new ->
            ( { model | delta = new }, Cmd.none )

        FunnelsResponse response ->
            ( { model | funnels = response }, Cmd.none )

        SpendingsResponse response ->
            ( { model | spendings = response }, Cmd.none )

        AdjustTimeZone zone ->
            ( { model | tz = zone }, Cmd.none )

        CreateSpending funnelId ->
            ( { model | delta = "" }, Task.perform (\_ -> ReloadData) (Time.now |> Task.andThen (postSpending model.baseUrl model.delta funnelId)) )

        ReloadData ->
            ( { model | funnels = RD.Loading, spendings = RD.Loading }, getData model.baseUrl )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    main_ [ class "px-4 py-8 flex flex-col h-screen dark:bg-slate-700 dark:text-slate-100" ]
        [ h1 [ class "text-4xl" ] [ text "₪ Tracker" ]
        , div [ class "mt-6" ]
            [ viewFunnels model
            , input
                [ class "mt-4 py-2 px-1 rounded border border-slate-300 w-full text-2xl dark:bg-slate-600 dark:border-0"
                , attribute "input-mode" "numeric"
                , value model.delta
                , onInput UpdateDelta
                , placeholder "20.5"
                ]
                []
            , mapWebData model.funnels <|
                \funnels ->
                    div [ class "grid grid-cols-2 mt-4" ] <|
                        List.map
                            (\funnel ->
                                button
                                    [ class "py-2 active:brightness-75"
                                    , style "background-color" funnel.color
                                    , onClick (CreateSpending funnel.id)
                                    ]
                                    [ text funnel.emoji ]
                            )
                            funnels
            ]
        , viewSpendings model
        ]


mapWebData : RD.WebData a -> (a -> Html Msg) -> Html Msg
mapWebData model render =
    case model of
        RD.NotAsked ->
            div [] []

        RD.Loading ->
            div [] []

        RD.Failure _ ->
            div [] [ text "error"]

        RD.Success data ->
            render data


viewFunnels : Model -> Html Msg
viewFunnels model =
    mapWebData model.funnels <|
        \funnels ->
            div [ class "grid grid-cols-12 gap-2 items-end" ]
                (funnels
                    |> List.concatMap
                        (\funnel ->
                            let
                                deltaNum =
                                    Utils.prefixToFloat model.delta |> Maybe.withDefault 0

                                dailyText =
                                    if deltaNum == 0 then
                                        div [ class "pb-1" ] [ text (Utils.formatFloat funnel.daily) ]

                                    else
                                        div [ class "pb-1 flex gap-2 justify-center" ]
                                            [ span [ class "text-red-600 line-through" ] [ text (Utils.formatFloat funnel.daily) ]
                                            , span [] [ text (Utils.formatFloat (funnel.daily - deltaNum)) ]
                                            ]

                                bars =
                                    [ { value = funnel.limit, opacity = 0.33 }
                                    , { value = funnel.remaining, opacity = 0.67 }
                                    ]
                                        |> List.map
                                            (\bar ->
                                                div
                                                    [ class "absolute bottom-0 h-1 rounded"
                                                    , style "background-color" funnel.color
                                                    , style "opacity" (String.fromFloat bar.opacity)
                                                    , style "width" <| String.fromFloat (100 * bar.value / funnel.limit) ++ "%"
                                                    ]
                                                    []
                                            )
                            in
                            [ div [ class "col-span-2 text-sm" ] [ text funnel.name ]
                            , div [ class "col-span-8 text-center text-lg relative" ] (dailyText :: bars)
                            , div [ class "col-span-2 text-sm text-end" ] [ text (String.fromInt (round funnel.remaining)) ]
                            ]
                        )
                )


viewSpendings : Model -> Html Msg
viewSpendings model =
    mapWebData (RD.map2 (\a b -> ( a, b )) model.funnels model.spendings)
        (\( funnels, spendings ) ->
            div [ class "relative grow" ]
                [ div [ class "absolute inset-0 overflow-y-auto flex flex-col-reverse" ]
                    (div [ class "mb-auto" ] []
                        :: List.map
                            (\spending ->
                                let
                                    emoji =
                                        List.foldl (\el acc -> Dict.insert el.id el.emoji acc) Dict.empty funnels
                                            |> Dict.get spending.funnelId
                                            |> Maybe.withDefault ":("

                                    date =
                                        spending.timestamp
                                            |> Time.millisToPosix
                                            |> Date.fromPosix model.tz
                                            |> Date.format "dd.MM.y"

                                    formatTimeUnit unit =
                                        unit |> String.fromInt |> String.padLeft 2 '0'

                                    time =
                                        spending.timestamp
                                            |> Time.millisToPosix
                                            |> (\t -> formatTimeUnit (Time.toMinute model.tz t) ++ ":" ++ formatTimeUnit (Time.toHour model.tz t))

                                    datetime =
                                        time ++ ", " ++ date
                                in
                                div [ class "flex gap-2 py-4 border-b border-slate-300 dark:border-slate-500" ]
                                    [ div [] [ text emoji ]
                                    , div [] [ text (Utils.formatFloat spending.amount) ]
                                    , div [ class "ms-auto" ] [ text datetime ]
                                    ]
                            )
                            spendings
                    )
                ]
        )



getFunnels : String -> Cmd Msg
getFunnels baseUrl =
    Http.get
        { url = baseUrl ++ "/funnel/"
        , expect = Http.expectJson (RD.fromResult >> FunnelsResponse) decodeFunnels
        }


getSpendings : String -> Cmd Msg
getSpendings baseUrl =
    Http.get
        { url = baseUrl ++ "/spending/"
        , expect = Http.expectJson (RD.fromResult >> SpendingsResponse) decodeSpendings
        }


getData : String -> Cmd Msg
getData baseUrl =
    Cmd.batch [ getFunnels baseUrl, getSpendings baseUrl ]


postSpending : String -> String -> String -> Time.Posix -> Task.Task error ()
postSpending baseUrl amount funnelId time =
    Http.task
        { method = "POST"
        , headers = []
        , url = baseUrl ++ "/spending/"
        , body = Http.jsonBody (encodeSpending time amount funnelId)
        , resolver = Http.bytesResolver (\_ -> Result.Ok ())
        , timeout = Nothing
        }


decodeFunnels : JD.Decoder Funnels
decodeFunnels =
    JD.list
        (JD.map7 Funnel
            (JD.field "name" JD.string)
            (JD.field "color" JD.string)
            (JD.field "emoji" JD.string)
            (JD.field "remaining" JD.float)
            (JD.field "limit" JD.float)
            (JD.field "daily" JD.float)
            (JD.field "id" JD.string)
        )


decodeSpendings : JD.Decoder Spendings
decodeSpendings =
    JD.list
        (JD.map3 Spending
            (JD.field "amount" JD.float)
            (JD.field "timestamp" JD.int)
            (JD.field "funnel_id" JD.string)
        )


encodeSpending : Time.Posix -> String -> String -> JE.Value
encodeSpending time amount funnelId =
    JE.object
        [ ( "amount", JE.string amount )
        , ( "timestamp", JE.int (Time.posixToMillis time) )
        , ( "funnel_id", JE.string funnelId )
        ]
