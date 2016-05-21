effect module LocalStorage
    where { subscription = MySub }
    exposing
        ( Error(..)
        , Event
        , Key
        , Value
        , get
        , set
        , remove
        , clear
        , keys
        , changes
        )

{-|

This library offers simple access to the browser's localstorage via Commands (to
create, read, update, and delete values) and Subscription (to be notified of
changes). Only String keys and values are allowed.

# Commands for retrieving
@docs get, keys

# Commands for changing
@docs set, remove, clear

# Subscriptions
@docs changes, Event

# Types for storage
@docs Key, Value

# Errors
@docs Error

-}

import Dom.LowLevel as Dom
import Json.Decode exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Native.LocalStorage
import Process
import Task exposing (Task)


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


{-| Commands can produce Error values. The only comprised value is `NoStorage`
for when localstorage is not available at all in the current window.
-}
type Error
    = NoStorage



-- Convert javascript storage event to Event value.
-- See https://developer.mozilla.org/en-US/docs/Web/API/StorageEvent


event : Json.Decode.Decoder Event
event =
    Json.Decode.succeed Event
        |: ("key" := Json.Decode.string)
        |: ("oldValue" := Json.Decode.string)
        |: ("newValue" := Json.Decode.string)
        |: ("url" := Json.Decode.string)


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


{-| Subscribe to any changes in localstorage. These events occur only when
localstorage is changed in a different window than the one of the current
program. Only the `set` command results in an event; `remove` operations happen
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
    t1 `Task.andThen` \_ -> t2



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
                `Task.andThen` \pid ->
                                Task.succeed (Just { subs = newSubs, pid = pid })

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
