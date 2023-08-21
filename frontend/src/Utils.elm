module Utils exposing (..)


flip : (a -> b -> c) -> b -> a -> c
flip f a b = f b a

prefixToFloat : String -> Maybe Float
prefixToFloat str =
  case String.toFloat str of
    Just f -> Just f
    Nothing -> case str of
      "" -> Nothing
      _ -> prefixToFloat <| String.slice 0 -1 str


formatFloat : Float -> String
formatFloat f =
  let
      fixedDigits = 2
      multi = 10 ^ fixedDigits
  in
  multi * f |> round |> toFloat |> flip (/) multi |> String.fromFloat
