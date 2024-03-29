port module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Dashboard
import Data as D
import Dict exposing (Dict)
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Login
import RemoteData as RD
import Route
import Settings
import Settings.FunnelForm
import Url



-- PORTS


port copyText : String -> Cmd msg


port alert : String -> Cmd msg


port prompt : ( String, Int ) -> Cmd msg


port promptResult : (( Int, Bool ) -> msg) -> Sub msg



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
    | SettingsPage Settings.Model
    | FunnelFormPage Settings.FunnelForm.Model


type alias Model =
    { page : PageModel
    , auth : D.Auth
    , navKey : Nav.Key
    , effectQueue : List (Effect Msg)
    , refetchQueue : List (D.User -> Effect Msg)
    , baseUrl : String
    , url : Url.Url
    , promptQueue : Dict Int (Effect Msg)
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


getInitPage : String -> D.User -> Url.Url -> ( PageModel, List (Effect Msg) )
getInitPage baseUrl user url =
    let
        route =
            Route.fromUrl url |> Maybe.withDefault Route.Dashboard
    in
    case route of
        Route.Dashboard ->
            Dashboard.init baseUrl user |> mapInit DashboardPage GotDashboardMsg

        Route.Settings ->
            Settings.init baseUrl user |> mapInit SettingsPage GotSettingsMsg

        Route.FunnelForm funnelId ->
            Settings.FunnelForm.init baseUrl user funnelId |> mapInit FunnelFormPage GotFunnelFormMsg


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
                    getInitPage baseUrl user url
    in
    ( { page = model
      , auth = auth
      , navKey = key
      , effectQueue = taskList
      , refetchQueue = []
      , baseUrl = baseUrl
      , url = url
      , promptQueue = Dict.empty
      }
    , Cmd.none
    )
        |> runEffects



-- UPDATE


type Msg
    = GotDashboardMsg Dashboard.Msg
    | GotLoginMsg Login.Msg
    | GotSettingsMsg Settings.Msg
    | GotFunnelFormMsg Settings.FunnelForm.Msg
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | UserUpdated (Maybe D.User)
    | GotPromptResult ( Int, Bool )


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

                ( GotPromptResult ( id, result ), _ ) ->
                    case ( result, Dict.get id model.promptQueue ) of
                        ( True, Just effect ) ->
                            ( { model | promptQueue = Dict.remove id model.promptQueue, effectQueue = effect :: model.effectQueue }, Cmd.none )
                                |> runEffects

                        _ ->
                            ( { model | promptQueue = Dict.remove id model.promptQueue }, Cmd.none )

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

                ( GotSettingsMsg sMsg, SettingsPage sModel ) ->
                    let
                        ( newModel, sEffectList ) =
                            Settings.update sMsg sModel
                    in
                    ( { model | page = SettingsPage newModel, effectQueue = model.effectQueue ++ mapEffectQueue GotSettingsMsg sEffectList }, Cmd.none )

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

                ( GotFunnelFormMsg localMsg, FunnelFormPage localModel ) ->
                    let
                        ( newModel, effectList ) =
                            Settings.FunnelForm.update localMsg localModel
                    in
                    ( { model | page = FunnelFormPage newModel, effectQueue = model.effectQueue ++ mapEffectQueue GotFunnelFormMsg effectList }, Cmd.none )

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

        Effect.Prompt text effectOnConfirm ->
            let
                key =
                    Dict.size model.promptQueue
            in
            ( { model | promptQueue = Dict.insert key effectOnConfirm model.promptQueue }, prompt ( text, key ) )

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

        Effect.GotoRoute user route ->
            let
                packModel mapModel mapFx ( m, fx ) =
                    ( mapModel m, List.map (Effect.mapEffect mapFx) fx )

                ( pageModel, pageEffects ) =
                    case route of
                        Route.Dashboard ->
                            Dashboard.init model.baseUrl user |> packModel DashboardPage GotDashboardMsg

                        Route.Settings ->
                            Settings.init model.baseUrl user |> packModel SettingsPage GotSettingsMsg

                        Route.FunnelForm maybeId ->
                            Settings.FunnelForm.init model.baseUrl user maybeId |> packModel FunnelFormPage GotFunnelFormMsg
            in
            ( { model
                | auth = D.LoggedIn user
                , page = pageModel
                , effectQueue = model.effectQueue ++ pageEffects
              }
            , Route.goto model.navKey route
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

                LoginPage localModel ->
                    Sub.map GotLoginMsg <| Login.subscriptions localModel

                SettingsPage localModel ->
                    Sub.map GotSettingsMsg <| Settings.subscriptions localModel

                FunnelFormPage localModel ->
                    Sub.map GotFunnelFormMsg <| Settings.FunnelForm.subscriptions localModel
    in
    Sub.batch [ pageSub, D.tokensUpdated UserUpdated, promptResult GotPromptResult ]



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "₪ Tracker"
    , body =
        [ case model.page of
            DashboardPage localModel ->
                Dashboard.view localModel |> Html.map GotDashboardMsg

            LoginPage localModel ->
                Login.view localModel |> Html.map GotLoginMsg

            SettingsPage localModel ->
                Settings.view localModel |> Html.map GotSettingsMsg

            FunnelFormPage localModel ->
                Settings.FunnelForm.view localModel |> Html.map GotFunnelFormMsg
        ]
    }
