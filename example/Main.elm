module Main exposing (..)

import Basics.Extra exposing (never)
import Dict exposing (Dict)
import Html exposing (Html)
import Html.App as Html
import Html.Attributes as Html
import Html.Events
import Task
import LocalStorage


main : Program Never
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Key =
    String


type alias Value =
    String


type alias Model =
    { keys : List Key
    , key : Key
    , values : Dict Key Value
    }


init : ( Model, Cmd Msg )
init =
    ( { key = "default", keys = [], values = Dict.empty }
    , Task.perform Error RequestValues LocalStorage.keys
    )


type Msg
    = Error LocalStorage.Error
    | SetValue Key Value
    | SetKey Value
    | RequestValues (List Key)
    | KeyValue Key (Maybe Value)
    | Clear
    | Refresh
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg |> Debug.log "msg" of
        SetValue key val ->
            if val == "" then
                model ! [ Task.perform Error (always Refresh) (LocalStorage.remove key) ]
            else
                model ! [ Task.perform Error (always Refresh) (LocalStorage.set key val) ]

        SetKey key ->
            { model | key = key } ! []

        RequestValues keys ->
            { model | keys = keys } ! [ requestValues keys ]

        KeyValue key valueMaybe ->
            case valueMaybe of
                Just value ->
                    let
                        values' =
                            Dict.insert key value model.values
                    in
                        { model | values = values' } ! []

                Nothing ->
                    model ! []

        Clear ->
            model ! [ Task.perform Error (always Refresh) LocalStorage.clear ]

        Refresh ->
            model ! [ Task.perform Error RequestValues LocalStorage.keys ]

        Error err ->
            model ! []

        NoOp ->
            model ! []


requestValues : List Key -> Cmd Msg
requestValues keys =
    let
        requestKey key =
            Task.perform Error (KeyValue key) (LocalStorage.get key)
    in
        Cmd.batch <| List.map requestKey keys


view : Model -> Html Msg
view model =
    Html.div []
        [ viewStorage model ]


viewStorage : Model -> Html Msg
viewStorage model =
    Html.div []
        [ Html.input [ Html.Events.onInput SetKey, Html.id "key" ] []
        , Html.input [ Html.Events.onInput (SetValue model.key) ] []
        , viewKeyValues model
        , viewClearButton model
        ]


viewKeyValues : Model -> Html Msg
viewKeyValues model =
    Html.ol [] (List.map (viewKey model) model.keys)


valEdit key val =
    Html.input
        [ Html.class "valEdit"
        , Html.Events.onInput (SetValue key)
        , Html.value val
        ]
        []


viewKey : Model -> Key -> Html Msg
viewKey model key =
    let
        valDisplay =
            case Dict.get key model.values of
                Just val ->
                    valEdit key val

                Nothing ->
                    Html.text "(none)"
    in
        Html.li []
            [ Html.text key
            , Html.text ": "
            , valDisplay
            ]


viewClearButton model =
    Html.button [ Html.Events.onClick Clear ] [ Html.text "clear" ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
