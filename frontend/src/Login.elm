module Login exposing (Model, Msg, init, subscriptions, update, view)

import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Layout
import Data as D
import RemoteData as RD
import Ui.Button
import Ui.Input



-- MODEL


type OtpSecretState
    = NotGenerated
    | Generating
    | Generated { uri : String, secret : String, otp : String }


type alias RegisterModel =
    { username : String
    , otpSecret : OtpSecretState
    }


type alias LoginModel =
    { username : String
    , otp : String
    , isSubmitting : Bool
    }


type ModeModel
    = Register RegisterModel
    | Login LoginModel


type alias Model =
    { mode : ModeModel
    , baseUrl : String
    }


isLogin : Model -> Bool
isLogin { mode } =
    case mode of
        Register _ ->
            False

        Login _ ->
            True


init : String -> ( Model, List (Effect Msg) )
init baseUrl =
    ( { mode = Login { username = "", otp = "", isSubmitting = False }, baseUrl = baseUrl }, [] )


type RegisterMsg
    = UpdateRegisterUsername String
    | UpdateRegisterOtp String
    | GenerateOtpSecret
    | GeneratedOtpSecret (RD.WebData D.OtpSecretResponse)
    | CopySecret String
    | RegisterNewUser D.RegisterRequest
    | NewUserRegistered (RD.WebData D.User)


type LoginMsg
    = UpdateLoginUsername String
    | UpdateLoginOtp String
    | SubmitLogin
    | SuccessfulLogin (RD.WebData D.User)


type Msg
    = GotRegisterMsg RegisterMsg
    | GotLoginMsg LoginMsg
    | ToggleMode



-- UPDATE


updateRegisterModel : RegisterMsg -> RegisterModel -> String -> ( ModeModel, List (Effect Msg) )
updateRegisterModel msg model baseUrl =
    case msg of
        UpdateRegisterUsername newUsername ->
            ( Register { model | username = newUsername }, [] )

        GenerateOtpSecret ->
            ( Register { model | otpSecret = Generating }
            , [ Effect.Local <| Effect.GenerateOtpSecret baseUrl { username = model.username } (GeneratedOtpSecret >> GotRegisterMsg) ]
            )

        GeneratedOtpSecret response ->
            let
                newModel =
                    case response of
                        RD.Success { secret, uri } ->
                            { model | otpSecret = Generated { secret = secret, uri = uri, otp = "" } }

                        RD.Failure _ ->
                            { model | otpSecret = NotGenerated }

                        RD.Loading ->
                            model

                        RD.NotAsked ->
                            model
            in
            ( Register newModel, [] )

        UpdateRegisterOtp newOtp ->
            let
                newModel =
                    case model.otpSecret of
                        Generated secret ->
                            let
                                newSecret =
                                    Generated { secret | otp = newOtp }
                            in
                            { model | otpSecret = newSecret }

                        _ ->
                            model
            in
            ( Register newModel, [] )

        CopySecret secret ->
            ( Register model, [ Effect.Global <| Effect.CopyText secret ] )

        RegisterNewUser request ->
            ( Register model
            , [ Effect.Local <|Effect.RegisterNewUser
                    baseUrl
                    request
                    (NewUserRegistered >> GotRegisterMsg)
              ]
            )

        NewUserRegistered userRd ->
            case RD.toMaybe userRd of
              Just user -> 
                ( Register model, [Effect.Global <| Effect.GotoHomePage user] )
              Nothing ->
                ( Register model, [Effect.Global <| Effect.Alert "Registration unsuccessful"])


updateLoginModel : LoginMsg -> LoginModel -> String -> ( ModeModel, List (Effect Msg) )
updateLoginModel msg model baseUrl =
    case msg of
        UpdateLoginUsername newUsername ->
            ( Login { model | username = newUsername }, [] )

        UpdateLoginOtp newOtp ->
            ( Login { model | otp = newOtp }, [] )

        SubmitLogin ->
            ( Login { model | isSubmitting = True }
            , [ Effect.Local <| Effect.Login
                    baseUrl
                    { username = model.username, otp = model.otp }
                    (SuccessfulLogin >> GotLoginMsg)
              ]
            )

        SuccessfulLogin userData ->
            let
                effects =
                    case RD.toMaybe userData of
                        Nothing ->
                            [Effect.Global <| Effect.Alert "Login unsuccessful"]

                        Just user ->
                            [Effect.Global <| Effect.SaveTokens user, Effect.Global <| Effect.GotoHomePage user]
            in
            ( Login { model | isSubmitting = False }, effects )


update : Msg -> Model -> ( Model, List (Effect Msg) )
update msg model =
    let
        ( modeModel, effects ) =
            case ( model.mode, msg ) of
                ( Register regModel, GotRegisterMsg regMsg ) ->
                    updateRegisterModel regMsg regModel model.baseUrl

                ( Login loginModel, GotLoginMsg loginMsg ) ->
                    updateLoginModel loginMsg loginModel model.baseUrl

                ( Register regModel, ToggleMode ) ->
                    ( Login { username = regModel.username, otp = "", isSubmitting = False }, [] )

                ( Login loginModel, ToggleMode ) ->
                    ( Register { username = loginModel.username, otpSecret = NotGenerated }, [] )

                ( _, _ ) ->
                    ( model.mode, [] )
    in
    ( { model | mode = modeModel }, effects )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    Layout.viewContent
        { headerContent = Html.text ""
        , content =
            div []
                [ div [ class "flex justify-between" ]
                    [ (if isLogin model then
                        h2

                       else
                        button
                      )
                        [ class "text-2xl", classList [ ( "font-semibold tracking-wider text-accent pointer-events-none", isLogin model ) ], onClick ToggleMode ]
                        [ text "Login" ]
                    , (if isLogin model then
                        button

                       else
                        h2
                      )
                        [ class "text-2xl", classList [ ( "font-semibold tracking-wider text-accent pointer-events-none", not (isLogin model) ) ], onClick ToggleMode ]
                        [ text "Register" ]
                    ]
                , div [ class "mt-4 flex flex-col" ]
                    [ case model.mode of
                        Register regModel ->
                            viewRegisterFields regModel |> Html.map GotRegisterMsg

                        Login loginModel ->
                            viewLogin loginModel |> Html.map GotLoginMsg
                    ]
                ]
        }


viewRegisterFields : RegisterModel -> Html RegisterMsg
viewRegisterFields { username, otpSecret } =
    let
        genOtpButton =
            \isPending ->
                Ui.Button.view
                    { onClick = Just GenerateOtpSecret
                    , color = Ui.Button.Accent
                    , state =
                        if isPending then
                            Ui.Button.Loading

                        else
                            Ui.Button.Normal
                    }
                    [ text "Create OTP secret" ]
    in
    div [ class "flex flex-col gap-4" ] <|
        Ui.Input.view { value = username, onChange = UpdateRegisterUsername, placeholder = "Username" }
            :: (case otpSecret of
                    NotGenerated ->
                        [ genOtpButton False ]

                    Generating ->
                        [ genOtpButton True ]

                    Generated { uri, secret, otp } ->
                        [ Ui.Input.view { value = otp, onChange = UpdateRegisterOtp, placeholder = "One-time password" }
                        , div [ class "flex gap-4" ]
                            [ Ui.Button.viewButtonLink uri
                                { onClick = Nothing, color = Ui.Button.Accent, state = Ui.Button.Normal }
                                [ text "Add secret key to keychain" ]
                            , Ui.Button.view
                                { onClick = Just (CopySecret secret), color = Ui.Button.Outline, state = Ui.Button.Normal }
                                [ text "Copy secret key" ]
                            ]
                        , div [ class "fixed bottom-0 inset-x-0 flex flex-col p-6" ]
                            [ Ui.Button.view
                                { onClick = Just (RegisterNewUser { username = username, otpSecret = secret, otpExample = otp })
                                , color = Ui.Button.Accent
                                , state =
                                    if otp /= "" then
                                        Ui.Button.Normal

                                    else
                                        Ui.Button.Disabled
                                }
                                [ text "Register new account" ]
                            ]
                        ]
               )


viewLogin : LoginModel -> Html LoginMsg
viewLogin { username, otp, isSubmitting } =
    Html.form [ class "flex flex-col gap-4", onSubmit SubmitLogin ]
        [ Ui.Input.view { value = username, onChange = UpdateLoginUsername, placeholder = "Username" }
        , Ui.Input.view { value = otp, onChange = UpdateLoginOtp, placeholder = "One-time password" }
        , Ui.Button.view
            { color = Ui.Button.Accent
            , onClick = Nothing
            , state =
                if isSubmitting then
                    Ui.Button.Loading

                else
                    Ui.Button.Normal
            }
            [ text "Log in" ]
        ]
