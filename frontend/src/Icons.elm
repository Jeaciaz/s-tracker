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


close : Html msg
close =
    svg
        [ SvgAttr.width "22"
        , SvgAttr.height "22"
        , SvgAttr.fill "none"
        ]
        [ Svg.rect
            [ SvgAttr.width "25.7467"
            , SvgAttr.height "4"
            , SvgAttr.x ".745209"
            , SvgAttr.y "18.9509"
            , SvgAttr.fill "currentColor"
            , SvgAttr.rx "1"
            , SvgAttr.transform "rotate(-45 .745209 18.9509)"
            ]
            []
        , Svg.rect
            [ SvgAttr.width "25.7467"
            , SvgAttr.height "4"
            , SvgAttr.x "18.9509"
            , SvgAttr.y "21.7793"
            , SvgAttr.fill "currentColor"
            , SvgAttr.rx "1"
            , SvgAttr.transform "rotate(-135 18.9509 21.7793)"
            ]
            []
        ]


edit : Html msg
edit =
    svg
        [ SvgAttr.width "19"
        , SvgAttr.height "19"
        , SvgAttr.viewBox "0 0 19 19"
        , SvgAttr.fill "none"
        ]
        [ path
            [ SvgAttr.fillRule "evenodd"
            , SvgAttr.clipRule "evenodd"
            , SvgAttr.d "M0.474325 18.8419C0.278886 18.907 0.0929519 18.7211 0.158098 18.5257L0.92532 16.224C0.974413 16.0767 1.05712 15.9429 1.1669 15.8331L1.21031 15.7897L2.14645 17L3.20599 17.794L3.16692 17.8331C3.05714 17.9429 2.92332 18.0256 2.77604 18.0747L0.474325 18.8419ZM3.92677 17.0732L16.1432 4.85676L15 4L14.1277 2.87227L1.92677 15.0732L3.92677 17.0732ZM16.8535 4.14646L14.8535 2.14646L16.2929 0.707108C16.6834 0.316584 17.3166 0.316584 17.7071 0.707108L18.2929 1.2929C18.6834 1.68342 18.6834 2.31658 18.2929 2.70711L16.8535 4.14646Z"
            , SvgAttr.fill "currentColor"
            ]
            []
        ]


delete : Html msg
delete =
    svg
        [ SvgAttr.width "24"
        , SvgAttr.height "24"
        , SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.fill "none"
        ]
        [ path
            [ SvgAttr.d "M4 6.06445C4 5.48763 4.48668 5.03042 5.06238 5.0664L19.0624 5.9414C19.5894 5.97434 20 6.41139 20 6.93945V7.43555C20 8.01237 19.5133 8.46958 18.9376 8.4336L4.93762 7.5586C4.41059 7.52566 4 7.08861 4 6.56055V6.06445Z"
            , SvgAttr.fill "currentColor"
            ]
            []
        , path
            [ SvgAttr.d "M9.30632 3.11942L14.9313 3.80091L14.6956 6.94223L9.06683 6.60125L9.30632 3.11942Z"
            , SvgAttr.stroke "currentColor"
            , SvgAttr.strokeWidth "2"
            ]
            []
        , path
            [ SvgAttr.fillRule "evenodd"
            , SvgAttr.clipRule "evenodd"
            , SvgAttr.d "M12 9L17.7682 9.0804C18.4032 9.08925 18.8692 9.67994 18.73 10.2995L16.5016 20.2192C16.3991 20.6756 15.9938 21 15.5259 21H8.47403C8.00619 21 7.60088 20.6756 7.49834 20.2192L5.26998 10.2995C5.13081 9.67994 5.59681 9.08925 6.23173 9.0804L12 9ZM13.8413 11.9613C13.9243 11.4153 14.4342 11.0399 14.9802 11.1229C15.5262 11.2059 15.9016 11.7158 15.8186 12.2618L14.9172 18.1937C14.8342 18.7397 14.3243 19.1151 13.7783 19.0321C13.2323 18.9491 12.8569 18.4392 12.9399 17.8932L13.8413 11.9613ZM8.98864 11.1502C9.53465 11.0673 10.0445 11.4426 10.1275 11.9886L11.029 17.9205C11.1119 18.4666 10.7366 18.9765 10.1906 19.0594C9.64455 19.1424 9.13465 18.767 9.05167 18.221L8.15023 12.2891C8.06725 11.7431 8.44262 11.2332 8.98864 11.1502Z"
            , SvgAttr.fill "currentColor"
            ]
            []
        ]


plus : Html msg
plus =
    svg
        [ SvgAttr.width "24"
        , SvgAttr.height "24"
        , SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.fill "none"
        ]
        [ Svg.rect
            [ SvgAttr.x "2"
            , SvgAttr.y "10.2622"
            , SvgAttr.width "20"
            , SvgAttr.height "4"
            , SvgAttr.rx "1"
            , SvgAttr.fill "currentColor"
            ]
            []
        , Svg.rect
            [ SvgAttr.x "10"
            , SvgAttr.y "22"
            , SvgAttr.width "20"
            , SvgAttr.height "4"
            , SvgAttr.rx "1"
            , SvgAttr.transform "rotate(-90 10 22)"
            , SvgAttr.fill "currentColor"
            ]
            []
        ]
