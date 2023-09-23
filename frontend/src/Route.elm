module Route exposing (Route(..), fromUrl, href, replaceUrl)

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Url
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s)


type Route
    = Login
    | Dashboard


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Dashboard Parser.top
        , Parser.map Login (s "login")
        ]



-- PUBLIC HELPERS


href : Route -> Attribute msg
href route =
    Attr.href (routeToString route)


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (routeToString route)


fromUrl : Url.Url -> Maybe Route
fromUrl url =
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing } |> Parser.parse parser



-- INTERNAL


routeToString : Route -> String
routeToString route =
    "#/" ++ String.join "/" (routeToPieces route)


routeToPieces : Route -> List String
routeToPieces route =
    case route of
        Dashboard ->
            []

        Login ->
            [ "login" ]
