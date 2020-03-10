module Utils exposing (..)


isNothing : Maybe a -> Bool
isNothing m =
    case m of
        Just _ ->
            False

        Nothing ->
            True


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
