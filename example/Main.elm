module Main exposing (main)

{-| This is an example of using the LocalStorage APIs.

It displays the current value of the browser's localstorage and allows the user
to create, edit, and delete keys and values.

Model.keys and Model.values are treated here as a copy that tracks localstorage.

Setting a value to empty is treated here as request to remove the key/value pair
from localstorage.

-}

import Basics.Extra exposing (never)
import Dict exposing (Dict)
import Html as H exposing (Html)
import Html.App as H
import Html.Attributes as HA
import Html.Events as HE
import Task
import LocalStorage


main : Program Never
main =
    H.program
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
    , events :
        List LocalStorage.Event
    }


init : ( Model, Cmd Msg )
init =
    ( { editKey = "default", keys = [], values = Dict.empty, events = [] }
    , Task.perform Error SetLocalKeys LocalStorage.keys
    )


type Msg
    = Error LocalStorage.Error
    | SetValue Key Value
    | SetEditKey Key
    | CreateKey
    | SetLocalKeys (List Key)
    | SetLocalValue Key (Maybe Value)
    | Remove Key
    | Clear
    | Refresh
    | ChangeEvent LocalStorage.Event
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg |> Debug.log "msg" of
        SetValue key val ->
            model
                ! [ Task.perform Error
                        (always (SetLocalValue key (Just val)))
                        (LocalStorage.set key val)
                  ]

        Remove key ->
            model ! [ Task.perform Error (always Refresh) (LocalStorage.remove key) ]

        SetEditKey key ->
            { model | editKey = key } ! []

        CreateKey ->
            case model.editKey of
                "" ->
                    model ! []

                _ ->
                    model ! [ Task.perform Error (always Refresh) (LocalStorage.set model.editKey "") ]

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
            let
                -- todo: make this smarter, more selective update
                ( model', cmd' ) =
                    update Refresh model
            in
                { model' | events = event :: model.events }
                    ! [ cmd' ]

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
    H.div []
        [ H.h1 [] [ H.text "LocalStorage example" ]
        , H.h2 [] [ H.text "Create new key and value" ]
        , viewNewEdit model
        , H.h2 [] [ H.text "Current keys and values" ]
        , viewKeyValueTable model
        , H.h2 [] [ H.text "Global changes" ]
        , viewClearButton model
        , H.h2 [] [ H.text "Events" ]
        , H.div []
            [ H.text "Most recent event is listed first. Only events from another window "
            , H.a [ HA.href "/", HA.target "_blank" ] [ H.text "(open one)" ]
            , H.text " will appear."
            ]
        , viewEvents model
        ]


viewNewEdit : Model -> Html Msg
viewNewEdit model =
    H.form [ HA.class "newEdit pure-form" ]
        [ H.fieldset []
            [ H.input
                [ HE.onInput SetEditKey
                , HA.placeholder "new key"
                ]
                []
            , H.button [ HE.onClick CreateKey ] [ H.text "create key" ]
            ]
        ]


viewKeyValueTable : Model -> Html Msg
viewKeyValueTable model =
    H.table [ HA.class "keyValues pure-table" ]
        [ H.thead []
            [ H.tr []
                [ H.td [] [ H.text "key" ]
                , H.td [] [ H.text "value" ]
                , H.td [] []
                ]
            ]
        , H.tbody [] (List.indexedMap (viewTableRow model) model.keys)
        ]


viewTableRow : Model -> Int -> Key -> Html Msg
viewTableRow model rowi key =
    H.tr [ HA.classList [ ( "pure-table-odd", rowi % 2 == 1 ) ] ]
        [ H.td [] [ H.text <| "\"" ++ key ++ "\"" ]
        , H.td [] [ valDisplay model.values key ]
        , H.td [] [ H.button [ HE.onClick (Remove key) ] [ H.text "remove" ] ]
        ]


valEdit : Key -> Value -> Html Msg
valEdit key val =
    H.input
        [ HA.class "valEdit"
        , HE.onInput (SetValue key)
        , HA.value val
        ]
        []


valEditTextarea : Key -> Value -> Html Msg
valEditTextarea key val =
    H.textarea
        [ HA.class "valEdit"
        , HA.cols 40
        , HE.onInput (SetValue key)
        ]
        [ H.text val ]


valDisplay values key =
    case Dict.get key values of
        Just val ->
            valEditTextarea key val

        Nothing ->
            H.text "(none)"


viewClearButton : Model -> Html Msg
viewClearButton model =
    H.button
        [ HE.onClick Clear
        , HA.class "pure-button"
        ]
        [ H.text "clear all" ]


viewEvents : Model -> Html Msg
viewEvents model =
    let
        viewEvent event =
            H.li [] [ H.text (toString event) ]
    in
        H.ul [] (List.map viewEvent model.events)


subscriptions : Model -> Sub Msg
subscriptions model =
    LocalStorage.changes ChangeEvent
