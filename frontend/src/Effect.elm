module Effect exposing (Effect(..), GlobalEffect(..), LocalEffect(..), mapEffect, mapLocalEffect, revalidateRequest, runLocalEffect)

import Http
import Json.Decode as JD
import Data exposing (User)
import RemoteData as RD
import Task
import Time


type HttpMethod
    = Get
    | Post Http.Body
    | Put Http.Body
    | Delete Http.Body


type Effect msgOnSuccess
    = Local (LocalEffect msgOnSuccess)
    | Global (GlobalEffect msgOnSuccess)


type LocalEffect msgOnSuccess
    = FetchFunnels String User (RD.WebData Data.Funnels -> msgOnSuccess)
    | FetchSpendings String User (RD.WebData Data.Spendings -> msgOnSuccess)
    | GenerateOtpSecret String Data.OtpSecretRequest (RD.WebData Data.OtpSecretResponse -> msgOnSuccess)
    | RegisterNewUser String Data.RegisterRequest (RD.WebData User -> msgOnSuccess)
    | Login String Data.LoginRequest (RD.WebData User -> msgOnSuccess)
    | CreateSpending String User Data.SpendingCreateWithoutTs (RD.WebData () -> msgOnSuccess)


type GlobalEffect msgOnSuccess
    = CopyText String
    | Alert String
    | SaveTokens User
    | RevalidateToken String User (User -> Effect msgOnSuccess)
    | GotoHomePage User


type alias RequestConfig response =
    { method : HttpMethod
    , url : String
    , headers : List Http.Header
    , decoder : JD.Decoder response

    -- , expect : Http.Expect msg
    }


requestTask : RequestConfig res -> Task.Task x (RD.WebData res)
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
                            resText
                                |> JD.decodeString decoder
                                |> Result.mapError (JD.errorToString >> Http.BadBody)

                        Http.BadUrl_ url_ ->
                            Result.Err (Http.BadUrl url_)

                        Http.Timeout_ ->
                            Result.Err Http.Timeout

                        Http.NetworkError_ ->
                            Result.Err Http.NetworkError

                        Http.BadStatus_ { statusCode } _ ->
                            Result.Err (Http.BadStatus statusCode)
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


mapGlobalEffect : (a -> b) -> GlobalEffect a -> GlobalEffect b
mapGlobalEffect f effect =
    case effect of
        RevalidateToken baseUrl user genEffect ->
            RevalidateToken baseUrl user (genEffect >> mapEffect f)

        CopyText s ->
            CopyText s

        Alert s ->
            Alert s

        SaveTokens user ->
            SaveTokens user

        GotoHomePage user ->
            GotoHomePage user


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
                , decoder = Data.decodeFunnels
                }
                |> Task.perform genMsg

        FetchSpendings baseUrl user genMsg ->
            requestTask
                { method = Get
                , headers = [ Data.getAuthHeader user ]
                , url = baseUrl ++ "/spending/"
                , decoder = Data.decodeSpendings
                }
                |> Task.perform genMsg

        GenerateOtpSecret baseUrl body genMsg ->
            requestTask
                { method = Post (body |> Data.encodeOtpSecretRequest |> Http.jsonBody)
                , headers = []
                , url = baseUrl ++ "/user/generate-otp-secret"
                , decoder = Data.decodeOtpSecret
                }
                |> Task.perform genMsg

        RegisterNewUser baseUrl body genMsg ->
            requestTask
                { method = Post (body |> Data.encodeRegisterRequest |> Http.jsonBody)
                , headers = []
                , url = baseUrl ++ "/user/"
                , decoder = Data.decodeUserFromTokenPairResponse
                }
                |> Task.map extractMaybeUser
                |> Task.perform genMsg

        Login baseUrl body genMsg ->
            requestTask
                { method = Post (body |> Data.encodeLoginRequest |> Http.jsonBody)
                , headers = []
                , url = baseUrl ++ "/user/login"
                , decoder = Data.decodeUserFromTokenPairResponse
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
                            , url = baseUrl ++ "/spending"
                            , decoder = Data.decodeNothing
                            }
            in
            Task.perform genMsg (Time.now |> Task.map Time.posixToMillis |> Task.andThen req)


revalidateRequest : String -> User -> (RD.WebData User -> msg) -> Cmd msg
revalidateRequest baseUrl user genMsg =
    requestTask
        { method = Post (user |> Data.encodeRefreshRequest |> Http.jsonBody)
        , headers = []
        , url = baseUrl ++ "/user/refresh"
        , decoder = Data.decodeUserFromTokenPairResponse
        }
        |> Task.map extractMaybeUser
        |> Task.perform genMsg


extractMaybeUser : RD.WebData (Maybe Data.User) -> RD.WebData Data.User
extractMaybeUser =
    RD.andThen (RD.fromMaybe (Http.BadBody "Invalid token send in response :("))
