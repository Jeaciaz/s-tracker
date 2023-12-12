port module Data exposing
    ( Auth(..)
    , Funnel
    , FunnelPost
    , FunnelPut
    , Funnels
    , LoginRequest
    , OtpSecretRequest
    , OtpSecretResponse
    , RegisterRequest
    , Spending
    , SpendingCreateWithoutTs
    , Spendings
    , TokenPair
    , User
    , UserData
    , addTsToSpending
    , decodeFunnel
    , decodeFunnels
    , decodeNothing
    , decodeOtpSecret
    , decodeServerError
    , decodeSpendings
    , decodeUserFromTokenPairResponse
    , encodeFunnelPost
    , encodeFunnelPut
    , encodeLoginRequest
    , encodeOtpSecretRequest
    , encodeRefreshRequest
    , encodeRegisterRequest
    , encodeSpending
    , getAuthHeader
    , getUserData
    , onlyAuthHeader
    , saveTokens
    , tokenPairToUser
    , tokensUpdated
    )

import Http
import Json.Decode as JD
import Json.Encode as JE
import Jwt


port saveTokensPort : TokenPair -> Cmd msg


port tokensUpdatedPort : (TokenPair -> msg) -> Sub msg


saveTokens : User -> Cmd msg
saveTokens (User _ tokenPair) =
    saveTokensPort tokenPair


tokensUpdated : (Maybe User -> msg) -> Sub msg
tokensUpdated f =
    tokensUpdatedPort (\pair -> pair |> tokenPairToUser |> f)



-- DOMAIN


type alias Funnel =
    { name : String
    , color : String
    , emoji : String
    , remaining : Float
    , limit : Float
    , daily : Float
    , id : String
    }


type alias FunnelPost =
    { name : String
    , limit : Float
    , color : String
    , emoji : String
    }


type alias FunnelPut =
    { name : String
    , limit : Float
    , color : String
    , emoji : String
    , id : String
    }


type alias Funnels =
    List Funnel


decodeFunnel : JD.Decoder Funnel
decodeFunnel =
    JD.map7 Funnel
        (JD.field "name" JD.string)
        (JD.field "color" JD.string)
        (JD.field "emoji" JD.string)
        (JD.field "remaining" JD.float)
        (JD.field "limit" JD.float)
        (JD.field "daily" JD.float)
        (JD.field "id" JD.string)


decodeFunnels : JD.Decoder Funnels
decodeFunnels =
    JD.list decodeFunnel


encodeFunnelPost : FunnelPost -> JE.Value
encodeFunnelPost { name, limit, color, emoji } =
    JE.object [ ( "name", JE.string name ), ( "limit", JE.float limit ), ( "color", JE.string color ), ( "emoji", JE.string emoji ) ]


encodeFunnelPut : FunnelPut -> JE.Value
encodeFunnelPut { name, limit, color, emoji, id } =
    JE.object [ ( "name", JE.string name ), ( "limit", JE.float limit ), ( "color", JE.string color ), ( "emoji", JE.string emoji ), ( "id", JE.string id ) ]


type alias Spending =
    { amount : Float
    , timestamp : Int
    , funnelId : String
    , id : String
    }


type alias SpendingCreate =
    { amount : Float
    , timestamp : Int
    , funnelId : String
    }


type alias SpendingCreateWithoutTs =
    { amount : Float
    , funnelId : String
    }


type alias Spendings =
    List Spending


addTsToSpending : Int -> SpendingCreateWithoutTs -> SpendingCreate
addTsToSpending timestamp { amount, funnelId } =
    { amount = amount, funnelId = funnelId, timestamp = timestamp }


decodeSpendings : JD.Decoder Spendings
decodeSpendings =
    JD.list
        (JD.map4 Spending
            (JD.field "amount" JD.float)
            (JD.field "timestamp" JD.int)
            (JD.field "funnel_id" JD.string)
            (JD.field "id" JD.string)
        )


encodeSpending : SpendingCreate -> JE.Value
encodeSpending { amount, timestamp, funnelId } =
    JE.object
        [ ( "amount", JE.float amount )
        , ( "timestamp", JE.int timestamp )
        , ( "funnel_id", JE.string funnelId )
        ]


decodeNothing : JD.Decoder ()
decodeNothing =
    JD.succeed ()



-- USER/AUTH


type alias OtpSecretRequest =
    { username : String }


encodeOtpSecretRequest : OtpSecretRequest -> JE.Value
encodeOtpSecretRequest { username } =
    JE.object [ ( "username", JE.string username ) ]


type alias OtpSecretResponse =
    { secret : String
    , uri : String
    }


decodeOtpSecret : JD.Decoder OtpSecretResponse
decodeOtpSecret =
    JD.map2 OtpSecretResponse
        (JD.field "secret" JD.string)
        (JD.field "uri" JD.string)


type alias RegisterRequest =
    { username : String
    , otpSecret : String
    , otpExample : String
    }


encodeRegisterRequest : RegisterRequest -> JE.Value
encodeRegisterRequest { username, otpSecret, otpExample } =
    JE.object [ ( "username", JE.string username ), ( "otp_secret", JE.string otpSecret ), ( "otp_example", JE.string otpExample ) ]


type alias TokenPair =
    { refresh : String
    , access : String
    }


type alias UserData =
    { username : String }


type User
    = User UserData TokenPair


type Auth
    = LoggedIn User
    | Refreshing
    | LoggedOut


decodeUserData : JD.Decoder UserData
decodeUserData =
    JD.map UserData
        (JD.field "username" JD.string)


decodeTokenPair : JD.Decoder TokenPair
decodeTokenPair =
    JD.map2 TokenPair
        (JD.field "refresh" JD.string)
        (JD.field "access" JD.string)


extractJwtData : String -> Result Jwt.JwtError UserData
extractJwtData =
    Jwt.decodeToken decodeUserData


tokenPairToUser : TokenPair -> Maybe User
tokenPairToUser pair =
    case extractJwtData pair.access of
        Result.Ok userData ->
            Just <| User userData pair

        Result.Err _ ->
            Nothing


decodeUserFromTokenPairResponse : JD.Decoder (Maybe User)
decodeUserFromTokenPairResponse =
    JD.map tokenPairToUser decodeTokenPair


getUserData : User -> UserData
getUserData (User data _) =
    data


getAuthHeader : User -> Http.Header
getAuthHeader (User _ { access }) =
    Http.header "Authorization" ("Bearer " ++ access)


onlyAuthHeader : Maybe User -> List Http.Header
onlyAuthHeader maybeUser =
    case maybeUser of
        Just user ->
            [ getAuthHeader user ]

        Nothing ->
            []


type alias LoginRequest =
    { username : String
    , otp : String
    }


encodeLoginRequest : LoginRequest -> JE.Value
encodeLoginRequest { username, otp } =
    JE.object [ ( "username", JE.string username ), ( "otp", JE.string otp ) ]


encodeRefreshRequest : User -> JE.Value
encodeRefreshRequest (User _ { refresh }) =
    JE.object [ ( "refresh", JE.string refresh ) ]


decodeServerError : JD.Decoder String
decodeServerError =
    JD.oneOf
        [ JD.field "detail" JD.string
        , JD.field "message" JD.string
        , JD.field "msg" JD.string
        ]
