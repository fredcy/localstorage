module Main exposing (..)

import Html exposing (Html)
import Html.App as Html
import Window
import Native.Window


main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init =
    ( { width = 0, height = 0 }, Cmd.none )


update msg model =
    model ! []


view model =
    Html.div [] [ Html.text (toString model) ]


subscriptions model =
    Sub.none
