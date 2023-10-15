module Utils exposing (..)

import Http


flip : (a -> b -> c) -> b -> a -> c
flip f a b =
    f b a


prefixToFloat : String -> Maybe Float
prefixToFloat str =
    case String.toFloat str of
        Just f ->
            Just f

        Nothing ->
            case str of
                "" ->
                    Nothing

                _ ->
                    prefixToFloat <| String.slice 0 -1 str


formatFloat : Float -> String
formatFloat f =
    let
        fixedDigits =
            2

        multi =
            10 ^ fixedDigits
    in
    multi * f |> round |> toFloat |> flip (/) multi |> String.fromFloat


errorToString : Http.Error -> String
errorToString error =
    case error of
        Http.BadUrl url ->
            "Bad url: " ++ url

        Http.Timeout ->
            "Could not reach the server, try again"

        Http.NetworkError ->
            "Could not reach the server, check your internet connection"

        Http.BadStatus 500 ->
            "The server had a problem, try again later"

        Http.BadStatus 400 ->
            "The server cannot handle this request, try again later"

        Http.BadStatus _ ->
            "Unknown error"

        Http.BadBody msg ->
            msg
