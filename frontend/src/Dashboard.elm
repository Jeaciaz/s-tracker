module Dashboard exposing (Model, Msg, init, subscriptions, update, view)

import Clsx
import Data as D
import Date
import Dict
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icons
import Layout
import RemoteData as RD
import Route
import Time
import Utils



-- MODEL


type alias Model =
    { delta : String
    , funnels : Effect.ResponseData Funnels
    , spendings : Effect.ResponseData D.Spendings
    , tz : Time.Zone
    , baseUrl : String
    , user : D.User
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


init : String -> D.User -> ( Model, List (Effect Msg) )
init baseUrl user =
    ( { delta = ""
      , funnels = RD.Loading
      , spendings = RD.Loading
      , tz = Time.utc
      , baseUrl = baseUrl
      , user = user
      }
    , [ Effect.Local <| Effect.FetchFunnels baseUrl user FunnelsResponse
      , Effect.Local <| Effect.FetchSpendings baseUrl user SpendingsResponse
      ]
    )


type Msg
    = UpdateDelta String
    | FunnelsResponse (Effect.ResponseData Funnels)
    | SpendingsResponse (Effect.ResponseData D.Spendings)
    | AdjustTimeZone Time.Zone
    | CreateSpending String
    | ErrorCreateSpending { amount : Float, funnelId : String } Bool Effect.ResponseError
    | ReloadData
    | GotoSettings
    | PromptDeleteSpending D.Spending
    | SpendingDeleteResponse String (Effect.ResponseData ())


update : Msg -> Model -> ( Model, List (Effect Msg) )
update msg model =
    let
        fetchFunnelsEffect user =
            Effect.Local <| Effect.FetchFunnels model.baseUrl user FunnelsResponse

        fetchSpendingsEffect user =
            Effect.Local <| Effect.FetchSpendings model.baseUrl user SpendingsResponse

        deleteSpendingsEffect id user =
            Effect.Local <| Effect.DeleteSpending model.baseUrl user id (SpendingDeleteResponse id)

        onCreateSpending req shouldRetryOnInvalidToken data =
            case data of
                RD.Failure detail ->
                    ErrorCreateSpending req shouldRetryOnInvalidToken detail

                _ ->
                    ReloadData
    in
    case msg of
        UpdateDelta new ->
            ( { model | delta = new }, [] )

        FunnelsResponse response ->
            case response of
                RD.Failure Effect.InvalidToken ->
                    ( model, [ Effect.Global <| Effect.RevalidateToken model.baseUrl model.user fetchFunnelsEffect ] )

                RD.Failure (Effect.Other detail) ->
                    ( model, [ Effect.Global <| Effect.Alert detail ] )

                _ ->
                    ( { model | funnels = response }, [] )

        SpendingsResponse response ->
            case response of
                RD.Failure Effect.InvalidToken ->
                    ( model, [ Effect.Global <| Effect.RevalidateToken model.baseUrl model.user fetchSpendingsEffect ] )

                RD.Failure (Effect.Other detail) ->
                    ( model, [ Effect.Global <| Effect.Alert detail ] )

                _ ->
                    ( { model | spendings = response }, [] )

        AdjustTimeZone zone ->
            ( { model | tz = zone }, [] )

        CreateSpending funnelId ->
            let
                amount =
                    model.delta
                        |> String.replace "," "."
                        |> String.toFloat
            in
            case amount of
                Just delta ->
                    ( { model | delta = "" }
                    , [ Effect.Local <|
                            Effect.CreateSpending
                                model.baseUrl
                                model.user
                                { amount = delta, funnelId = funnelId }
                                (onCreateSpending { amount = delta, funnelId = funnelId } True)
                      ]
                    )

                Nothing ->
                    ( model, [] )

        ErrorCreateSpending req shouldRetryOnInvalidToken error ->
            case ( error, shouldRetryOnInvalidToken ) of
                ( Effect.InvalidToken, True ) ->
                    ( model
                    , [ Effect.Global <|
                            Effect.RevalidateToken model.baseUrl
                                model.user
                                (\newUser ->
                                    Effect.Local <|
                                        Effect.CreateSpending model.baseUrl newUser req (onCreateSpending req False)
                                )
                      ]
                    )

                ( Effect.InvalidToken, False ) ->
                    ( model, [ Effect.Global <| Effect.Alert "Could not create spending, try again" ] )

                ( Effect.Other detail, _ ) ->
                    ( model
                    , [ Effect.Global <| Effect.Alert detail ]
                    )

        ReloadData ->
            ( { model | funnels = RD.Loading, spendings = RD.Loading }
            , [ fetchFunnelsEffect model.user
              , fetchSpendingsEffect model.user
              ]
            )

        GotoSettings ->
            ( model, [ Effect.Global <| Effect.GotoRoute model.user Route.Settings ] )

        PromptDeleteSpending spending ->
            ( model
            , [ Effect.Global <|
                    Effect.Prompt ("Are you sure you want to delete this spending of " ++ String.fromFloat spending.amount ++ "?")
                        (deleteSpendingsEffect spending.id model.user)
              ]
            )

        SpendingDeleteResponse id response ->
            case response of
                RD.Failure Effect.InvalidToken ->
                    ( model, [ Effect.Global <| Effect.RevalidateToken model.baseUrl model.user (deleteSpendingsEffect id) ] )

                RD.Failure (Effect.Other detail) ->
                    ( model, [ Effect.Global <| Effect.Alert detail ] )

                _ ->
                    ( model, [ fetchSpendingsEffect model.user, fetchFunnelsEffect model.user ] )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    Layout.viewContent
        { headerContent =
            div []
                [ button [ class "p-1", onClick ReloadData, attribute "aria-label" "refresh" ]
                    [ Icons.refresh ]
                , button [ class "p-1", onClick GotoSettings, attribute "aria-label" "go to settings" ]
                    [ Icons.edit ]
                ]
        , content =
            div [ class "flex flex-col gap-4 flex-grow" ]
                [ viewFunnels model
                , input
                    [ class Clsx.input
                    , class "w-full text-2xl"
                    , attribute "inputmode" "numeric"
                    , value model.delta
                    , onInput UpdateDelta
                    , placeholder "20.5"
                    ]
                    []
                , Effect.foldResponse
                    (div [ class Clsx.skeleton, class "h-10" ] [])
                    (\funnels ->
                        div [ class "grid grid-cols-2" ] <|
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
                    )
                    model.funnels
                , viewSpendings model
                ]
        }


viewFunnelsSkeleton : Html msg
viewFunnelsSkeleton =
    div [ class "grid grid-cols-12 gap-4 items-end" ] <|
        List.concat <|
            List.repeat 3
                [ div [ class Clsx.skeleton, class "col-span-2 h-6" ] []
                , div [ class "col-span-8" ]
                    [ div [ class Clsx.skeleton, class "h-4 mb-1 w-20 m-auto" ] []
                    , div [ class Clsx.skeleton, class "h-1" ] []
                    ]
                , div [ class Clsx.skeleton, class "col-span-2 h-6" ] []
                ]


viewFunnels : Model -> Html Msg
viewFunnels model =
    Effect.foldResponse
        viewFunnelsSkeleton
        (\funnels ->
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
        )
        model.funnels


viewSpendingsSkeleton : Html msg
viewSpendingsSkeleton =
    div [] <|
        List.concat <|
            List.repeat 9 <|
                [ div [ class "flex gap-2 py-4 relative" ]
                    [ div [ class Clsx.skeleton, class "h-4 w-4" ] []
                    , div [ class Clsx.skeleton, class "h-4 w-20" ] []
                    , div [ class Clsx.skeleton, class "ms-auto h-4 w-40" ] []
                    , div [ class Clsx.skeleton, class "absolute bottom-0 h-px w-full" ] []
                    ]
                ]


viewSpendings : Model -> Html Msg
viewSpendings model =
    div [ class "relative grow" ]
        [ div [ class "absolute inset-0 overflow-y-auto flex flex-col" ]
            [ Effect.foldResponse
                viewSpendingsSkeleton
                (\( funnels, spendings ) ->
                    div [] <|
                        (List.reverse <|
                            List.map
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
                                                |> (\t -> formatTimeUnit (Time.toHour model.tz t) ++ ":" ++ formatTimeUnit (Time.toMinute model.tz t))

                                        datetime =
                                            time ++ ", " ++ date
                                    in
                                    div
                                        [ class "flex gap-2 py-4 border-b border-slate-300 dark:border-slate-500 active:backdrop-invert backdrop-opacity-10"
                                        , onClick (PromptDeleteSpending spending)
                                        ]
                                        [ div [] [ text emoji ]
                                        , div [] [ text (Utils.formatFloat spending.amount) ]
                                        , div [ class "ms-auto" ] [ text datetime ]
                                        ]
                                )
                                spendings
                        )
                )
                (RD.map2 (\a b -> ( a, b )) model.funnels model.spendings)
            ]
        ]
