module Conversation exposing (..)

import Json.Decode exposing (Decoder, field, string)


type alias ConversationId =
    Int


type alias Conversation =
    { id : ConversationId
    , name : String
    , pending : Bool
    }


type alias NewConversationFormState =
    { addedFriends : List String
    , conversationName : String
    }


initNewConversationForm : NewConversationFormState
initNewConversationForm =
    { addedFriends = []
    , conversationName = ""
    }


conversationDecoder : Decoder Conversation
conversationDecoder =
    Json.Decode.map3 Conversation
        (Json.Decode.field "id" Json.Decode.int)
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "pending" Json.Decode.bool)


conversationsDecoder : Decoder (List Conversation)
conversationsDecoder =
    Json.Decode.list conversationDecoder
