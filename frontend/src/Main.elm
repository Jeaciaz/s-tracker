port module Main exposing (main)

import Browser exposing (UrlRequest)
import Browser.Navigation as Nav
import Dashboard
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Login
import Data as D
import RemoteData as RD
import Url



-- PORTS


port copyText : String -> Cmd msg


port alert : String -> Cmd msg



-- MAIN


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }



-- MODEL


type PageModel
    = DashboardPage Dashboard.Model
    | LoginPage Login.Model


type alias Model =
    { page : PageModel
    , auth : D.Auth
    , navKey : Nav.Key
    , effectQueue : List (Effect Msg)
    , refetchQueue : List (D.User -> Effect Msg)
    , baseUrl : String
    , url : Url.Url
    }


mapEffectQueue : (msg -> Msg) -> List (Effect msg) -> List (Effect Msg)
mapEffectQueue f =
    List.map (Effect.mapEffect f)



-- INIT


type alias Flags =
    { baseUrl : String
    , tokens : Maybe D.TokenPair
    }


mapInit : (modelA -> modelB) -> (msgA -> msgB) -> ( modelA, List (Effect msgA) ) -> ( modelB, List (Effect msgB) )
mapInit mapModel mapMsg ( modelA, effects ) =
    ( mapModel modelA, List.map (Effect.mapEffect mapMsg) effects )


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init { baseUrl, tokens } url key =
    let
        auth =
            case Maybe.andThen D.tokenPairToUser tokens of
                Just user ->
                    D.LoggedIn user

                Nothing ->
                    D.LoggedOut

        ( model, taskList ) =
            case auth of
                D.LoggedOut ->
                    Login.init baseUrl |> mapInit LoginPage GotLoginMsg

                D.Refreshing ->
                    Login.init baseUrl |> mapInit LoginPage GotLoginMsg

                D.LoggedIn user ->
                    Dashboard.init baseUrl user |> mapInit DashboardPage GotDashboardMsg
    in
    ( { page = model
      , auth = auth
      , navKey = key
      , effectQueue = taskList
      , refetchQueue = []
      , baseUrl = baseUrl
      , url = url
      }
    , Cmd.none
    )
        |> runEffects



-- UPDATE


type Msg
    = GotDashboardMsg Dashboard.Msg
    | GotLoginMsg Login.Msg
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | UserUpdated (Maybe D.User)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        intermediate =
            case ( msg, model.page ) of
                ( LinkClicked urlRequest, _ ) ->
                    case urlRequest of
                        Browser.Internal url ->
                            ( model, Nav.pushUrl model.navKey (Url.toString url) )

                        Browser.External href ->
                            ( model, Nav.load href )

                ( UrlChanged url, _ ) ->
                    ( { model | url = url }, Cmd.none )

                ( GotDashboardMsg pMsg, DashboardPage pModel ) ->
                    let
                        ( dNewModel, dEffectList ) =
                            Dashboard.update pMsg pModel
                    in
                    ( { model
                        | page = DashboardPage dNewModel
                        , effectQueue = model.effectQueue ++ mapEffectQueue GotDashboardMsg dEffectList
                      }
                    , Cmd.none
                    )

                ( GotLoginMsg pMsg, LoginPage pModel ) ->
                    let
                        ( newModel, pEffectList ) =
                            Login.update pMsg pModel
                    in
                    ( { model
                        | page = LoginPage newModel
                        , effectQueue = model.effectQueue ++ mapEffectQueue GotLoginMsg pEffectList
                      }
                    , Cmd.none
                    )

                ( UserUpdated maybeUser, _ ) ->
                    case maybeUser of
                        Just user ->
                            let
                                ( newModel, effectCmd ) =
                                    runGlobalEffect model (Effect.SaveTokens user)
                            in
                            ( { newModel 
                                | auth = D.LoggedIn user 
                                , effectQueue = List.map (\f -> f user) model.refetchQueue
                                , refetchQueue = []
                            }
                            , effectCmd
                            )

                        Nothing ->
                            ( { model | auth = D.LoggedOut, page = LoginPage <| Tuple.first <| Login.init model.baseUrl }, Cmd.none )

                ( _, _ ) ->
                    ( model, Cmd.none )
    in
    runEffects intermediate


runEffects : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
runEffects ( model, cmd ) =
    model.effectQueue
        |> List.foldr
            (\effect ( m, c ) ->
                let
                    ( newM, newC ) =
                        case effect of
                            Effect.Local l ->
                                ( m, Effect.runLocalEffect l )

                            Effect.Global g ->
                                runGlobalEffect m g
                in
                ( newM, Cmd.batch [ newC, c ] )
            )
            ( { model | effectQueue = [] }, cmd )


runGlobalEffect : Model -> Effect.GlobalEffect Msg -> ( Model, Cmd Msg )
runGlobalEffect model effect =
    case effect of
        Effect.CopyText text ->
            ( model, copyText text )

        Effect.Alert text ->
            ( model, alert text )

        Effect.SaveTokens user ->
            ( model, D.saveTokens user )

        Effect.RevalidateToken baseUrl user genMsg ->
            case model.auth of
                D.LoggedIn _ ->
                    ( { model
                        | auth = D.Refreshing
                        , refetchQueue = genMsg :: model.refetchQueue
                      }
                    , Effect.revalidateRequest baseUrl user (RD.toMaybe >> UserUpdated)
                    )

                _ ->
                    ( { model | refetchQueue = genMsg :: model.refetchQueue }, Cmd.none )

        Effect.GotoHomePage user ->
            let
                ( pageModel, pageEffects ) =
                    Dashboard.init model.baseUrl user
            in
            ( { model
                | auth = D.LoggedIn user
                , page = DashboardPage pageModel
                , effectQueue = model.effectQueue ++ List.map (Effect.mapEffect GotDashboardMsg) pageEffects
              }
            , Cmd.none
            )
                |> runEffects



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        pageSub =
            case model.page of
                DashboardPage dModel ->
                    Sub.map GotDashboardMsg <| Dashboard.subscriptions dModel

                LoginPage lModel ->
                    Sub.map GotLoginMsg <| Login.subscriptions lModel
    in
    Sub.batch [ pageSub, D.tokensUpdated UserUpdated ]



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "₪ Tracker"
    , body =
        [ case model.page of
            DashboardPage dModel ->
                Dashboard.view dModel |> Html.map GotDashboardMsg

            LoginPage lModel ->
                Login.view lModel |> Html.map GotLoginMsg
        ]
    }
