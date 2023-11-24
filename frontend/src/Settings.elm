module Settings exposing (..)

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



-- MODEL


type alias Model =
    { baseUrl : String
    , user : Data.User
    , funnels : Effect.ResponseData Data.Funnels
    }


init : String -> Data.User -> ( Model, List (Effect Msg) )
init url user =
    ( { baseUrl = url
      , user = user
      , funnels = RD.NotAsked
      }
    , [ Effect.Local <| Effect.FetchFunnels url user GotFunnels ]
    )



-- UPDATE


type Msg
    = GotoHomePage
    | GotFunnels (Effect.ResponseData Data.Funnels)
    | GotoFunnel String


update : Msg -> Model -> ( Model, List (Effect Msg) )
update msg model =
    let
        fetchFunnelsEffect user =
            Effect.Local <| Effect.FetchFunnels model.baseUrl user GotFunnels
    in
    case msg of
        GotoHomePage ->
            ( model, [ Effect.Global <| Effect.GotoRoute model.user Route.Dashboard ] )

        GotFunnels response ->
            case response of
                RD.Failure Effect.InvalidToken ->
                    ( model, [ Effect.Global <| Effect.RevalidateToken model.baseUrl model.user fetchFunnelsEffect ] )

                RD.Failure (Effect.Other detail) ->
                    ( model, [ Effect.Global <| Effect.Alert detail ] )

                RD.Success data ->
                    ( { model | funnels = RD.succeed data }, [] )

                RD.NotAsked ->
                    ( { model | funnels = RD.NotAsked }, [] )

                RD.Loading ->
                    ( { model | funnels = RD.Loading }, [] )

        GotoFunnel id ->
            ( model, [ Effect.Global <| Effect.GotoRoute model.user (Route.FunnelForm (Just id)) ] )



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
                [ button [ class "p-1", HE.onClick GotoHomePage, attribute "aria-label" "Return to dashboard" ]
                    [ Icons.close ]
                ]
        , content =
            div []
                [ h2 [ class "text-2xl tracking-wide mb-4" ] [ text "Funnels" ]
                , Effect.foldResponse
                    viewFunnels
                    model.funnels
                -- , button [ class "mt-8 border w-full flex justify-center active:bg-slate-600 rounded py-2" ] [ Icons.plus ]
                ]
        }


viewFunnels : Data.Funnels -> Html Msg
viewFunnels funnels =
    div [ class "flex flex-col gap-6" ] <|
        List.map
            (\funnel ->
                div [ class "flex gap-4 text-xl relative pb-1.5" ]
                    [ span [] [ text funnel.emoji ]
                    , span [] [ text funnel.name ]
                    , button
                        [ class "ms-auto"
                        , class Clsx.iconButton
                        , HE.onClick (GotoFunnel funnel.id)
                        , attribute "aria-label" "Edit funnel"
                        ]
                        [ Icons.edit ]
                    -- , button [ class Clsx.iconButton, attribute "aria-label" "Delete funnel" ] [ Icons.delete ]
                    , div [ class "absolute bottom-0 h-0.5 w-1/2 rounded", style "background-color" funnel.color ] []
                    , div [ class "absolute bottom-0 h-0.5 w-full rounded opacity-50", style "background-color" funnel.color ] []
                    ]
            )
            funnels
