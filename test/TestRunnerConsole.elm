port module TestRunnerConsole exposing (..)

import Json.Encode exposing (Value)
import Test.Runner.Node exposing (run, TestProgram)
import Test exposing (Test)
import Expect exposing (Expectation)
import LocalStorage


main : TestProgram
main =
    run emit runtimeExcpetionsTest


runtimeExcpetionsTest : Test
runtimeExcpetionsTest =
    let
        _ =
            [ LocalStorage.remove ""
            , LocalStorage.clear
            ]

        _ =
            LocalStorage.get ""
    in
        Test.test "This test merely test for runtime exceptions" <|
            \() ->
                Expect.pass


port emit : ( String, Value ) -> Cmd msg
