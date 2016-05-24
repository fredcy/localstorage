module Test2 exposing (main)

import Html as H exposing (Html)
import Html.App
import Json.Decode exposing ((:=))
import LocalStorage
import Task exposing (Task)


main =
    Html.App.program
        { init = init
        , update = update
        , view = view
        , subscriptions = (always Sub.none)
        }


type alias Model =
    { message : String
    , testError : Maybe ( Cmd Msg, Msg, Msg )
    , sequence : List ( Cmd Msg, Msg )
    }


type Msg
    = Error LocalStorage.Error
    | Clear ()
    | SetResult ()
    | GetResult (Maybe String)
    | RemoveResult ()
    | KeysResult (List LocalStorage.Key)


{-| A sequence of commands and expected resulting messages
-}
sequence : List ( Cmd Msg, Msg )
sequence =
    [ ( LocalStorage.clear |> Task.perform Error Clear
      , Clear ()
      )
    , ( LocalStorage.set "foo" "bar" |> Task.perform Error SetResult
      , SetResult ()
      )
    , ( LocalStorage.get "foo" |> Task.perform Error GetResult
      , GetResult (Just "bar")
      )
    , ( LocalStorage.set "foojson" "{ \"bar\": \"blatz\" }" |> Task.perform Error SetResult
      , SetResult ()
      )
    , ( LocalStorage.getJson decoder "foojson" |> Task.perform Error GetResult
      , GetResult (Just "blatz")
      )
    , ( LocalStorage.keys |> Task.perform Error (KeysResult << List.sort)
      , KeysResult [ "foo", "foojson" ]
      )
    , ( LocalStorage.remove "foo" |> Task.perform Error RemoveResult
      , RemoveResult ()
      )
    , ( LocalStorage.keys |> Task.perform Error (KeysResult << List.sort)
      , KeysResult [ "foojson" ]
      )
    , ( LocalStorage.get "foo" |> Task.perform Error GetResult
      , GetResult Nothing
      )
    ]


decoder : Json.Decode.Decoder String
decoder =
    ("bar" := Json.Decode.string)


init : ( Model, Cmd Msg )
init =
    ( Model "running" Nothing sequence
    , nextCmd sequence
    )


nextCmd : List ( Cmd Msg, a ) -> Cmd Msg
nextCmd sequence =
    List.head sequence |> Maybe.map fst |> Maybe.withDefault Cmd.none


update msg model =
    let
        ( model', cmd ) =
            checkMsg (Debug.log "msg" msg) model
    in
        ( model', cmd )


view : Model -> Html Msg
view model =
    H.div []
        [ model.message |> H.text
        , viewError model
        ]


viewError : Model -> Html Msg
viewError model =
    case model.testError of
        Just ( cmd, expected, got ) ->
            let
                item label value =
                    H.li []
                        [ H.text label
                        , H.code [] [ H.text <| toString value ]
                        ]
            in
                H.ul []
                    [ item "expected: " expected
                    , item "but got: " got
                    ]

        Nothing ->
            H.text ""


checkMsg : Msg -> Model -> ( Model, Cmd Msg )
checkMsg msg model =
    case model.sequence of
        ( cmd, expected ) :: rest ->
            if msg == expected then
                let
                    cmd' =
                        nextCmd rest

                    message =
                        if cmd' == Cmd.none then
                            "passed"
                        else
                            "continuing"
                in
                    ( { model | sequence = rest, message = message }, cmd' )
            else
                let
                    testError =
                        Just ( cmd, expected, msg )
                in
                    ( { model | message = "failed", testError = testError }, Cmd.none )

        _ ->
            ( { model | message = "done" }, Cmd.none )
