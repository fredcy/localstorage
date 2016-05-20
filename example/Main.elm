module Main exposing (..)

import Basics.Extra exposing (never)
import Html exposing (Html)
import Html.App as Html
import Task
import Storage


main : Program Never
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model = {
      length : Int
    }


init : ( Model, Cmd Msg )
init =
    ( { length = 0 }
    , Task.perform never Length Storage.length
    )


type Msg
    = Length Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg |> Debug.log "msg" of
      Length len ->
          { model | length = len } ! []


view : Model -> Html Msg
view model =
    Html.div [] [ Html.text (toString model) ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
