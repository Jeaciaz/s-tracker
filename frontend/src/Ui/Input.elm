module Ui.Input exposing (..)

import Html exposing (..)
import Html.Attributes as HA exposing (..)
import Html.Events exposing (..)


type alias InputConfig msg =
    { value : String
    , onChange : String -> msg
    , placeholder : String
    }


view : InputConfig msg -> Html msg
view { value, onChange, placeholder } =
    input
        [ type_ "text"
        , class "bg-transparent border-b-2 text-lg leading-loose outline-none focus:border-b-accent transition"
        , HA.value value
        , onInput onChange
        , HA.placeholder placeholder
        ]
        []
