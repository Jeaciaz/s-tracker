module Ui.Button exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as HE


type ButtonColor
    = Accent
    | Outline
    | Custom String String


type ButtonState
    = Disabled
    | Loading
    | Normal


type alias ButtonConfig msg =
    { onClick : Maybe msg
    , color : ButtonColor
    , state : ButtonState
    }


viewAsButton : (List (Attribute msg) -> a) -> List (Attribute msg) -> ButtonConfig msg -> a
viewAsButton el additionalAttrs { onClick, color, state } =
    el <|
        (onClick |> Maybe.map (HE.onClick >> List.singleton) |> Maybe.withDefault [])
            ++ [ class "py-2 px-4 cursor-pointer text-lg text-center outline-black focus-visible:outline-4 active:brightness-75"
               , class <|
                    case color of
                        Accent ->
                            "bg-accent text-black"

                        Outline ->
                            "border border-accent text-slate-300"

                        Custom bg text ->
                            "bg-[" ++ bg ++ "] text-[" ++ text ++ "]"
               , class <|
                    case state of
                        Disabled ->
                            "pointer-events-none opacity-50"

                        Loading ->
                            "pointer-events-none animate-pulse cursor-progress brightness-50"

                        Normal ->
                            ""
               ]
            ++ additionalAttrs


view : ButtonConfig msg -> List (Html msg) -> Html msg
view =
    viewAsButton button []


viewButtonLink : String -> ButtonConfig msg -> List (Html msg) -> Html msg
viewButtonLink to =
    viewAsButton a [ href to ]
