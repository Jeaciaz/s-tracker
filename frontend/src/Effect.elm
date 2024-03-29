module Effect exposing
    ( Effect(..)
    , GlobalEffect(..)
    , LocalEffect(..)
    , ResponseData
    , ResponseError(..)
    , foldResponse
    , mapEffect
    , mapLocalEffect
    , revalidateRequest
    , runLocalEffect
    )

import Data exposing (User)
import Html exposing (Html, div, text)
import Http
import Json.Decode as JD
import RemoteData as RD
import Route
import Task
import Time
import Utils


type ResponseError
    = InvalidToken
    | Other String


type alias ResponseData res =
    RD.RemoteData ResponseError res


foldResponse : Html msg -> (a -> Html msg) -> ResponseData a -> Html msg
foldResponse renderLoader render model =
    case model of
        RD.NotAsked ->
            div [] []

        RD.Loading ->
            div [] [ renderLoader ]

        RD.Failure _ ->
            div [] [ text "error" ]

        RD.Success data ->
            render data


type HttpMethod
    = Get
    | Post Http.Body
    | Put Http.Body
    | Delete Http.Body


type Effect msgOnSuccess
    = Local (LocalEffect msgOnSuccess)
    | Global (GlobalEffect msgOnSuccess)


type LocalEffect msgOnSuccess
    = FetchFunnels String User (ResponseData Data.Funnels -> msgOnSuccess)
    | FetchSpendings String User (ResponseData Data.Spendings -> msgOnSuccess)
    | GenerateOtpSecret String Data.OtpSecretRequest (ResponseData Data.OtpSecretResponse -> msgOnSuccess)
    | RegisterNewUser String Data.RegisterRequest (ResponseData User -> msgOnSuccess)
    | Login String Data.LoginRequest (ResponseData User -> msgOnSuccess)
    | CreateSpending String User Data.SpendingCreateWithoutTs (ResponseData () -> msgOnSuccess)
    | FetchFunnel String User String (ResponseData Data.Funnel -> msgOnSuccess)
    | UpdateFunnel String User Data.FunnelPut (ResponseData () -> msgOnSuccess)
    | DeleteFunnel String User String (ResponseData () -> msgOnSuccess)
    | CreateFunnel String User Data.FunnelPost (ResponseData String -> msgOnSuccess)
    | DeleteSpending String User String (ResponseData () -> msgOnSuccess)


type GlobalEffect msgOnSuccess
    = CopyText String
    | Alert String
    | Prompt String (Effect msgOnSuccess)
    | SaveTokens User
    | RevalidateToken String User (User -> Effect msgOnSuccess)
    | GotoRoute User Route.Route


type ResponseDecoder response
    = JsonDecoder (JD.Decoder response)
    | StaticValue response


type alias RequestConfig response =
    { method : HttpMethod
    , url : String
    , headers : List Http.Header
    , decoder : ResponseDecoder response
    }


requestTask : RequestConfig res -> Task.Task x (ResponseData res)
requestTask { method, url, headers, decoder } =
    let
        ( methodStr, body ) =
            case method of
                Get ->
                    ( "GET", Http.emptyBody )

                Post body_ ->
                    ( "POST", body_ )

                Put body_ ->
                    ( "PUT", body_ )

                Delete body_ ->
                    ( "DELETE", body_ )
    in
    Http.task
        { method = methodStr
        , headers = headers
        , url = url
        , body = body
        , timeout = Nothing
        , resolver =
            Http.stringResolver
                (\res ->
                    case res of
                        Http.GoodStatus_ _ resText ->
                            case decoder of
                                JsonDecoder actualDecoder ->
                                    resText
                                        |> JD.decodeString actualDecoder
                                        |> Result.mapError (JD.errorToString >> Other)

                                StaticValue value ->
                                    Result.Ok value

                        Http.BadUrl_ url_ ->
                            Result.Err (Http.BadUrl url_ |> Utils.errorToString |> Other)

                        Http.Timeout_ ->
                            Result.Err (Http.Timeout |> Utils.errorToString |> Other)

                        Http.NetworkError_ ->
                            Result.Err (Http.NetworkError |> Utils.errorToString |> Other)

                        Http.BadStatus_ { statusCode } detail ->
                            Result.Err
                                (if statusCode == 403 then
                                    InvalidToken

                                 else
                                    detail
                                        |> JD.decodeString Data.decodeServerError
                                        |> Result.withDefault "Something went wrong"
                                        |> Other
                                )
                )
        }
        |> RD.fromTask


mapLocalEffect : (a -> b) -> LocalEffect a -> LocalEffect b
mapLocalEffect f effect =
    case effect of
        FetchFunnels baseUrl user genMsg ->
            FetchFunnels baseUrl user (genMsg >> f)

        FetchSpendings baseUrl user genMsg ->
            FetchSpendings baseUrl user (genMsg >> f)

        GenerateOtpSecret baseUrl body genMsg ->
            GenerateOtpSecret baseUrl body (genMsg >> f)

        RegisterNewUser baseUrl body genMsg ->
            RegisterNewUser baseUrl body (genMsg >> f)

        Login baseUrl body genMsg ->
            Login baseUrl body (genMsg >> f)

        CreateSpending baseUrl user bodyWithoutTs genMsg ->
            CreateSpending baseUrl user bodyWithoutTs (genMsg >> f)

        FetchFunnel baseUrl user id genMsg ->
            FetchFunnel baseUrl user id (genMsg >> f)

        UpdateFunnel baseUrl user funnel genMsg ->
            UpdateFunnel baseUrl user funnel (genMsg >> f)

        DeleteFunnel baseUrl user funnelId genMsg ->
            DeleteFunnel baseUrl user funnelId (genMsg >> f)

        CreateFunnel baseUrl user funnel genMsg ->
            CreateFunnel baseUrl user funnel (genMsg >> f)

        DeleteSpending baseUrl user spendingId genMsg ->
            DeleteSpending baseUrl user spendingId (genMsg >> f)

mapGlobalEffect : (a -> b) -> GlobalEffect a -> GlobalEffect b
mapGlobalEffect f effect =
    case effect of
        RevalidateToken baseUrl user genEffect ->
            RevalidateToken baseUrl user (genEffect >> mapEffect f)

        CopyText s ->
            CopyText s

        Alert s ->
            Alert s

        Prompt text effectOnConfirm ->
            Prompt text (mapEffect f effectOnConfirm)

        SaveTokens user ->
            SaveTokens user

        GotoRoute user route ->
            GotoRoute user route


mapEffect : (a -> b) -> Effect a -> Effect b
mapEffect f effect =
    case effect of
        Local l ->
            Local (mapLocalEffect f l)

        Global g ->
            Global (mapGlobalEffect f g)


runLocalEffect : LocalEffect msgOnSuccess -> Cmd msgOnSuccess
runLocalEffect effect =
    case effect of
        FetchFunnels baseUrl user genMsg ->
            requestTask
                { method = Get
                , headers = [ Data.getAuthHeader user ]
                , url = baseUrl ++ "/funnel/"
                , decoder = JsonDecoder Data.decodeFunnels
                }
                |> Task.perform genMsg

        FetchSpendings baseUrl user genMsg ->
            requestTask
                { method = Get
                , headers = [ Data.getAuthHeader user ]
                , url = baseUrl ++ "/spending/"
                , decoder = JsonDecoder Data.decodeSpendings
                }
                |> Task.perform genMsg

        GenerateOtpSecret baseUrl body genMsg ->
            requestTask
                { method = Post (body |> Data.encodeOtpSecretRequest |> Http.jsonBody)
                , headers = []
                , url = baseUrl ++ "/user/generate-otp-secret"
                , decoder = JsonDecoder Data.decodeOtpSecret
                }
                |> Task.perform genMsg

        RegisterNewUser baseUrl body genMsg ->
            requestTask
                { method = Post (body |> Data.encodeRegisterRequest |> Http.jsonBody)
                , headers = []
                , url = baseUrl ++ "/user/"
                , decoder = JsonDecoder Data.decodeUserFromTokenPairResponse
                }
                |> Task.map extractMaybeUser
                |> Task.perform genMsg

        Login baseUrl body genMsg ->
            requestTask
                { method = Post (body |> Data.encodeLoginRequest |> Http.jsonBody)
                , headers = []
                , url = baseUrl ++ "/user/login"
                , decoder = JsonDecoder Data.decodeUserFromTokenPairResponse
                }
                |> Task.map extractMaybeUser
                |> Task.perform genMsg

        CreateSpending baseUrl user bodyWithoutTs genMsg ->
            let
                req =
                    \ts ->
                        requestTask
                            { method = Post (bodyWithoutTs |> Data.addTsToSpending ts |> Data.encodeSpending |> Http.jsonBody)
                            , headers = [ Data.getAuthHeader user ]
                            , url = baseUrl ++ "/spending/"
                            , decoder = StaticValue ()
                            }
            in
            Task.perform genMsg (Time.now |> Task.map Time.posixToMillis |> Task.andThen req)

        FetchFunnel baseUrl user id genMsg ->
            requestTask
                { method = Get
                , headers = [ Data.getAuthHeader user ]
                , url = baseUrl ++ "/funnel/" ++ id
                , decoder = JsonDecoder Data.decodeFunnel
                }
                |> Task.perform genMsg

        UpdateFunnel baseUrl user funnel genMsg ->
            let
                body =
                    funnel |> Data.encodeFunnelPut |> Http.jsonBody
            in
            requestTask
                { method = Put body
                , headers = [ Data.getAuthHeader user ]
                , url = baseUrl ++ "/funnel/" ++ funnel.id
                , decoder = StaticValue ()
                }
                |> Task.perform genMsg

        DeleteFunnel baseUrl user funnelId genMsg ->
            requestTask
                { method = Delete Http.emptyBody
                , headers = [ Data.getAuthHeader user ]
                , url = baseUrl ++ "/funnel/" ++ funnelId
                , decoder = StaticValue ()
                }
                |> Task.perform genMsg

        CreateFunnel baseUrl user funnel genMsg ->
            requestTask
                { method = Post (funnel |> Data.encodeFunnelPost |> Http.jsonBody)
                , headers = [ Data.getAuthHeader user ]
                , url = baseUrl ++ "/funnel/"
                , decoder = JsonDecoder JD.string
                }
                |> Task.perform genMsg

        DeleteSpending baseUrl user spendingId genMsg ->
            requestTask
                { method = Delete Http.emptyBody
                , headers = [ Data.getAuthHeader user ]
                , url = baseUrl ++ "/spending/" ++ spendingId
                , decoder = StaticValue ()
                }
                |> Task.perform genMsg


revalidateRequest : String -> User -> (ResponseData User -> msg) -> Cmd msg
revalidateRequest baseUrl user genMsg =
    requestTask
        { method = Post (user |> Data.encodeRefreshRequest |> Http.jsonBody)
        , headers = []
        , url = baseUrl ++ "/user/refresh"
        , decoder = JsonDecoder Data.decodeUserFromTokenPairResponse
        }
        |> Task.map extractMaybeUser
        |> Task.perform genMsg


extractMaybeUser : ResponseData (Maybe Data.User) -> ResponseData Data.User
extractMaybeUser =
    RD.andThen (RD.fromMaybe (Other "Invalid token sent in response :("))
