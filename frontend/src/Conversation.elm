module Conversation exposing (..)

import Json.Decode exposing (Decoder, field, string)
import Json.Encode as E


type alias ConversationId =
    Int

type alias ConversationViewFormState = 
    {

    }

initConversationViewForm: ConversationViewFormState
initConversationViewForm = {}

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


encodeCreateConversation : NewConversationFormState -> E.Value
encodeCreateConversation form =
    E.object
        [ ( "name", E.string form.conversationName )
        , ( "usernames", E.list E.string form.addedFriends )
        ]


conversationDecoder : Decoder Conversation
conversationDecoder =
    Json.Decode.map3 Conversation
        (Json.Decode.field "id" Json.Decode.int)
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "pending" Json.Decode.bool)


conversationsDecoder : Decoder (List Conversation)
conversationsDecoder =
    Json.Decode.list conversationDecoder
