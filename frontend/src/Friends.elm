module Friends exposing (..)

import Json.Decode exposing (Decoder, field, string)
import Json.Encode as E


type alias FriendId = Int

type alias Friend =
    { id : FriendId
    , requester : String
    , target : String
    , pending : Bool
    }

friendDecoder: Decoder Friend
friendDecoder = 
    Json.Decode.map4 Friend
        (Json.Decode.field "id" Json.Decode.int)
        (Json.Decode.field "requester" Json.Decode.string)
        (Json.Decode.field "target" Json.Decode.string)
        (Json.Decode.field "pending" Json.Decode.bool)

friendListDecoder : Decoder (List Friend)
friendListDecoder =
    Json.Decode.list friendDecoder


type alias FriendsSiteState =
    { addFriendInput : String }



encodeRespondToFriendRequest: Bool -> E.Value
encodeRespondToFriendRequest response = 
    E.object [
        ("accept", E.bool response)
    ]
initFriendsSiteState : FriendsSiteState
initFriendsSiteState =
    { addFriendInput = ""
    }


encodeAddFriendRequest: FriendsSiteState -> E.Value
encodeAddFriendRequest formState 
    = E.object [
        ("target", E.string formState.addFriendInput)
    ]