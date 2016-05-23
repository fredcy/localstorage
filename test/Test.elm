module Test exposing (..)

import ElmTest as T
import LocalStorage
import Testable.Cmd
import Testable.TestContext as TC
import Testable.Task


type Msg
    = Error LocalStorage.Error
    | Set LocalStorage.Key LocalStorage.Value
    | SetResult


type alias Model =
    String


component =
    { init = init
    , update = update
    }


init : ( Model, Testable.Cmd.Cmd Msg )
init =
    ( "", Testable.Cmd.none )


update : Msg -> Model -> ( Model, Testable.Cmd.Cmd Msg )
update msg model =
    case msg |> Debug.log "msg" of
        Set key val ->
             Testable.Task.perform Error (always SetResult) (LocalStorage.set key val)

        _ ->
            ( model, Testable.Cmd.none )


all : T.Test
all =
    T.suite "localstorage"
        []


testPut : T.Test
testPut =
    component
        |> TC.startForTest
        |> TC.currentModel
        |> T.assertEqual (Ok "foo")
        |> T.test "put"


main =
    T.runSuiteHtml all
