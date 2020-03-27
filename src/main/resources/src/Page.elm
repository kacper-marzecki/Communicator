module Page exposing (..)
import Json.Decode exposing (Decoder, field, string)


type alias Page a =
    { content : List a
    , totalPages : Int
    , totalElements : Int
    , number : Int
    }


pageDecoder : Decoder a -> Decoder (Page a)
pageDecoder contentDecoder =
    Json.Decode.map4 Page
        (Json.Decode.field "content" (Json.Decode.list contentDecoder))
        (Json.Decode.field "totalPages" Json.Decode.int)
        (Json.Decode.field "totalElements" Json.Decode.int)
        (Json.Decode.field "number" Json.Decode.int)
