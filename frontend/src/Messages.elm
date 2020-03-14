module Messages exposing (..)

import Channel exposing (ChannelId)
import Json.Decode exposing (Decoder, field, string)


type alias MessageId =
    Int


type MessagePayload
    = TextMessage String
    | LinkMessage String


type alias Message =
    { id : MessageId
    , channelId : ChannelId
    , payload : MessagePayload
    , username : String
    , timeMillis : Int
    }


type User
    = Anonymous
    | Registered Int String


messagePayloadDecoder : Decoder MessagePayload
messagePayloadDecoder =
    let
        messageTypeDecoder : Decoder String
        messageTypeDecoder =
            Json.Decode.field "messageType" Json.Decode.string

        payloadDecoder : Decoder String
        payloadDecoder =
            Json.Decode.field "payload" Json.Decode.string

        textMessageDecoder : Decoder MessagePayload
        textMessageDecoder =
            Json.Decode.map TextMessage payloadDecoder

        linkMessageDecoder : Decoder MessagePayload
        linkMessageDecoder =
            Json.Decode.map LinkMessage payloadDecoder

        chooseMessageType : String -> Decoder MessagePayload
        chooseMessageType t =
            case t of
                "TEXT_MESSAGE" ->
                    textMessageDecoder

                "LINK_MESSAGE" ->
                    linkMessageDecoder

                _ ->
                    Json.Decode.fail ("Invalid message type: " ++ t)
    in
    messageTypeDecoder
        |> Json.Decode.andThen chooseMessageType



-- \messageType ->
--     Json.Decode.field "payload" <|
--         \payload ->
--             case ( messageType, payload ) of
--                 ( Just "TEXT_MESSAGE", Just p ) ->
--                     TextMessage p
--                         |> Json.Decode.succeed
--                 ( _, Just p ) ->
--                     Json.Decode.succeed (LinkMessage p)


messageDecoder : Decoder Message
messageDecoder =
    Json.Decode.map5 Message
        (Json.Decode.field "id" Json.Decode.int)
        (Json.Decode.field "channelId" Json.Decode.int)
        messagePayloadDecoder
        (Json.Decode.field "username" Json.Decode.string)
        (Json.Decode.field "time" Json.Decode.int)


messagesDecoder : Decoder (List Message)
messagesDecoder =
    Json.Decode.list messageDecoder
