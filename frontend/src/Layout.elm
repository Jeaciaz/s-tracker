module Layout exposing (viewContent)

import Html exposing (..)
import Html.Attributes exposing (..)


type alias LayoutParams msg =
    { content : Html msg
    , headerContent : Html msg
    }


viewContent : LayoutParams msg -> Html msg
viewContent { content, headerContent } =
    main_ [ class "px-4 py-8 flex flex-col h-screen dark:bg-slate-700 dark:text-slate-100" ]
        [ div [ class "flex justify-between items-center" ]
            [ h1 [ class "text-4xl" ] [ text "₪ Tracker" ]
            , headerContent
            ]
        , div [ class "mt-6 flex flex-col flex-grow" ]
            [ content
            ]
        ]
