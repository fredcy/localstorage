effect module Storage
    where { subscription = MySub }
    exposing
        ( Error(..)
        , get
        , set
        , keys
        , changes
        )

{-| TODO

@docs set, get, keys

-}

import Dom.LowLevel as Dom
import Json.Decode exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Native.Storage
import Process
import Task exposing (Task)


type alias StorageEvent =
    { key : String
    }


type Error
    = NoStorage


storageEvent : Json.Decode.Decoder StorageEvent
storageEvent =
    Json.Decode.succeed StorageEvent
        |: ("key" := Json.Decode.string)


{-| get a value in storage.
-}
get : String -> Task Error (Maybe String)
get =
    Native.Storage.get


{-| Set a value in storage.
-}
set : String -> String -> Task Error String
set =
    Native.Storage.set


keys : Task Error (List String)
keys =
    Native.Storage.keys


{-| Subscribe to any changes in storage.
-}
changes : (StorageEvent -> msg) -> Sub msg
changes tagger =
    subscription (MySub tagger)



-- SUBSCRIPTIONS


type MySub msg
    = MySub (StorageEvent -> msg)


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


onEffects : Platform.Router msg StorageEvent -> List (MySub msg) -> State msg -> Task Never (State msg)
onEffects router newSubs oldState =
    case ( oldState, newSubs ) of
        ( Nothing, [] ) ->
            Task.succeed Nothing

        ( Just { pid }, [] ) ->
            Process.kill pid
                &> Task.succeed Nothing

        ( Nothing, _ ) ->
            Process.spawn (Dom.onDocument "onstorage" storageEvent (Platform.sendToSelf router))
                `Task.andThen` \pid ->
                                Task.succeed (Just { subs = newSubs, pid = pid })

        ( Just { pid }, _ ) ->
            Task.succeed (Just { subs = newSubs, pid = pid })


onSelfMsg : Platform.Router msg StorageEvent -> StorageEvent -> State msg -> Task Never (State msg)
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
