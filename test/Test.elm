module Test exposing (main)

import Html as H exposing (Html)
import Json.Decode exposing (field)
import LocalStorage
import Task


main =
    H.program
        { init = init
        , update = update
        , view = view
        , subscriptions = (always Sub.none)
        }


type alias Model =
    String


type Msg
    = OnSet (Result LocalStorage.Error ())
    | OnGet (Result LocalStorage.Error (Maybe String))
    | OnGetJson (Result LocalStorage.Error (Maybe String))


init : ( Model, Cmd Msg )
init =
    ( "begin"
    , LocalStorage.set "foo" "{ \"bar\": \"blah\" }" |> Task.attempt OnSet
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg |> Debug.log "msg" of
        OnSet result ->
            case result of
                Ok _ ->
                    model ! [ LocalStorage.get "foo" |> Task.attempt OnGet ]

                Err _ ->
                    errorCase msg model

        OnGet result ->
            let
                decoder =
                    (field "bar" Json.Decode.string)
            in
                case result of
                    Ok _ ->
                        model ! [ LocalStorage.getJson decoder "foo" |> Task.attempt OnGetJson ]

                    Err _ ->
                        errorCase msg model

        OnGetJson result ->
            if result == Ok (Just "blah") then
                doneCase msg model
            else
                errorCase msg model


errorCase msg model =
    ( "Error: got msg: " ++ toString msg, Cmd.none )


doneCase msg model =
    ( "Pass", Cmd.none )


view : Model -> Html Msg
view model =
    model |> toString |> H.text
