module Settings.FunnelForm exposing (..)

import Clsx
import Data
import Effect exposing (Effect)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as HE
import Icons
import Layout
import RemoteData as RD
import Route
import Ui.Button



-- MODEL


type alias FormField a =
    { value : a
    , dirty : Bool
    }


type alias FormState =
    { emoji : FormField String
    , name : FormField String
    , color : FormField String
    , limit : FormField String
    }


isDirty : FormState -> Bool
isDirty state =
    [ .emoji, .name, .color, .limit ] |> List.any (\getter -> getter state |> .dirty)


initialFormField : a -> FormField a
initialFormField value =
    { value = value
    , dirty = False
    }


dirtyFormField : a -> FormField a
dirtyFormField value =
    { value = value
    , dirty = True
    }


type FormType
    = CreateFunnel
    | EditFunnel String (Effect.ResponseData Data.Funnel)


type alias Model =
    { baseUrl : String
    , user : Data.User
    , formType : FormType
    , formState : FormState
    }


init : String -> Data.User -> Maybe String -> ( Model, List (Effect Msg) )
init url user maybeFunnelId =
    let
        formType =
            case maybeFunnelId of
                Just id ->
                    EditFunnel id RD.Loading

                Nothing ->
                    CreateFunnel
    in
    ( { baseUrl = url
      , user = user
      , formType = formType
      , formState =
            { emoji = initialFormField ""
            , name = initialFormField ""
            , color = initialFormField ""
            , limit = initialFormField ""
            }
      }
    , case maybeFunnelId of
        Just id ->
            [ Effect.Local <| Effect.FetchFunnel url user id (GotFunnelData id) ]

        Nothing ->
            []
    )



-- UPDATE


type Msg
    = GotFunnelData String (Effect.ResponseData Data.Funnel)
    | SubmitNewData
    | SetEmoji String
    | SetName String
    | SetColor String
    | SetLimit String
    | NewDataSubmitted Data.FunnelPut (Effect.ResponseData ()) -- response and request model
    | CloseForm


update : Msg -> Model -> ( Model, List (Effect Msg) )
update msg model =
    let
        updateFunnelEffect body user =
            Effect.Local <|
                Effect.UpdateFunnel
                    model.baseUrl
                    user
                    body
                    (NewDataSubmitted body)
    in
    case msg of
        GotFunnelData id data ->
            case data of
                RD.Success funnel ->
                    ( { model
                        | formState =
                            { emoji = initialFormField funnel.emoji
                            , name = initialFormField funnel.name
                            , color = initialFormField funnel.color
                            , limit = initialFormField <| String.fromFloat funnel.limit
                            }
                      }
                    , []
                    )

                RD.Failure Effect.InvalidToken ->
                    ( model
                    , [ Effect.Global <|
                            Effect.RevalidateToken
                                model.baseUrl
                                model.user
                                (\user -> Effect.Local <| Effect.FetchFunnel model.baseUrl user id (GotFunnelData id))
                      ]
                    )

                RD.Failure (Effect.Other error) ->
                    ( model, [ Effect.Global <| Effect.Alert error ] )

                _ ->
                    ( model, [] )

        SubmitNewData ->
            let
                maybeLimit =
                    String.toFloat model.formState.limit.value
            in
            case maybeLimit of
                Just limit ->
                    ( model
                    , case model.formType of
                        EditFunnel id _ ->
                            [ updateFunnelEffect
                                { name = model.formState.name.value
                                , limit = limit
                                , color = model.formState.color.value
                                , emoji = model.formState.emoji.value
                                , id = id
                                }
                                model.user
                            ]

                        CreateFunnel ->
                            []
                    )

                Nothing ->
                    ( model, [] )

        NewDataSubmitted body response ->
            case response of
                RD.Success () ->
                    ( model, [ Effect.Global <| Effect.GotoRoute model.user Route.Settings ] )

                RD.Failure Effect.InvalidToken ->
                    ( model, [ Effect.Global <| Effect.RevalidateToken model.baseUrl model.user (updateFunnelEffect body) ] )

                RD.Failure (Effect.Other detail) ->
                    ( model, [ Effect.Global <| Effect.Alert detail ] )

                _ ->
                    ( model, [] )

        CloseForm ->
            ( model, [ Effect.Global <| Effect.GotoRoute model.user Route.Settings ] )

        SetEmoji emoji ->
            let
                form =
                    model.formState

                newForm =
                    { form | emoji = dirtyFormField emoji }
            in
            ( { model | formState = newForm }, [] )

        SetName name ->
            let
                form =
                    model.formState

                newForm =
                    { form | name = dirtyFormField name }
            in
            ( { model | formState = newForm }, [] )

        SetColor color ->
            let
                form =
                    model.formState

                newForm =
                    { form | color = dirtyFormField color }
            in
            ( { model | formState = newForm }, [] )

        SetLimit limit ->
            let
                form =
                    model.formState

                newForm =
                    { form | limit = dirtyFormField limit }
            in
            ( { model | formState = newForm }, [] )



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
                [ button [ HE.onClick CloseForm, class "p-1", attribute "aria-label" "Return to funnel list" ]
                    [ Icons.close ]
                ]
        , content =
            div []
                [ h2 [ class "text-2.5xl" ]
                    [ text
                        (case model.formType of
                            CreateFunnel ->
                                "Create funnel"

                            EditFunnel _ _ ->
                                "Edit funnel"
                        )
                    ]
                , Html.form
                    [ class "pt-4 flex flex-col gap-4"
                    , HE.onSubmit SubmitNewData
                    ]
                    [ div [ class "flex gap-2" ]
                        [ label [ class "flex flex-col gap-1 w-1/3" ]
                            [ div [] [ text "Emoji" ]
                            , input
                                [ class Clsx.input
                                , value model.formState.emoji.value
                                , HE.onInput SetEmoji
                                ]
                                []
                            ]
                        , label [ class "flex flex-col gap-1 w-2/3" ]
                            [ div [] [ text "Name" ]
                            , input
                                [ class Clsx.input
                                , value model.formState.name.value
                                , HE.onInput SetName
                                ]
                                []
                            ]
                        ]
                    , label [ class "flex flex-col gap-1" ]
                        [ div [] [ text "Color" ]
                        , div [ class "relative h-10" ]
                            [ div [ class "absolute rounded inset-0 opacity-50", style "background-color" model.formState.color.value ] []
                            , div [ class "absolute rounded inset-0 right-1/2", style "background-color" model.formState.color.value ] []
                            , div [ class "absolute left-2 top-2 w-6 h-6 flex justify-center items-center drop-shadow-outline" ] [ Icons.edit ]
                            ]
                        , input
                            [ class "hidden"
                            , type_ "color"
                            , HE.onInput SetColor
                            ]
                            []
                        ]
                    , label [ class "flex flex-col gap-1" ]
                        [ div [] [ text "Monthly limit" ]
                        , input
                            [ class Clsx.input
                            , value model.formState.limit.value
                            , HE.onInput SetLimit
                            ]
                            []
                        ]
                    , div [ class "pt-6 w-full flex flex-col" ]
                        [ Ui.Button.view
                            { onClick = Nothing
                            , color = Ui.Button.Accent
                            , state =
                                if isDirty model.formState then
                                    Ui.Button.Normal

                                else
                                    Ui.Button.Disabled
                            }
                            [ text "Save changes" ]
                        ]
                    ]
                ]
        }
