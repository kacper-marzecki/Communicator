module Message exposing (..)
import Json.Decode exposing (Decoder, field, string)


type alias Message =
    { username : String }

messageDecoder : Decoder Message
messageDecoder =
    Json.Decode.map Message
        (Json.Decode.field "username" Json.Decode.string)

messagesDecoder : Decoder (List Message)
messagesDecoder =
    Json.Decode.list messageDecoder
