effect module LocalStorage
    where { subscription = MySub }
    exposing
        ( Error(..)
        , Event
        , Key
        , Value
        , get
        , getJson
        , set
        , setJson
        , remove
        , clear
        , keys
        , changes
        )

{-|

This library offers simple access to the browser's localstorage via Tasks (to
create, read, update, and delete values) and Subscription (to be notified of
changes). Only String keys and values are allowed.

# Tasks for retrieving
@docs get, getJson, keys

# Tasks for changing
@docs set, setJson, remove, clear

# Subscriptions
@docs changes, Event

# Types for storage
@docs Key, Value

# Errors
@docs Error

-}

import Dom.LowLevel as Dom
import Json.Encode
import Json.Decode exposing (field)
import Native.LocalStorage
import Process
import Task exposing (Task, andThen, succeed, fail)


{-| All keys are String values.
-}
type alias Key =
    String


{-| All stored values are Strings.
-}
type alias Value =
    String


{-| A `LocalStorage.changes` subscription produces `Event` values.
-}
type alias Event =
    { key : Key
    , oldValue : Value
    , newValue : Value
    , url : String
    }


{-| Tasks can produce Error values. See the docs for each such task.
-}
type Error
    = NoStorage
    | UnexpectedPayload String
    | Overflow



-- Convert javascript storage event to Event value.
-- See https://developer.mozilla.org/en-US/docs/Web/API/StorageEvent


event : Json.Decode.Decoder Event
event =
    Json.Decode.map4 Event
        (field "key" Json.Decode.string)
        (field "oldValue" Json.Decode.string)
        (field "newValue" Json.Decode.string)
        (field "url" Json.Decode.string)


{-| Retrieve the string value for a given key. Yields Maybe.Nothing if the key
does not exist in storage. Task will fail with NoStorage if localStorage is not
available in the browser.
-}
get : String -> Task Error (Maybe String)
get =
    Native.LocalStorage.get


{-| Sets the string value for a given key. Task will fail with NoStorage if
localStorage is not available in the browser.
-}
set : String -> String -> Task Error ()
set =
    Native.LocalStorage.set


{-| Removes the value for a given key. Task will fail with NoStorage if
localStorage is not available in the browser.
-}
remove : String -> Task Error ()
remove =
    Native.LocalStorage.remove


{-| Removes all keys and values from localstorage.
-}
clear : Task Error ()
clear =
    Native.LocalStorage.clear


{-| Returns all keys from localstorage.
-}
keys : Task Error (List String)
keys =
    Native.LocalStorage.keys


{-| Converts given JSON value to a string and stores it under specified key.
Task will fail with NoStorage if localStorage is not available in the browser.
-}
setJson : String -> Json.Encode.Value -> Task Error ()
setJson key value =
    Json.Encode.encode 0 value
        |> set key


{-| Retrieves the value for a given key and parses it using the provided JSON
decoder. Yields Maybe.Nothing if the key does not exist in storage. Task will
fail with NoStorage if localStorage is not available in the browser, or
UnexpectedPayload if there was a parsing error.
-}
getJson : Json.Decode.Decoder value -> String -> Task Error (Maybe value)
getJson decoder key =
    let
        decode maybe =
            case maybe of
                Just str ->
                    fromJson decoder str

                Nothing ->
                    succeed Nothing
    in
        (get key) |> andThen decode



-- Decodes json and handles parse errors


fromJson : Json.Decode.Decoder value -> String -> Task Error (Maybe value)
fromJson decoder str =
    case Json.Decode.decodeString decoder str of
        Ok v ->
            succeed (Just v)

        Err msg ->
            fail (UnexpectedPayload msg)


{-| Subscribe to any changes in localstorage. These events occur only when
localstorage is changed in a different window than the one of the current
program. Only the `set` task results in an event; `remove` operations happen
without notice (unfortunately).
-}
changes : (Event -> msg) -> Sub msg
changes tagger =
    subscription (MySub tagger)



-- SUBSCRIPTIONS


type MySub msg
    = MySub (Event -> msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap func (MySub tagger) =
    MySub (tagger >> func)



-- EFFECT MANAGER


type alias State msg =
    Maybe
        { subs : List (MySub msg)
        , pid : Process.Id
        }


init : Task Never (State msg)
init =
    Task.succeed Nothing


(&>) t1 t2 =
    t1 |> Task.andThen (\_ -> t2)



-- All of the SUBSCRIPTIONS and EFFECT MANAGER section code here is standard
-- machinery for an effect manager. The only part specific to LocalStorage is
-- the case below that uses Dom.onWindow.


onEffects : Platform.Router msg Event -> List (MySub msg) -> State msg -> Task Never (State msg)
onEffects router newSubs oldState =
    case ( oldState, newSubs ) of
        ( Nothing, [] ) ->
            Task.succeed Nothing

        ( Just { pid }, [] ) ->
            Process.kill pid
                &> Task.succeed Nothing

        ( Nothing, _ ) ->
            Process.spawn (Dom.onWindow "storage" event (Platform.sendToSelf router))
                |> Task.andThen
                    (\pid ->
                        Task.succeed (Just { subs = newSubs, pid = pid })
                    )

        ( Just { pid }, _ ) ->
            Task.succeed (Just { subs = newSubs, pid = pid })


onSelfMsg : Platform.Router msg Event -> Event -> State msg -> Task Never (State msg)
onSelfMsg router dimensions state =
    case state of
        Nothing ->
            Task.succeed state

        Just { subs } ->
            let
                send (MySub tagger) =
                    Platform.sendToApp router (tagger dimensions)
            in
                Task.sequence (List.map send subs)
                    &> Task.succeed state
