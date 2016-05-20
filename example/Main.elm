module Main exposing (..)

import Basics.Extra exposing (never)
import Html exposing (Html)
import Html.App as Html
import Window
import Task


main : Program Never
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    Window.Size


init : ( Model, Cmd Msg )
init =
    ( { width = 0, height = 0 }
    , Task.perform never WindowSize Window.size
    )


type Msg
    = WindowSize Window.Size


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WindowSize size ->
            size ! []


view : Model -> Html Msg
view model =
    Html.div [] [ Html.text (toString model) ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Window.resizes WindowSize
