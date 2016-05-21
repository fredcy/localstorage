module Main exposing (main)

{-| This is an example of using the LocalStorage APIs.

It displays the current value of the browser's localstorage and allows the user
to create, edit, and delete keys and values.

The Model.keys and Model.values values are treated here as a shadow of
localstorage.

Setting a value to empty is treated here as request to remove the key/value pair
from localstorage.

-}

import Basics.Extra exposing (never)
import Dict exposing (Dict)
import Html exposing (Html)
import Html.App as Html
import Html.Attributes as Html
import Html.Events as Html
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
    LocalStorage.Key


type alias Value =
    LocalStorage.Value


type alias Model =
    { keys :
        List Key
        -- all keys in LocalStorage
    , editKey :
        Key
        -- key to be edited, possibly created if new
    , values :
        Dict Key Value
        -- a shadow of the keys and values in LocalStorate
    }


init : ( Model, Cmd Msg )
init =
    ( { editKey = "default", keys = [], values = Dict.empty }
    , Task.perform Error SetLocalKeys LocalStorage.keys
    )


type Msg
    = Error LocalStorage.Error
    | SetValue Key Value
    | SetEditKey Key
    | SetLocalKeys (List Key)
    | SetLocalValue Key (Maybe Value)
    | Clear
    | Refresh
    | ChangeEvent LocalStorage.Event
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg |> Debug.log "msg" of
        SetValue key val ->
            if val == "" then
                model ! [ Task.perform Error (always Refresh) (LocalStorage.remove key) ]
            else
                -- Could optimize this to avoid full refresh, but have to handle
                -- case of new key too.
                model ! [ Task.perform Error (always Refresh) (LocalStorage.set key val) ]

        SetEditKey key ->
            { model | editKey = key } ! []

        SetLocalKeys keys ->
            { model | keys = keys } ! [ requestValues keys ]

        SetLocalValue key valueMaybe ->
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
            model ! [ Task.perform Error SetLocalKeys LocalStorage.keys ]

        ChangeEvent event ->
            model ! []

        Error err ->
            model ! []

        NoOp ->
            model ! []


{-| Create a command to request the values from localstorage of the given keys.
-}
requestValues : List Key -> Cmd Msg
requestValues keys =
    let
        requestKey key =
            Task.perform Error (SetLocalValue key) (LocalStorage.get key)
    in
        Cmd.batch <| List.map requestKey keys


view : Model -> Html Msg
view model =
    Html.div []
        [ viewNewEdit model
        , viewKeyValueTable model
        , viewClearButton model
        ]


viewNewEdit : Model -> Html Msg
viewNewEdit model =
    Html.div [ Html.class "newEdit pure-form" ]
        [ Html.label [ Html.for "key" ] [ Html.text "key" ]
        , Html.input [ Html.onInput SetEditKey, Html.id "key" ] []
        , Html.label [ Html.for "value" ] [ Html.text "value" ]
        , Html.input [ Html.onInput (SetValue model.editKey), Html.id "value" ] []
        ]


viewKeyValueTable : Model -> Html Msg
viewKeyValueTable model =
    Html.table [ Html.class "keyValues pure-table" ]
        [ Html.thead []
            [ Html.tr []
                [ Html.td [] [ Html.text "key" ]
                , Html.td [] [ Html.text "value" ]
                ]
            ]
        , Html.tbody [] (List.map (viewTableRow model) model.keys)
        ]


viewTableRow : Model -> Key -> Html Msg
viewTableRow model key =
    Html.tr []
        [ Html.td [] [ Html.text <| "\"" ++ key ++ "\"" ]
        , Html.td [] [ valDisplay model.values key ]
        ]


valEdit : Key -> Value -> Html Msg
valEdit key val =
    Html.input
        [ Html.class "valEdit"
        , Html.onInput (SetValue key)
        , Html.value val
        ]
        []


valDisplay values key =
    case Dict.get key values of
        Just val ->
            valEdit key val

        Nothing ->
            Html.text "(none)"


viewClearButton : Model -> Html Msg
viewClearButton model =
    Html.button
        [ Html.onClick Clear
        , Html.class "pure-button"
        ]
        [ Html.text "clear all" ]


{-| Subscribe to localstorage events. These events generally trigger only for
localstorage changes made in *other* windows, not the window of this program.
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    LocalStorage.changes ChangeEvent
