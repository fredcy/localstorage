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
        [ viewStorage model ]


viewStorage : Model -> Html Msg
viewStorage model =
    Html.div []
        [ Html.input [ Html.Events.onInput SetEditKey, Html.id "key" ] []
        , Html.input [ Html.Events.onInput (SetValue model.editKey) ] []
        , viewKeyValues model
        , viewClearButton model
        ]


viewKeyValues : Model -> Html Msg
viewKeyValues model =
    Html.ol [] (List.map (viewKey model) model.keys)


valEdit : Key -> Value -> Html Msg
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


viewClearButton : Model -> Html Msg
viewClearButton model =
    Html.button [ Html.Events.onClick Clear ] [ Html.text "clear" ]


{-| Subscribe to localstorage events. These events generally trigger only for
localstorage changes made in *other* windows, not the window of this program.
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    LocalStorage.changes ChangeEvent
