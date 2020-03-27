module Login exposing (..)
import Json.Encode as E


type alias LoginFormState =
    { login : String
    , password : String
    }


newLoginForm : LoginFormState
newLoginForm =
    { login = ""
    , password = ""
    }

encodeLoginForm : LoginFormState -> E.Value
encodeLoginForm form =
    E.object
        [ ( "username", E.string form.login )
        , ( "password", E.string form.password )
        ]
