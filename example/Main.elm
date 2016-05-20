module Main exposing (..)

import Basics.Extra exposing (never)
import Html exposing (Html)
import Html.App as Html
import Html.Events
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


type alias Model =
    { length : Int
    , keys : List String
    , key : String
    }


init : ( Model, Cmd Msg )
init =
    ( { length = 0, key = "default", keys = [] }
    , Cmd.batch
        [ Task.perform Error Length Storage.length
        , Task.perform Error Keys Storage.keys
        ]
    )


type Msg
    = Length Int
    | Value String
    | ValueSet String
    | Error Storage.Error
    | Key String
    | Keys (List String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg |> Debug.log "msg" of
        Length len ->
            { model | length = len } ! []

        Value val ->
            model ! [ Task.perform Error ValueSet (Storage.set model.key val) ]

        ValueSet _ ->
            model ! [ Task.perform Error Length Storage.length ]

        Key key ->
            { model | key = key } ! []

        Keys keys ->
            { model | keys = keys } ! []

        Error err ->
            model ! []


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.text (toString model)
        , viewStorage model
        ]


viewStorage : Model -> Html Msg
viewStorage model =
    Html.div []
        [ Html.input [ Html.Events.onInput Key ] []
        , Html.input [ Html.Events.onInput Value ] []
        , viewKeyValues model
        ]


viewKeyValues : Model -> Html Msg
viewKeyValues model =
    Html.ol [] (List.map viewKey model.keys)


viewKey : String -> Html Msg
viewKey key =
    Html.li [] [ Html.text key ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
