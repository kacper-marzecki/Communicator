module Messages exposing (..)

import Channel exposing (ChannelId)
import Json.Decode exposing (Decoder, field, string)
import Json.Encode as E


type alias MessageId =
    Int


type MessagePayload
    = TextMessage String
    | LinkMessage String


type alias Message =
    { id : MessageId
    , channelId : ChannelId
    , payload : String
    , username : String
    , timeMillis : Int
    }


type User
    = Anonymous
    | Registered Int String


encodeSendMessageRequest : String -> Channel.ChannelId -> E.Value
encodeSendMessageRequest message channelId =
    E.object
        [ ( "channelId", E.int channelId )
        , ( "payload", E.string message )
        ]


messageDecoder : Decoder Message
messageDecoder =
    Json.Decode.map5 Message
        (Json.Decode.field "id" Json.Decode.int)
        (Json.Decode.field "channelId" Json.Decode.int)
        (Json.Decode.field "payload" Json.Decode.string)
        (Json.Decode.field "username" Json.Decode.string)
        (Json.Decode.field "time" Json.Decode.int)


messagesDecoder : Decoder (List Message)
messagesDecoder =
    Json.Decode.list messageDecoder
