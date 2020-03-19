module Utils exposing (..)

import Html exposing (..)
import Html.Events exposing (keyCode)
import Json.Decode as Json
import Regex as Regex
import Time


getOrDefault : Maybe a -> a -> a
getOrDefault maybe default =
    case maybe of
        Just x ->
            x

        Nothing ->
            default


isNothing : Maybe a -> Bool
isNothing m =
    case m of
        Just _ ->
            False

        Nothing ->
            True


last : List a -> Maybe a
last list =
    case list of
        x :: [] ->
            Just x

        x :: xs ->
            last xs

        [] ->
            Nothing


toMonthInt : Time.Month -> Int
toMonthInt month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12


dateStringFromEpochSecondsmessage : Int -> String
dateStringFromEpochSecondsmessage seconds =
    let
        zone =
            Time.utc

        time =
            Time.millisToPosix <| 1000 * seconds

        year =
            String.fromInt <| Time.toYear zone time

        month =
            String.fromInt <| toMonthInt <| Time.toMonth zone time

        day =
            String.fromInt <| Time.toDay zone time

        hour =
            String.fromInt <| Time.toHour zone time

        minute =
            String.fromInt <| Time.toMinute zone time

        second =
            String.fromInt <| Time.toSecond zone time
    in
    String.join "." [ year, month, day ] ++ "  " ++ String.join ":" [ hour, minute, second ]


and : Bool -> Bool -> Bool
and a b =
    a && b


anyTrue : a -> List (a -> Bool) -> Bool
anyTrue checked predicates =
    let
        check pred acc =
            pred checked || acc
    in
    List.foldl check False predicates


startsLikeALink : String -> Bool
startsLikeALink m =
    anyTrue m [ String.startsWith "http", String.startsWith "https", String.startsWith "www" ]


isLink : String -> Bool
isLink m =
    (String.split m " " |> List.length) == 1 && startsLikeALink m


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


createYoutubeEmbeddedLink : String -> Maybe String
createYoutubeEmbeddedLink link =
    let
        ytRegex =
            "v=.*(?=&)*"

        reg =
            case Regex.fromString ytRegex of
                Just m ->
                    m

                Nothing ->
                    Regex.never
    in
    case List.head (link |> Regex.find reg) of
        Just match ->
            let
                dupa =
                    match.match
                        |> String.dropLeft 2
                        |> (\it ->
                                if String.endsWith "&" it then
                                    String.dropRight 1 it

                                else
                                    it
                           )
            in
            Just <| "//www.youtube.com/embed/" ++ dupa

        _ ->
            Nothing


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
