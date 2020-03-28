port module Main exposing (..)

import Browser
import Channel exposing (..)
import Conversation exposing (Conversation, ConversationId, ConversationViewFormState, NewConversationFormState, conversationsDecoder, encodeCreateConversation, initConversationViewForm, initNewConversationForm)
import Dict exposing (Dict)
import Friends exposing (Friend, FriendId, FriendsSiteState, encodeRespondToFriendRequest, friendDecoder, initFriendsSiteState)
import Html exposing (Html, a, div, h1, i, img, input, nav, td, text, tr)
import Html.Attributes exposing (attribute, class, src, title)
import Html.Events exposing (onClick, onInput)
import Http
import Info exposing (..)
import Json.Decode exposing (Decoder, field, string)
import Json.Encode as E
import Login exposing (LoginFormState, encodeLoginForm, newLoginForm)
import Messages exposing (Message, MessagePayload(..), messageDecoder)
import Page exposing (Page, pageDecoder)
import Process
import Registration exposing (RegistrationFormState, encodeRegisterForm, initRegistrationForm)
import Task
import Terms exposing (..)
import User exposing (User, encodeUser, userDecoder)
import Utils exposing (addIfNotPresent, isNothing, listWithout)



-- PORTS


port copyToClipboard : E.Value -> Cmd msg


port openLink : E.Value -> Cmd msg


port showSnackbarIn : (E.Value -> msg) -> Sub msg


port showSnackbarOut : E.Value -> Cmd msg


port scrollToTheTop : () -> Cmd msg


port scrollMessagesToBottom : () -> Cmd msg


port scrollMessagesToTop : () -> Cmd msg


port saveUser : E.Value -> Cmd msg


port getSavedUser : (E.Value -> msg) -> Sub msg


port connectWs : () -> Cmd msg


port getChannels : () -> Cmd msg


port gotChannel : (E.Value -> msg) -> Sub msg


port gotFriend : (E.Value -> msg) -> Sub msg


port logoutJs : () -> Cmd msg


port deletedFriend : (String -> msg) -> Sub msg


port gotMessage : (E.Value -> msg) -> Sub msg


port gotPreviousMessage : (E.Value -> msg) -> Sub msg


port clearMessageInput : () -> Cmd msg


showSnackbar : String -> Cmd msg
showSnackbar s =
    showSnackbarOut (E.string s)


getToken : Model -> String
getToken model =
    case model.user of
        Just user ->
            user.token

        _ ->
            "falseToken"


languageParam : TermsLanguage -> ( String, String )
languageParam lang =
    ( "language"
    , case lang of
        PL ->
            "PL"

        EN ->
            "EN"
    )


getLatestMessagesFromChannel : Model -> ChannelId -> Cmd Msg
getLatestMessagesFromChannel model channelId =
    authedGet
        { model = model
        , body = Http.emptyBody
        , url = "/conversation/message"
        , params = [ ( "channelId", String.fromInt channelId ) ]
        , expect = Http.expectWhatever NoOp
        }


getPreviousMessages : Model -> ChannelId -> Int -> Cmd Msg
getPreviousMessages model channelId timeMillis =
    authedGet
        { model = model
        , body = Http.emptyBody
        , url = "/conversation/previous_messages"
        , params = [ ( "channelId", String.fromInt channelId ), ( "before", String.fromInt timeMillis ) ]
        , expect = Http.expectWhatever NoOp
        }


login : String -> LoginFormState -> TermsLanguage -> Cmd Msg
login backendApi loginForm language =
    Http.post
        { url = backendApi ++ "/api/auth/login" ++ joinParams [ languageParam language ]
        , expect = Http.expectJson (ApiMessage << LoggedIn) userDecoder
        , body = Http.jsonBody (encodeLoginForm loginForm)
        }


respondToFriendRequest : Int -> Bool -> Model -> Cmd Msg
respondToFriendRequest id response model =
    authedPost
        { model = model
        , url = "/friends/process_request/" ++ String.fromInt id
        , expect = Http.expectWhatever NoOp
        , params = []
        , body = Http.jsonBody (encodeRespondToFriendRequest response)
        }


sendMessage : String -> ChannelId -> Model -> Cmd Msg
sendMessage message channelId model =
    authedPost
        { model = model
        , url = "/conversation/message"
        , expect = Http.expectWhatever NoOp
        , params = []
        , body = Http.jsonBody (Messages.encodeSendMessageRequest message channelId)
        }


authedRequest :
    { model : Model
    , body : Http.Body
    , url : String
    , method : String
    , expect : Http.Expect msg
    , params : List ( String, String )
    }
    -> Cmd msg
authedRequest r =
    let
        authentication =
            getToken r.model
    in
    Http.request
        { method = r.method
        , body = r.body
        , timeout = Nothing
        , tracker = Nothing
        , url = r.model.backendApi ++ r.url ++ joinParams (languageParam r.model.language :: r.params)
        , expect = r.expect
        , headers = [ Http.header "token" authentication ]
        }


joinParams : List ( String, String ) -> String
joinParams params =
    let
        paramEquals =
            List.map (\( a, b ) -> String.join "=" [ a, b ]) params

        paramsString =
            String.join "&" paramEquals
    in
    "?" ++ paramsString


authedGet :
    { model : Model
    , body : Http.Body
    , url : String
    , expect : Http.Expect msg
    , params : List ( String, String )
    }
    -> Cmd msg
authedGet r =
    authedRequest
        { model = r.model
        , body = r.body
        , url = r.url
        , expect = r.expect
        , params = r.params
        , method = "GET"
        }


authedPost :
    { model : Model
    , body : Http.Body
    , url : String
    , expect : Http.Expect msg
    , params : List ( String, String )
    }
    -> Cmd msg
authedPost r =
    authedRequest
        { model = r.model
        , body = r.body
        , url = r.url
        , expect = r.expect
        , method = "POST"
        , params = r.params
        }


testAuth : Model -> Cmd Msg
testAuth model =
    let
        authentication =
            getToken model
    in
    Http.request
        { method = "GET"
        , body = Http.emptyBody
        , timeout = Nothing
        , tracker = Nothing
        , url = model.backendApi ++ "/api/auth/me" ++ joinParams [ languageParam model.language ]
        , expect = Http.expectWhatever AuthTest
        , headers = [ Http.header "token" authentication ]
        }


createConversation : Model -> NewConversationFormState -> Cmd Msg
createConversation model formState =
    authedPost
        { model = model
        , body = Http.jsonBody (encodeCreateConversation formState)
        , url = "/conversation"
        , params = []
        , expect = Http.expectWhatever (GotConversationViewMsg << GotNewConversationFormMsg << CreateConversationResponse)
        }


addNewFriend : Model -> FriendsSiteState -> Cmd Msg
addNewFriend model formState =
    authedPost
        { model = model
        , url = "/friends"
        , params = []
        , expect = Http.expectWhatever NoOp
        , body = Http.jsonBody (Friends.encodeAddFriendRequest formState)
        }


registerUser : String -> RegistrationFormState -> TermsLanguage -> Cmd Msg
registerUser backendApi registerForm language =
    Http.post
        { url = backendApi ++ "/api/auth/register" ++ joinParams [ languageParam language ]
        , expect = Http.expectWhatever (ApiMessage << RegistrationComplete)
        , body = Http.jsonBody (encodeRegisterForm registerForm)
        }


buildMessagesUrl : Model -> Int -> Maybe String
buildMessagesUrl model page =
    let
        url =
            model.backendApi
                ++ "/home/"
                ++ "city"
                ++ "?lowerPrice="
                ++ "&upperPrice="
                ++ "&page="
                ++ String.fromInt page
    in
    Just url


type Site
    = MainSite
    | LoginSite
    | RegistrationSite
    | ConversationSite
    | FriendsSite


type Form
    = LoginForm LoginFormState
    | RegistrationForm RegistrationFormState
    | NewConversationForm NewConversationFormState
    | FriendsSiteForm FriendsSiteState
    | ConversationViewForm ConversationViewFormState


type alias Model =
    { programFlags : ProgramFlags
    , language : TermsLanguage
    , site : Site
    , form : Maybe Form
    , user : Maybe User
    , friends : List Friend
    , loading : Bool
    , menuOpen : Bool
    , conversations : List Conversation
    , channels : Dict Int Channel
    , chosenChannel : Maybe ChannelId
    , messages : List Message
    , errors : List String
    , backendApi : String
    , bottomNotification : Maybe String
    , token : String
    }


init : ProgramFlags -> ( Model, Cmd Msg )
init flags =
    let
        model =
            { programFlags = flags
            , language = PL
            , site = LoginSite
            , user = Nothing
            , form = Just (LoginForm newLoginForm)
            , menuOpen = False
            , loading = False
            , chosenChannel = Nothing
            , friends = []
            , errors = []
            , messages = []
            , backendApi = flags.backendApi
            , bottomNotification = Nothing
            , conversations = []
            , channels = Dict.empty
            , token = ""
            }
    in
    ( model
    , Cmd.batch []
    )



---- UPDATE ----


type ConversationViewMsg
    = ConversationClicked ConversationId
    | MessageInput String
    | ToggleSendOnEnter
    | SendClicked
    | NewConversationClicked
    | GotNewConversationFormMsg NewConversationFormMsg
    | PreviousMessagesClicked


type NewConversationFormMsg
    = AddFriendToConversation String
    | RemoveFriendFromConversation String
    | ChangeConversationName String
    | CreateConversationButtonClicked
    | CreateConversationResponse (Result Http.Error ())
    | CloseNewConversationFormView


type RegisterFormMsg
    = ChangeRegisterPassword String
    | ChangeRegisterRepeatPassword String
    | ChangeRegisterLogin String
    | RegisterButtonClicked


type LoginFormMsg
    = ChangePassword String
    | ChangeLogin String
    | LoginButtonClicked
    | OpenRegistrationSite


type FriendsFormMsg
    = ChangeNewFriendInput String
    | AcceptFriendRequest FriendId
    | DeclineFriendRequest FriendId
    | AddNewFriendButtonClicked


type ApiMsg
    = GetUser
    | OpenLink String
    | GetConversations
    | LoggedIn (Result Http.Error User)
    | GotConversations (Result Http.Error (List Conversation))
    | RegistrationComplete (Result Http.Error ())


type Msg
    = NoOp (Result Http.Error ())
    | ApiMessage ApiMsg
    | GotLoginFormMsg LoginFormMsg
    | GotRegisterFormMsg RegisterFormMsg
    | GotFriendsFormMsg FriendsFormMsg
    | GotConversationViewMsg ConversationViewMsg
    | GotUser (Result Json.Decode.Error User)
    | GotMessage (Result Json.Decode.Error Message)
    | GotPreviousMessage (Result Json.Decode.Error Message)
    | AuthTest (Result Http.Error ())
    | GotFriend (Result Json.Decode.Error Friend)
    | DeletedFriend (Result Json.Decode.Error FriendId)
    | GotChannel (Result Json.Decode.Error Channel)
    | OpenMainSite
    | OpenFriendsSite
    | OpenLoginSite
    | OpenConversationSite
    | SwitchLanguage
    | SignOutClicked
    | BurgerClicked
    | CopyToClipboard String
    | ShowBottomNotification (Result Json.Decode.Error String)
    | HideBottomNotification
    | TestMsg
    | Error String


toogleOpenMenu : Model -> Model
toogleOpenMenu model =
    { model | menuOpen = not model.menuOpen }


addChannel : Model -> Channel -> Model
addChannel model channel =
    if Dict.member channel.id model.channels then
        model

    else
        { model | channels = Dict.insert channel.id channel model.channels }


loginUpdate : LoginFormMsg -> Login.LoginFormState -> Model -> ( Model, Cmd Msg )
loginUpdate msg state model =
    case msg of
        ChangePassword s ->
            let
                newFormState =
                    { state | password = s }
            in
            ( { model | form = Just (LoginForm newFormState) }, Cmd.none )

        ChangeLogin s ->
            let
                newFormState =
                    { state | login = s }
            in
            ( { model | form = Just (LoginForm newFormState) }, Cmd.none )

        LoginButtonClicked ->
            ( model, login model.backendApi state model.language )

        OpenRegistrationSite ->
            ( { model | site = RegistrationSite, form = Just (RegistrationForm initRegistrationForm) }, Cmd.none )


registrationUpdate : RegisterFormMsg -> RegistrationFormState -> Model -> ( Model, Cmd Msg )
registrationUpdate msg state model =
    let
        terms =
            getTerms model.language |> .registerTerms
    in
    case msg of
        ChangeRegisterLogin s ->
            let
                newState =
                    { state | login = s }
            in
            ( { model | form = Just (RegistrationForm newState) }, Cmd.none )

        ChangeRegisterPassword s ->
            let
                newState =
                    { state | password = s }
            in
            ( { model | form = Just (RegistrationForm newState) }, Cmd.none )

        ChangeRegisterRepeatPassword s ->
            let
                newState =
                    { state | passwordRepeat = s }
            in
            ( { model | form = Just (RegistrationForm newState) }, Cmd.none )

        RegisterButtonClicked ->
            let
                cmd =
                    if state.password == state.passwordRepeat then
                        registerUser model.backendApi state model.language

                    else
                        showSnackbar terms.passwordsDontMatch
            in
            ( model, cmd )


apiUpdate : ApiMsg -> Model -> Maybe Form -> ( Model, Cmd Msg )
apiUpdate msg model form =
    let
        terms =
            getTerms model.language
    in
    case msg of
        LoggedIn (Err _) ->
            ( model, showSnackbar terms.cannotSignIn )

        GotConversations (Err _) ->
            ( model, showSnackbar terms.cannotGetConversations )

        RegistrationComplete (Err _) ->
            ( model, showSnackbar terms.cannotRegister )

        RegistrationComplete (Ok _) ->
            update OpenLoginSite model

        LoggedIn (Ok user) ->
            ( { model | user = Just user }, saveUser (encodeUser user) )

        OpenLink link ->
            ( model, openLink (E.string link) )

        GotConversations (Ok conversations) ->
            ( { model | conversations = conversations, loading = False }, Cmd.none )

        _ ->
            ( model, Cmd.none )


friendsUpdate : FriendsFormMsg -> FriendsSiteState -> Model -> ( Model, Cmd Msg )
friendsUpdate msg state model =
    case msg of
        ChangeNewFriendInput s ->
            let
                formState =
                    { state | addFriendInput = s }
            in
            ( { model | form = Just (FriendsSiteForm formState) }, Cmd.none )

        AcceptFriendRequest id ->
            ( model, respondToFriendRequest id True model )

        DeclineFriendRequest id ->
            ( model, respondToFriendRequest id False model )

        AddNewFriendButtonClicked ->
            ( model, addNewFriend model state )


newConversationUpdate : NewConversationFormMsg -> Maybe NewConversationFormState -> Model -> ( Maybe NewConversationFormState, Cmd Msg )
newConversationUpdate msg formState model =
    let
        terms =
            getTerms model.language |> .conversationTerms
    in
    case ( msg, formState ) of
        ( AddFriendToConversation s, Just state ) ->
            ( Just { state | addedFriends = addIfNotPresent s state.addedFriends }, Cmd.none )

        ( RemoveFriendFromConversation s, Just state ) ->
            ( Just { state | addedFriends = List.filter (\f -> f /= s) state.addedFriends }, Cmd.none )

        ( ChangeConversationName s, Just state ) ->
            ( Just { state | conversationName = s }, Cmd.none )

        ( CloseNewConversationFormView, _ ) ->
            ( Nothing, Cmd.none )

        ( CreateConversationResponse (Ok _), _ ) ->
            ( Nothing, Cmd.none )

        ( CreateConversationResponse (Err _), _ ) ->
            ( Nothing, showSnackbar terms.cannotCreateConversation )

        ( CreateConversationButtonClicked, Just state ) ->
            ( Just state, createConversation model state )

        ( _, Nothing ) ->
            ( Nothing, Cmd.none )


insertMessage : Maybe ChannelId -> List Message -> Message -> List Message
insertMessage channelId messages message =
    case channelId of
        Just id ->
            if message.channelId == id && not (List.member message messages) then
                List.sortBy (\m -> m.timeMillis) (message :: messages)

            else
                messages

        Nothing ->
            messages


conversationUpdate : ConversationViewMsg -> Model -> ConversationViewFormState -> ( Model, Cmd Msg )
conversationUpdate msg model state =
    case msg of
        GotNewConversationFormMsg m ->
            let
                ( newConversationForm, cmd ) =
                    newConversationUpdate m state.newConversationFormState model

                newFormState =
                    { state | newConversationFormState = newConversationForm }
            in
            ( { model | form = Just (ConversationViewForm newFormState) }, cmd )

        PreviousMessagesClicked ->
            case ( model.chosenChannel, model.messages ) of
                ( Just id, x :: xs ) ->
                    ( model, getPreviousMessages model id x.timeMillis )

                ( _, _ ) ->
                    ( model, Cmd.none )

        NewConversationClicked ->
            let
                newConversationForm =
                    initNewConversationForm

                newFormState =
                    { state | newConversationFormState = Just newConversationForm }
            in
            ( { model | form = Just (ConversationViewForm newFormState) }, Cmd.none )

        ConversationClicked id ->
            ( { model | chosenChannel = Just id, messages = [] }, getLatestMessagesFromChannel model id )

        MessageInput s ->
            let
                newState =
                    { state | messageInput = s }
            in
            ( { model | form = Just (ConversationViewForm newState) }, Cmd.none )

        ToggleSendOnEnter ->
            let
                newState =
                    { state | sendOnEnter = not state.sendOnEnter }
            in
            ( { model | form = Just (ConversationViewForm newState) }, Cmd.none )

        SendClicked ->
            case model.chosenChannel of
                Just id ->
                    let
                        newState =
                            { state | messageInput = "" }
                    in
                    ( { model | form = Just <| ConversationViewForm newState }, Cmd.batch [ sendMessage state.messageInput id model, clearMessageInput () ] )

                Nothing ->
                    ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        terms =
            getTerms model.language
    in
    case ( msg, model.form ) of
        ( ApiMessage x, form ) ->
            apiUpdate x model form

        ( GotConversationViewMsg x, Just (ConversationViewForm state) ) ->
            conversationUpdate x model state

        ( GotRegisterFormMsg m, Just (RegistrationForm state) ) ->
            registrationUpdate m state model

        ( GotLoginFormMsg m, Just (LoginForm state) ) ->
            loginUpdate m state model

        ( GotFriendsFormMsg m, Just (FriendsSiteForm state) ) ->
            friendsUpdate m state model

        ( GotMessage (Ok m), _ ) ->
            let
                cmd =
                    if Utils.equal model.chosenChannel m.channelId then
                        scrollMessagesToBottom ()

                    else
                        Cmd.none
            in
            ( { model | messages = insertMessage model.chosenChannel model.messages m }, cmd )

        ( GotPreviousMessage (Ok m), _ ) ->
            let
                cmd =
                    if Utils.equal model.chosenChannel m.channelId then
                        scrollMessagesToTop ()

                    else
                        Cmd.none
            in
            ( { model | messages = insertMessage model.chosenChannel model.messages m }, cmd )

        ( GotUser (Ok user), _ ) ->
            let
                newModel =
                    { model | user = Just user, site = MainSite, menuOpen = False }
            in
            ( newModel, testAuth newModel )

        ( AuthTest (Ok ()), _ ) ->
            ( model, connectWs () )

        ( AuthTest (Err _), _ ) ->
            ( { model | site = LoginSite, user = Nothing, form = Just (LoginForm newLoginForm), menuOpen = False }, showSnackbar terms.cannotSignIn )

        ( GotFriend (Ok friend), _ ) ->
            let
                newFriends =
                    if List.member friend model.friends then
                        model.friends

                    else
                        friend :: model.friends
            in
            ( { model | friends = newFriends }, Cmd.none )

        ( DeletedFriend (Ok id), _ ) ->
            let
                newFriends =
                    List.filter (\f -> not (f.id == id)) model.friends
            in
            ( { model | friends = newFriends }, Cmd.none )

        ( OpenMainSite, _ ) ->
            ( { model | menuOpen = False, site = MainSite }, Cmd.none )

        ( OpenFriendsSite, _ ) ->
            ( { model | site = FriendsSite, form = Just (FriendsSiteForm initFriendsSiteState) }, Cmd.none )

        ( GotChannel (Ok channel), _ ) ->
            ( addChannel model channel, Cmd.none )

        ( OpenLoginSite, _ ) ->
            ( { model | site = LoginSite, form = Just (LoginForm newLoginForm), menuOpen = False }, Cmd.none )

        ( OpenConversationSite, _ ) ->
            ( { model | site = ConversationSite, form = Just (ConversationViewForm initConversationViewForm) }, getChannels () )

        ( SwitchLanguage, _ ) ->
            ( { model | language = oppositeLanugage model.language }, Cmd.none )

        ( CopyToClipboard string, _ ) ->
            ( model, copyToClipboard (E.string string) )

        ( BurgerClicked, _ ) ->
            ( toogleOpenMenu model, Cmd.none )

        ( ShowBottomNotification resultNotification, _ ) ->
            case resultNotification of
                Ok notification ->
                    ( { model | bottomNotification = Just notification }, Task.perform (\a -> HideBottomNotification) (Process.sleep 3000) )

                _ ->
                    ( model, Cmd.none )

        ( HideBottomNotification, _ ) ->
            ( { model | bottomNotification = Nothing }, Cmd.none )

        ( SignOutClicked, _ ) ->
            let
                newModel =
                    Tuple.first <| init model.programFlags
            in
            ( { newModel | language = model.language }, logoutJs () )

        ( Error err, _ ) ->
            ( { model | errors = [ err ] }, Cmd.none )

        ( TestMsg, _ ) ->
            ( model, showSnackbar "asd" )

        _ ->
            ( model, Cmd.none )


menuBar : Model -> Html Msg
menuBar model =
    nav [ class "navbar is-primary " ]
        [ div [ class "navbar-brand" ]
            [ a [ class " navbar-item ", onClick SwitchLanguage ]
                [ Html.img
                    [ class "image is-16x16 is-marginless"
                    , src
                        (case model.language of
                            PL ->
                                "poland.svg"

                            EN ->
                                "uk.svg"
                        )
                    ]
                    []
                ]
            , Html.a [ class "navbar-item", onClick OpenMainSite ]
                [ i [ class "fas fa-info-circle" ] []
                ]
            , Html.a [ class "navbar-item", Html.Attributes.classList [ ( "hidden", isNothing model.user ) ], onClick OpenFriendsSite ]
                [ i [ class "fas fa-user-friends" ] []
                ]
            , a [ class " navbar-item ", Html.Attributes.classList [ ( "hidden", isNothing model.user ) ], onClick OpenConversationSite ]
                [ i [ class "fas fa-envelope" ] []
                ]
            , a
                [ class "navbar-burger burger"
                , Html.Attributes.attribute "data-target" "navbar-id"
                , Html.Attributes.attribute "role" "button"
                , onClick BurgerClicked
                ]
                [ Html.span [] [], Html.span [] [], Html.span [] [] ]
            ]
        , div [ Html.Attributes.id "navbar-id", Html.Attributes.classList [ ( "navbar-menu", True ), ( "is-active animated ", model.menuOpen ) ] ]
            [ div [ class "navbar-start" ]
                []
            , div [ class "navbar-end" ]
                [ case model.user of
                    Nothing ->
                        a [ class "navbar-item", onClick OpenLoginSite ] [ Html.button [ class "button is-light is-rounded is-fullwidth" ] [ text (getTerms model.language |> .signIn) ] ]

                    Just user ->
                        a [ class "navbar-item", onClick SignOutClicked ] [ Html.button [ class "button is-light is-rounded" ] [ text (getTerms model.language |> .signOut) ] ]
                ]
            ]
        ]


progressBar : Model -> Html Msg
progressBar model =
    if model.loading then
        Html.progress [ class "progress is-small is-primary" ] []

    else
        div [] []


type FavouriteOption
    = FavouriteAdd
    | FavouriteRemove
    | FavouriteDisabled


mainView : Model -> Html Msg
mainView model =
    Html.map (\_ -> NoOp (Ok ())) <| Info.infoView model.language



-- Html.section [ class "hero is-primary  is-fullheight" ] []


footerView : Model -> Html Msg
footerView model =
    Html.footer [ class "footer p-b-md p-t-md has-background-grey-light" ]
        [ div [ class "content has-text-centered " ]
            [ Html.p [] [ text "Kacper Marzecki 2020" ]
            , div []
                [ text "Icons made by "
                , a [ Html.Attributes.href "https://www.flaticon.com/authors/freepik", title "Freepik" ]
                    [ text "Freepik" ]
                , text " from "
                , a [ Html.Attributes.href "https://www.flaticon.com/", title "Flaticon" ]
                    [ text "www.flaticon.com" ]
                ]
            , case model.bottomNotification of
                Just note ->
                    div [ Html.Attributes.id "snackbar", class "show" ]
                        [ text note
                        ]

                _ ->
                    div [] []
            ]
        ]


loginView : Model -> Html Msg
loginView model =
    let
        formState =
            case model.form of
                Just (LoginForm state) ->
                    state

                _ ->
                    newLoginForm

        terms =
            getTerms model.language |> .logInTerms
    in
    div [ class "hero-body", Html.Attributes.style "display" "block" ]
        [ div [ class "container has-text-centered" ]
            [ div [ class "column is-4 is-offset-4" ]
                [ div [ class "box box-center" ]
                    [ Html.figure [ class "avatar" ]
                        [ img [ Html.Attributes.alt "Welcome text", src "https://eu.ui-avatars.com/api/?bold=true&rounded=true&name=H+I&size=128x128" ] []
                        ]
                    , div [ class "field" ]
                        [ div [ class "control " ]
                            [ input
                                [ class "input is-large"
                                , Html.Attributes.attribute "aria-label" terms.username
                                , Html.Attributes.placeholder terms.username
                                , onInput (\a -> GotLoginFormMsg (ChangeLogin a))
                                , Html.Attributes.value formState.login
                                ]
                                []
                            ]
                        ]
                    , div [ class "field" ]
                        [ div [ class "control " ]
                            [ input
                                [ class "input is-large"
                                , Html.Attributes.placeholder terms.password
                                , Html.Attributes.attribute "aria-label" terms.password
                                , Html.Attributes.type_ "password"
                                , onInput (\a -> GotLoginFormMsg (ChangePassword a))
                                , Html.Attributes.value formState.password
                                ]
                                []
                            ]
                        ]
                    , Html.button [ class "button is-block is-info is-large is-fullwidth", onClick (GotLoginFormMsg LoginButtonClicked) ]
                        [ text terms.logIn
                        , i [ class "fas fa-sign-in-alt" ] []
                        ]
                    , Html.button [ class "button is-block is-info is-large is-fullwidth m-t-sm", onClick (GotLoginFormMsg OpenRegistrationSite) ]
                        [ text terms.register
                        , i [ class "fas fa-user-alt" ] []
                        ]
                    ]
                ]
            ]
        ]


registrationView : Model -> Html Msg
registrationView model =
    let
        formState =
            case model.form of
                Just (RegistrationForm state) ->
                    state

                _ ->
                    initRegistrationForm

        terms =
            getTerms model.language |> .registerTerms
    in
    div [ class "hero-body", Html.Attributes.style "display" "block" ]
        [ div [ class "container has-text-centered" ]
            [ div [ class "column is-4 is-offset-4" ]
                [ div [ class "box" ]
                    [ Html.figure [ class "avatar" ]
                        [ img [ src "https://eu.ui-avatars.com/api/?bold=true&rounded=true&name=H+I&size=128x128" ] []
                        ]
                    , div [ class "field" ]
                        [ div [ class "control " ]
                            [ input
                                [ class "input is-large"
                                , Html.Attributes.attribute "aria-label" terms.username
                                , Html.Attributes.placeholder terms.username
                                , onInput (GotRegisterFormMsg << ChangeRegisterLogin)
                                , Html.Attributes.value formState.login
                                ]
                                []
                            ]
                        ]
                    , div [ class "field" ]
                        [ div [ class "control " ]
                            [ input
                                [ class "input is-large"
                                , Html.Attributes.attribute "aria-label" terms.password
                                , Html.Attributes.placeholder terms.password
                                , Html.Attributes.type_ "password"
                                , onInput (GotRegisterFormMsg << ChangeRegisterPassword)
                                , Html.Attributes.value formState.password
                                ]
                                []
                            ]
                        ]
                    , div [ class "field" ]
                        [ div [ class "control " ]
                            [ input
                                [ class "input is-large"
                                , Html.Attributes.attribute "aria-label" terms.password
                                , Html.Attributes.placeholder terms.password
                                , Html.Attributes.type_ "password"
                                , onInput (GotRegisterFormMsg << ChangeRegisterRepeatPassword)
                                , Html.Attributes.value formState.passwordRepeat
                                ]
                                []
                            ]
                        ]
                    , Html.button [ class "button is-block is-info is-large is-fullwidth", onClick (GotRegisterFormMsg RegisterButtonClicked) ]
                        [ text terms.register
                        , i [ class "fas fa-sign-in-alt" ] []
                        ]
                    ]
                ]
            ]
        ]


newConversationFormView : Model -> Maybe NewConversationFormState -> List (Html Msg)
newConversationFormView model maybeFormState =
    case maybeFormState of
        Nothing ->
            []

        Just formState ->
            let
                terms =
                    getTerms model.language |> .conversationTerms

                myFriends =
                    getMyFriends model

                friendButton action name =
                    Html.button
                        [ class "button is-rounded"
                        , onClick (action name)
                        ]
                        [ text name ]

                friendsButtons clickAction friends =
                    List.map
                        (friendButton clickAction)
                        friends

                myFriendsButtons =
                    friendsButtons (GotConversationViewMsg << GotNewConversationFormMsg << AddFriendToConversation)
                        (listWithout myFriends formState.addedFriends)

                friendsToAddToConversation =
                    friendsButtons (GotConversationViewMsg << GotNewConversationFormMsg << RemoveFriendFromConversation)
                        formState.addedFriends

                friendSelect =
                    if List.isEmpty model.friends then
                        div [ class "container has-text-danger" ] [ text terms.noFriendsNoMessages ]

                    else
                        div [ class "columns is-multiline" ]
                            [ div [ class "column is-full" ]
                                [ div [ class "field is-horizontal" ]
                                    [ div [ class "field-label is-normal" ]
                                        [ Html.label [ class "label" ] [ text terms.name ]
                                        ]
                                    , div [ class "field-body" ]
                                        [ div [ class "field" ]
                                            [ div [ class "control " ]
                                                [ Html.input
                                                    [ class "input is-pulled-left m-r-sm"
                                                    , Html.Attributes.placeholder terms.conversationName
                                                    , Html.Attributes.value formState.conversationName
                                                    , onInput (GotConversationViewMsg << GotNewConversationFormMsg << ChangeConversationName)
                                                    ]
                                                    []
                                                ]
                                            ]
                                        ]
                                    ]
                                ]
                            , div [ class "column is-full" ]
                                [ div [ class "columns is is-multiline card" ]
                                    [ div [ class "column is-one-second" ]
                                        (div [ class "column is-full" ] [ text terms.clickToAdd ] :: myFriendsButtons)
                                    , div [ class "column is-one-second" ]
                                        (div [ class "column is-full" ] [ text terms.friendsInConversation ] :: friendsToAddToConversation)
                                    ]
                                ]
                            , div [ class "control column is-full" ]
                                [ Html.button
                                    [ class "button is-primary is-rounded is-fullwidth"
                                    , Html.Attributes.disabled (List.isEmpty friendsToAddToConversation || String.isEmpty formState.conversationName)
                                    , onClick (GotConversationViewMsg <| GotNewConversationFormMsg <| CreateConversationButtonClicked)
                                    ]
                                    [ text terms.createConversation ]
                                ]
                            ]
            in
            [ div [ class "modal is-active" ]
                [ div [ class "modal-background" ] []
                , div [ class "modal-card" ]
                    [ Html.header [ class "modal-card-head" ]
                        [ Html.p [ class "modal-card-title" ] [ text terms.newConversation ]
                        , Html.button [ class "modal-close is-large", onClick (GotConversationViewMsg <| GotNewConversationFormMsg <| CloseNewConversationFormView) ] []
                        ]
                    , Html.section [ class "modal-card-body" ]
                        [ friendSelect
                        ]
                    , Html.footer [ class "modal-card-footer" ]
                        [ Html.button [ class "modal-close is-large", onClick (GotConversationViewMsg <| GotNewConversationFormMsg <| CloseNewConversationFormView) ] []
                        ]
                    ]
                ]
            ]


messageView : Message -> Html Msg
messageView message =
    let
        youtubeView link =
            Html.iframe
                [ Html.Attributes.attribute "frameborder" "0"
                , Html.Attributes.attribute "height" "360"
                , Html.Attributes.id "ytplayer"
                , src link
                , Html.Attributes.type_ "text/html"
                , Html.Attributes.attribute "width" "640"
                ]
                []

        linkView link =
            case Utils.createYoutubeEmbeddedLink link of
                Just youtubeLink ->
                    youtubeView youtubeLink

                _ ->
                    a [ Html.Attributes.href <| "//" ++ link ] [ text link ]

        messageTextView m =
            if Utils.isLink m then
                linkView m

            else
                text m
    in
    Html.article [ class "media" ]
        [ Html.figure [ class "media-left" ]
            [ Html.p [ class "image is-64x64" ]
                [ img [ Html.Attributes.attribute "aria-label" <| "message from " ++ message.username, src <| "https://eu.ui-avatars.com/api/?bold=true&rounded=true&name=" ++ message.username ++ "&size=128x128" ] []
                ]
            ]
        , div [ class "media-content", Html.Attributes.style "overflow-x" "unset" ]
            [ div [ class "content " ]
                [ Html.p []
                    [ Html.strong [] [ text <| message.username ++ "   " ]
                    , Html.small [] [ text (Utils.dateStringFromEpochSecondsmessage message.timeMillis) ]
                    , Html.br [] []
                    , messageTextView message.payload
                    ]
                ]
            , Html.nav [ class "level is-mobile" ] [ div [ class "level-left" ] [] ]
            ]
        ]


messageInputView : List Message -> ConversationViewFormState -> Model -> Html Msg
messageInputView messages formState model =
    let
        terms =
            getTerms model.language |> .conversationTerms

        username =
            case model.user of
                Just user ->
                    user.username

                Nothing ->
                    ""

        isButtonDisabled =
            Utils.isNothing model.chosenChannel

        enterHandler =
            if formState.sendOnEnter then
                Utils.onEnter (GotConversationViewMsg SendClicked)

            else
                Html.Attributes.attribute "x" "x"
    in
    Html.article [ class "media" ]
        [ Html.figure [ class "media-left" ]
            [ Html.p [ class "image is-64x64" ]
                [ img [ Html.Attributes.attribute "aria-hidden" "true", src <| "https://eu.ui-avatars.com/api/?bold=true&rounded=true&name=" ++ username ++ "&size=128x128" ]
                    []
                ]
            ]
        , div [ class "media-content" ]
            [ div [ class "field" ]
                [ Html.p [ class "control " ]
                    [ Html.textarea
                        [ class "is-fullwidth input"
                        , Html.Attributes.id "message-input"
                        , Html.Attributes.attribute "aria-label" terms.messageContent
                        , Html.Attributes.placeholder terms.messageContent
                        , Html.Attributes.value formState.messageInput
                        , onInput (GotConversationViewMsg << MessageInput)
                        , enterHandler
                        ]
                        []
                    ]
                ]
            , nav [ class "level m-b-sm" ]
                [ div [ class "level-left" ]
                    [ div [ class "level-item" ]
                        [ Html.button
                            [ class "button is-primary is-mobile-fullwidth"
                            , Html.Attributes.disabled isButtonDisabled
                            , onClick (GotConversationViewMsg SendClicked)
                            ]
                            [ text terms.send ]
                        ]
                    ]
                , div [ class "level-right" ]
                    [ div [ class "level-item" ]
                        [ Html.label [ class "checkbox" ]
                            [ input
                                [ Html.Attributes.type_ "checkbox"
                                , Html.Attributes.checked formState.sendOnEnter
                                , onClick (GotConversationViewMsg ToggleSendOnEnter)
                                ]
                                []
                            , text terms.pressEnterToSend
                            ]
                        ]
                    ]
                ]
            ]
        ]


conversationView : Model -> List (Html Msg)
conversationView model =
    let
        terms =
            getTerms model.language |> .conversationTerms

        formState =
            case model.form of
                Just (ConversationViewForm state) ->
                    state

                _ ->
                    initConversationViewForm

        previousMessageIndicator =
            if List.length model.messages < 10 then
                []

            else
                [ Html.button [ class "button is-rounded", onClick (GotConversationViewMsg PreviousMessagesClicked) ]
                    [ Html.i [ class "fas fa-arrow-up" ] [] ]
                ]

        messageTiles =
            if List.isEmpty model.messages then
                []

            else
                previousMessageIndicator
                    ++ List.map
                        messageView
                        model.messages

        newConversationForm =
            newConversationFormView model formState.newConversationFormState
    in
    newConversationForm
        ++ [ div [ class "m-l-md m-r-md m-b-md " ]
                [ div [ class "hero is-fullheight" ]
                    [ div
                        [ class "columns m-t-sm is-fullheight" ]
                        [ div [ class "column is-one-fifth fixed-column" ]
                            [ Html.button
                                [ class "m-b-md button is-rounded"
                                , onClick (GotConversationViewMsg NewConversationClicked)
                                ]
                                [ text terms.newConversation ]
                            , div [ class "list is-hoverable has-background-white" ]
                                (List.map
                                    (\c ->
                                        Html.a
                                            [ Html.Attributes.classList
                                                [ ( "list-item is-rounded is-borderless", True )
                                                , ( "has-background-white", Utils.equal model.chosenChannel c.id )
                                                ]
                                            , onClick (GotConversationViewMsg (ConversationClicked c.id))
                                            ]
                                            [ text c.name ]
                                    )
                                    (Dict.values model.channels)
                                )
                            ]
                        , div [ class "column fixed-column" ]
                            [ Html.aside [ class " box scrollable-column has-background-white-ter", Html.Attributes.id "messagesView" ]
                                messageTiles
                            , Html.aside [ class "box has-background-white-ter" ]
                                [ messageInputView model.messages formState model
                                ]
                            ]
                        ]
                    ]
                ]
           ]


getUserName : Model -> String
getUserName model =
    case model.user of
        Just user ->
            user.username

        _ ->
            ""


getMyFriends : Model -> List String
getMyFriends model =
    let
        userName =
            getUserName model
    in
    List.map
        (\f ->
            if f.requester == userName then
                f.target

            else
                f.requester
        )
        (List.filter
            (\f -> not f.pending)
            model.friends
        )


friendsSiteView : Model -> List (Html Msg)
friendsSiteView model =
    let
        terms =
            getTerms model.language |> .friendsTerms

        formState =
            case model.form of
                Just (FriendsSiteForm state) ->
                    state

                _ ->
                    initFriendsSiteState

        userName =
            getUserName model

        myFriends =
            List.map
                (\f -> tr [] [ td [] [ text f ] ])
                (getMyFriends model)

        pending =
            List.map
                (\f ->
                    if f.requester == userName then
                        tr []
                            [ td []
                                [ div [ class "level" ]
                                    [ div [ class "level-left" ]
                                        [ div [ class "level-item" ]
                                            [ text f.target
                                            ]
                                        ]
                                    ]
                                ]
                            ]

                    else
                        tr []
                            [ td []
                                [ div [ class "level" ]
                                    [ div [ class "level-left" ]
                                        [ div [ class "level-item" ] [ text f.requester ]
                                        ]
                                    , div [ class "level-right" ]
                                        [ div [ class "level-item" ]
                                            [ Html.button
                                                [ class "button is-rounded"
                                                , onClick (GotFriendsFormMsg (AcceptFriendRequest f.id))
                                                ]
                                                [ text terms.acceptRequest ]
                                            , Html.button
                                                [ class "button is-rounded is-danger"
                                                , onClick (GotFriendsFormMsg (DeclineFriendRequest f.id))
                                                ]
                                                [ text terms.declineRequest ]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                )
                (List.filter (\f -> f.pending) model.friends)
    in
    [ div [ class "columns m-l-sm m-r-sm m-t-md is-multiline" ]
        [ div [ class "column is-full" ]
            [ div [ class "columns " ]
                [ div [ class "column is-4 " ]
                    [ div [ class "field has-addons" ]
                        [ div [ class "control" ]
                            [ Html.input
                                [ class "input is-pulled-left m-r-sm"
                                , Html.Attributes.attribute "aria-label" "friend input"
                                , Html.Attributes.value formState.addFriendInput
                                , onInput (GotFriendsFormMsg << ChangeNewFriendInput)
                                ]
                                []
                            ]
                        , div [ class "control" ]
                            [ Html.button
                                [ class "button m-r-sm"
                                , onClick (GotFriendsFormMsg AddNewFriendButtonClicked)
                                ]
                                [ text terms.sendFriendRequest ]
                            ]
                        ]
                    ]
                ]
            ]
        , div [ class "column is-full" ]
            [ div [ class "columns" ]
                [ div [ class "column is-one-second" ]
                    [ div [ class "box " ]
                        [ Html.table [ class "table is-fullwidth is-hoverable" ]
                            [ Html.thead [] [ Html.h3 [ class "has-text-weight-bold" ] [ text terms.myFriends ] ]
                            , Html.tbody []
                                myFriends
                            ]
                        ]
                    ]
                , div [ class "column is-one-second" ]
                    [ div [ class "box " ]
                        [ Html.table [ class "table is-fullwidth is-hoverable" ]
                            [ Html.thead [] [ Html.h3 [ class "has-text-weight-bold" ] [ text terms.pendingRequests ] ]
                            , Html.tbody []
                                pending
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]


view : Model -> Html Msg
view model =
    let
        mainViewport =
            Html.main_ [ class "hero is-primary  is-fullheight " ]
                (case model.site of
                    MainSite ->
                        [ div [] [ mainView model ] ]

                    FriendsSite ->
                        friendsSiteView model

                    ConversationSite ->
                        conversationView model

                    LoginSite ->
                        [ loginView model ]

                    RegistrationSite ->
                        [ registrationView model ]
                )

        mainContent =
            div [ class "main-content" ]
                [ menuBar model
                , progressBar model
                , mainViewport
                ]
    in
    div [ class "root" ]
        [ mainContent
        , footerView model
        ]



---- PROGRAM ----


type alias ProgramFlags =
    { backendApi : String }


main : Program ProgramFlags Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions =
            always
                (Sub.batch
                    [ showSnackbarIn (\v -> ShowBottomNotification (Json.Decode.decodeValue Json.Decode.string v))
                    , getSavedUser (\u -> GotUser (Json.Decode.decodeValue userDecoder u))
                    , gotChannel (\c -> GotChannel (Json.Decode.decodeValue channelDecoder c))
                    , gotFriend (\f -> GotFriend (Json.Decode.decodeValue friendDecoder f))
                    , deletedFriend (\id -> DeletedFriend (Json.Decode.decodeString Json.Decode.int id))
                    , gotMessage (\m -> GotMessage (Json.Decode.decodeValue messageDecoder m))
                    , gotPreviousMessage (\m -> GotPreviousMessage (Json.Decode.decodeValue messageDecoder m))
                    ]
                )
        }
