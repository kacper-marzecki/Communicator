module User exposing (..)

import Json.Decode exposing (Decoder, field, string)
import Json.Encode as E


type alias User =
    { username : String
    , token : String
    }


userDecoder : Decoder User
userDecoder =
    Json.Decode.map2 User
        (Json.Decode.field "username" Json.Decode.string)
        (Json.Decode.field "token" Json.Decode.string)


encodeUser : User -> E.Value
encodeUser user =
    E.object
        [ ( "username", E.string user.username )
        , ( "token", E.string user.token )
        ]
