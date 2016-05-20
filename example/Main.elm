module Main exposing (..)

import Basics.Extra exposing (never)
import Dict exposing (Dict)
import Html exposing (Html)
import Html.App as Html
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


type alias Model =
    { keys : List String
    , key : String
    , values : Dict String String
    }


init : ( Model, Cmd Msg )
init =
    ( { key = "default", keys = [], values = Dict.empty }
    , Task.perform Error Keys LocalStorage.keys
    )


type Msg
    = Error LocalStorage.Error
    | SetValue String
    | ValueSet String
    | Key String
    | Keys (List String)
    | KeyValue String (Maybe String)
    | ValueRemoved


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg |> Debug.log "msg" of
        SetValue val ->
            if val == "" then
                model ! [ Task.perform Error (always ValueRemoved) (LocalStorage.remove model.key) ]
            else
                model ! [ Task.perform Error ValueSet (LocalStorage.set model.key val) ]

        ValueSet _ ->
            model ! [ Task.perform Error Keys LocalStorage.keys ]

        ValueRemoved ->
            model ! [ Task.perform Error Keys LocalStorage.keys ]

        Key key ->
            { model | key = key } ! []

        Keys keys ->
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

        Error err ->
            model ! []


requestValues : List String -> Cmd Msg
requestValues keys =
    let
        requestKey key =
            Task.perform Error (KeyValue key) (LocalStorage.get key)
    in
        Cmd.batch <| List.map requestKey keys


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
        , Html.input [ Html.Events.onInput SetValue ] []
        , viewKeyValues model
        ]


viewKeyValues : Model -> Html Msg
viewKeyValues model =
    Html.ol [] (List.map (viewKey model) model.keys)


viewKey : Model -> String -> Html Msg
viewKey model key =
    let
        valDisplay =
            case Dict.get key model.values of
              Just val ->
                  Html.text val
              Nothing ->
                  Html.text "(none)"
    in
      Html.li []
              [ Html.text key
              , Html.text ": "
              , valDisplay
              ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
