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
import String
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
    , errors :
        List LocalStorage.Error
    }


init : ( Model, Cmd Msg )
init =
    ( { editKey = "default"
      , keys = []
      , values = Dict.empty
      , events = []
      , errors = []
      }
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
    | TryToOverflow
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

        TryToOverflow ->
            let
                testVal =
                    stringPower 23 "xx"

                _ =
                    Debug.log "overflow test len" (String.length testVal)
            in
                model ! [ LocalStorage.set "overflowtest" testVal |> Task.perform Error (always Refresh) ]

        Error err ->
            { model | errors = err :: model.errors } ! []

        NoOp ->
            model ! []


stringPower exp str =
    if exp <= 1 then
        str
    else
        stringPower (exp - 1) (str ++ str)


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
        , H.br [] []
        , viewOverflowButton model
        , H.h2 [] [ H.text "Errors" ]
        , viewErrors model
        , H.h2 [] [ H.text "Events" ]
        , H.div []
            [ H.text "Most recent event is listed first. Only events from another window "
            , H.a [ HA.href "/", HA.target "_blank" ] [ H.text "(open one here)" ]
            , H.text " will appear."
            ]
        , viewEvents model
        ]


viewNewEdit : Model -> Html Msg
viewNewEdit model =
    H.div [ HA.class "newEdit pure-form" ]
        [ H.input
            [ HE.onInput SetEditKey
            , HA.placeholder "new key"
            ]
            []
        , H.button [ HE.onClick CreateKey ] [ H.text "create key" ]
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
        , H.tbody []
            (model.keys
                |> List.filter ((/=) "overflowtest")
                |> List.indexedMap (viewTableRow model)
            )
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
        [ H.text "clear all keys and values" ]


viewOverflowButton : Model -> Html Msg
viewOverflowButton model =
    H.button
        [ HE.onClick TryToOverflow
        , HA.class "pure-button"
        ]
        [ H.text "try to overflow" ]


viewEvents : Model -> Html Msg
viewEvents model =
    let
        viewEvent event =
            H.li [] [ H.text (toString event) ]
    in
        H.ul [] (List.map viewEvent model.events)


viewErrors : Model -> Html Msg
viewErrors model =
    let
        errorStr error =
            case error of
                LocalStorage.NoStorage ->
                    "NoStorage"

                LocalStorage.Overflow ->
                    "Overflow"

                LocalStorage.UnexpectedPayload str ->
                    "Unexpected Payload: " ++ str

        viewError error =
            H.li [] [ H.text (errorStr error) ]
    in
        H.ul [] (List.map viewError model.errors)


subscriptions : Model -> Sub Msg
subscriptions model =
    LocalStorage.changes ChangeEvent
