module Test exposing (main)

import Html as H exposing (Html)
import Html.App
import Json.Decode exposing ((:=))
import LocalStorage
import Task


main =
    Html.App.program
        { init = init
        , update = update
        , view = view
        , subscriptions = (always Sub.none)
        }


type alias Model =
    String


type Msg
    = NoOp
    | Error LocalStorage.Error
    | SetResult
    | GetResult (Maybe String)
    | GetJsonResult (Maybe String)


init : ( Model, Cmd Msg )
init =
    ( "begin"
    , LocalStorage.set "foo" "{ \"bar\": \"blah\" }" |> Task.perform Error (always SetResult)
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg |> Debug.log "msg" of
        SetResult ->
            ( model
            , LocalStorage.get "foo" |> Task.perform Error (GetResult)
            )

        GetResult valMaybe ->
            let
                decoder =
                    ("bar" := Json.Decode.string)
            in
                case valMaybe of
                    Just val ->
                        ( model
                        , LocalStorage.getJson decoder "foo" |> Task.perform Error GetJsonResult
                        )

                    _ ->
                        errorCase msg model

        GetJsonResult valMaybe ->
            if valMaybe == Just "blah" then
                doneCase msg model
            else
                errorCase msg model

        _ ->
            errorCase msg model


errorCase msg model =
    ( "Error: got msg: " ++ toString msg, Cmd.none )


doneCase msg model =
    ( "Pass", Cmd.none )


view : Model -> Html Msg
view model =
    model |> toString |> H.text
