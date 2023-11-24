module Route exposing (Route(..), fromUrl, goto, homePage, href, replaceUrl)

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Url
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s)


type Route
    = Settings
    | Dashboard
    | FunnelForm (Maybe String)


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Settings (s "settings")
        , Parser.map (Just >> FunnelForm) (s "funnel" </> Parser.string)
        , Parser.map (FunnelForm Nothing) (s "funnel")
        , Parser.map Dashboard Parser.top
        ]



-- PUBLIC HELPERS


homePage : String
homePage =
    routeToString Dashboard


href : Route -> Attribute msg
href route =
    Attr.href (routeToString route)


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (routeToString route)


fromUrl : Url.Url -> Maybe Route
fromUrl url =
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing } |> Parser.parse parser


goto : Nav.Key -> Route -> Cmd msg
goto key route =
    Nav.pushUrl key (routeToString route)



-- INTERNAL


routeToString : Route -> String
routeToString route =
    "#/" ++ String.join "/" (routeToPieces route)


routeToPieces : Route -> List String
routeToPieces route =
    case route of
        Dashboard ->
            []

        Settings ->
            [ "settings" ]

        FunnelForm funnelId ->
            case funnelId of
                Just id ->
                    [ "funnel", id ]

                Nothing ->
                    [ "funnel" ]
