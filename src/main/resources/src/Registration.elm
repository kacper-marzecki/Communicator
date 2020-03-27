module Registration exposing (..)
import Json.Encode as E

type alias RegistrationFormState =
    { login : String
    , password : String
    , passwordRepeat : String
    }


initRegistrationForm : RegistrationFormState
initRegistrationForm =
        { login = ""
        , password = ""
        , passwordRepeat = ""
        }


encodeRegisterForm : RegistrationFormState -> E.Value
encodeRegisterForm form =
    E.object
        [ ( "username", E.string form.login )
        , ( "password", E.string form.password )
        ]
