module Utils exposing (..)

import Html exposing (..)
import Html.Events exposing (keyCode)
import Json.Decode as Json


isNothing : Maybe a -> Bool
isNothing m =
    case m of
        Just _ ->
            False

        Nothing ->
            True


equal : Maybe a -> a -> Bool
equal maybe other =
    case maybe of
        Just something ->
            other == something

        Nothing ->
            False


onEnter : m -> Attribute m
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Json.succeed msg

            else
                Json.fail "not ENTER"
    in
    Html.Events.on "keydown" (Json.andThen isEnter keyCode)


isJust : Maybe a -> Bool
isJust m =
    not (isNothing m)


addIfNotPresent : a -> List a -> List a
addIfNotPresent a list =
    if List.member a list then
        list

    else
        a :: list


listWithout : List a -> List a -> List a
listWithout list without =
    List.filter (\x -> not (List.member x without))
        list
