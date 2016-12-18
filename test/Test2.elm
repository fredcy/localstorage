module Test2 exposing (main)

import Html as H exposing (Html)
import Json.Decode exposing (field)
import LocalStorage
import Task exposing (Task)


main =
    H.program
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
    = OnClear (Result LocalStorage.Error ())
    | OnSet (Result LocalStorage.Error ())
    | OnGet (Result LocalStorage.Error (Maybe String))
    | OnRemove (Result LocalStorage.Error ())
    | OnKeys (Result LocalStorage.Error (List LocalStorage.Key))


{-| A sequence of commands and expected resulting messages
-}
sequence : List ( Cmd Msg, Msg )
sequence =
    [ ( LocalStorage.clear |> Task.attempt OnClear
      , OnClear (Ok ())
      )
    , ( LocalStorage.set "foo" "bar" |> Task.attempt OnSet
      , OnSet (Ok ())
      )
    , ( LocalStorage.get "foo" |> Task.attempt OnGet
      , OnGet (Ok (Just "bar"))
      )
    , ( LocalStorage.set "foojson" "{ \"bar\": \"blatz\" }" |> Task.attempt OnSet
      , OnSet (Ok ())
      )
    , ( LocalStorage.getJson decoder "foojson" |> Task.attempt OnGet
      , OnGet (Ok (Just "blatz"))
      )
    , ( LocalStorage.keys |> Task.attempt (OnKeys << (Result.map List.sort))
      , OnKeys (Ok [ "foo", "foojson" ])
      )
    , ( LocalStorage.remove "foo" |> Task.attempt OnRemove
      , OnRemove (Ok ())
      )
    , ( LocalStorage.keys |> Task.attempt (OnKeys << (Result.map List.sort))
      , OnKeys (Ok [ "foojson" ])
      )
    , ( LocalStorage.get "foo" |> Task.attempt OnGet
      , OnGet (Ok Nothing)
      )
    ]


decoder : Json.Decode.Decoder String
decoder =
    (field "bar" Json.Decode.string)


init : ( Model, Cmd Msg )
init =
    ( Model "running" Nothing sequence
    , nextCmd sequence
    )


nextCmd : List ( Cmd Msg, a ) -> Cmd Msg
nextCmd sequence =
    List.head sequence |> Maybe.map Tuple.first |> Maybe.withDefault Cmd.none


update msg model =
    let
        ( model_, cmd ) =
            checkMsg (Debug.log "msg" msg) model
    in
        ( model_, cmd )


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
                    cmd_ =
                        nextCmd rest

                    message =
                        if cmd_ == Cmd.none then
                            "passed"
                        else
                            "continuing"
                in
                    ( { model | sequence = rest, message = message }, cmd_ )
            else
                let
                    testError =
                        Just ( cmd, expected, msg )
                in
                    ( { model | message = "failed", testError = testError }, Cmd.none )

        _ ->
            ( { model | message = "done" }, Cmd.none )
