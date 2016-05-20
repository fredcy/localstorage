effect module LocalStorage
    where { subscription = MySub }
    exposing
        ( Error(..)
        , Event
        , get
        , set
        , remove
        , clear
        , keys
        , changes
        )

{-| TODO

@docs set, get, keys

-}

import Dom.LowLevel as Dom
import Json.Decode exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Native.LocalStorage
import Process
import Task exposing (Task)


type alias Event =
    { key : String
    }


type Error
    = NoStorage


event : Json.Decode.Decoder Event
event =
    Json.Decode.succeed Event
        |: ("key" := Json.Decode.string)


{-| get a value in storage.
-}
get : String -> Task Error (Maybe String)
get =
    Native.LocalStorage.get


{-| Set a value in storage.
-}
set : String -> String -> Task Error String
set =
    Native.LocalStorage.set


remove : String -> Task Error ()
remove =
    Native.LocalStorage.remove


clear : Task Error ()
clear =
    Native.LocalStorage.clear


keys : Task Error (List String)
keys =
    Native.LocalStorage.keys


{-| Subscribe to any changes in storage.
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
