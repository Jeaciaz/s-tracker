module Icons exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Svg exposing (path, svg)
import Svg.Attributes as SvgAttr


refresh : Html msg
refresh =
    svg
        [ SvgAttr.width "24"
        , SvgAttr.height "24"
        , SvgAttr.fill "none"
        , SvgAttr.viewBox "0 0 24 24"
        ]
        [ Svg.g
            [ SvgAttr.fill "currentColor"
            , SvgAttr.fillRule "evenodd"
            , SvgAttr.clipPath "url(#a)"
            , SvgAttr.clipRule "evenodd"
            ]
            [ path
                [ SvgAttr.d "M4.42 9.43A8 8 0 0 1 15.71 4.9l-1.07.95a.25.25 0 0 0 .17.43l4.74-.08c.19 0 .3-.2.21-.37l-2.3-4.14a.25.25 0 0 0-.46.07l-.29 1.4A10 10 0 0 0 2.34 14.6l1.93-.52a8 8 0 0 1 .15-4.64ZM19.58 14.57A8 8 0 0 1 8.29 19.1l1.07-.95a.25.25 0 0 0-.17-.43l-4.74.08c-.19 0-.3.2-.21.37l2.3 4.14c.11.2.41.16.46-.07l.29-1.4A10 10 0 0 0 21.66 9.4l-1.93.52a8 8 0 0 1-.15 4.64Z"
                ]
                []
            ]
        , Svg.defs []
            [ Svg.clipPath
                [ SvgAttr.id "a"
                ]
                [ path
                    [ SvgAttr.d "M0 0h24v24H0z"
                    ]
                    []
                ]
            ]
        ]
