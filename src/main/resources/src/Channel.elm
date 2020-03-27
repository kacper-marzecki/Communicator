module Channel exposing (..)

import Json.Decode exposing (Decoder, field, string)


type alias ChannelId =
    Int


type alias Channel =
    { id : ChannelId
    , name : String
    , users : List String
    }


channelDecoder : Decoder Channel
channelDecoder =
    Json.Decode.map3 Channel
        (Json.Decode.field "id" Json.Decode.int)
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "users" (Json.Decode.list Json.Decode.string))


conversationsDecoder : Decoder (List Channel)
conversationsDecoder =
    Json.Decode.list channelDecoder
