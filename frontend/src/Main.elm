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
import Json.Decode exposing (Decoder, field, string)
import Json.Encode as E
import Login exposing (LoginFormState, encodeLoginForm, newLoginForm)
import Messages exposing (Message, MessagePayload(..), messageDecoder)
import Page exposing (Page, pageDecoder)
import Process
import Regex
import Registration exposing (RegistrationFormState, encodeRegisterForm, initRegistrationForm)
import Task
import Time
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


getLatestMessagesFromChannel : Model -> ChannelId -> Cmd Msg
getLatestMessagesFromChannel model channelId =
    authedGet
        { model = model
        , body = Http.emptyBody
        , url = "/conversation/message?channelId=" ++ String.fromInt channelId
        , expect = Http.expectWhatever NoOp
        }


getPreviousMessages : Model -> ChannelId -> Int -> Cmd Msg
getPreviousMessages model channelId timeMillis =
    authedGet
        { model = model
        , body = Http.emptyBody
        , url = "/conversation/previous_messages?channelId=" ++ String.fromInt channelId ++ "&before=" ++ String.fromInt timeMillis
        , expect = Http.expectWhatever NoOp
        }


login : String -> LoginFormState -> Cmd Msg
login backendApi loginForm =
    Http.post
        { url = backendApi ++ "/api/auth/login"
        , expect = Http.expectJson (ApiMessage << LoggedIn) userDecoder
        , body = Http.jsonBody (encodeLoginForm loginForm)
        }


respondToFriendRequest : Int -> Bool -> Model -> Cmd Msg
respondToFriendRequest id response model =
    authedPost
        { model = model
        , url = "/friends/process_request/" ++ String.fromInt id
        , expect = Http.expectWhatever NoOp
        , body = Http.jsonBody (encodeRespondToFriendRequest response)
        }


sendMessage : String -> ChannelId -> Model -> Cmd Msg
sendMessage message channelId model =
    authedPost
        { model = model
        , url = "/conversation/message"
        , expect = Http.expectWhatever NoOp
        , body = Http.jsonBody (Messages.encodeSendMessageRequest message channelId)
        }


authedRequest :
    { model : Model
    , body : Http.Body
    , url : String
    , method : String
    , expect : Http.Expect msg
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
        , url = r.model.backendApi ++ r.url
        , expect = r.expect
        , headers = [ Http.header "token" authentication ]
        }


authedGet :
    { model : Model
    , body : Http.Body
    , url : String
    , expect : Http.Expect msg
    }
    -> Cmd msg
authedGet r =
    authedRequest
        { model = r.model
        , body = r.body
        , url = r.url
        , expect = r.expect
        , method = "GET"
        }


authedPost :
    { model : Model
    , body : Http.Body
    , url : String
    , expect : Http.Expect msg
    }
    -> Cmd msg
authedPost r =
    authedRequest
        { model = r.model
        , body = r.body
        , url = r.url
        , expect = r.expect
        , method = "POST"
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
        , url = model.backendApi ++ "/api/auth/me"
        , expect = Http.expectWhatever AuthTest
        , headers = [ Http.header "token" authentication ]
        }


createConversation : Model -> NewConversationFormState -> Cmd Msg
createConversation model formState =
    authedPost
        { model = model
        , body = Http.jsonBody (encodeCreateConversation formState)
        , url = "/conversation"
        , expect = Http.expectWhatever (GotConversationViewMsg << GotNewConversationFormMsg << CreateConversationResponse)
        }


addNewFriend : Model -> FriendsSiteState -> Cmd Msg
addNewFriend model formState =
    let
        authentication =
            case model.user of
                Just user ->
                    user.token

                Nothing ->
                    "fakeToken"
    in
    Http.request
        { method = "POST"
        , url = model.backendApi ++ "/friends"
        , timeout = Nothing
        , tracker = Nothing
        , expect = Http.expectWhatever NoOp
        , body = Http.jsonBody (Friends.encodeAddFriendRequest formState)
        , headers = [ Http.header "token" authentication ]
        }


registerUser : String -> RegistrationFormState -> Cmd Msg
registerUser backendApi registerForm =
    Http.post
        { url = backendApi ++ "/api/auth/register"
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
    { site : Site
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
            { site = MainSite
            , user = Nothing
            , form = Nothing
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
            ( model, login model.backendApi state )

        OpenRegistrationSite ->
            ( { model | site = RegistrationSite, form = Just (RegistrationForm initRegistrationForm) }, Cmd.none )


registrationUpdate : RegisterFormMsg -> RegistrationFormState -> Model -> ( Model, Cmd Msg )
registrationUpdate msg state model =
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
                        registerUser model.backendApi state

                    else
                        showSnackbar "Passwords dont match"
            in
            ( model, cmd )


apiUpdate : ApiMsg -> Model -> Maybe Form -> ( Model, Cmd Msg )
apiUpdate msg model form =
    case msg of
        LoggedIn (Err _) ->
            ( model, showSnackbar "Cannot log in. Forgot password ?" )

        GotConversations (Err _) ->
            ( model, showSnackbar "Cannot get conversations, please try later" )

        RegistrationComplete (Err _) ->
            ( model, showSnackbar "Cannot register, please try a different Username" )

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
            ( Nothing, showSnackbar "Cannot create such conversation" )

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
                    ( { model | form = Just <| ConversationViewForm newState }, sendMessage state.messageInput id model )

                Nothing ->
                    ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
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
            ( { model | site = LoginSite, user = Nothing, form = Just (LoginForm newLoginForm), menuOpen = False }, showSnackbar "Cannot Log In" )

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
            ( { model | user = Nothing, site = MainSite }, logoutJs () )

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
            [ Html.a [ class "navbar-item", onClick OpenMainSite ]
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
                        a [ class "navbar-item", onClick OpenLoginSite ] [ text "Sign In" ]

                    Just user ->
                        a [ class "navbar-item", onClick SignOutClicked ] [ text "Sign Out" ]
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


messageTile : Html Msg
messageTile =
    let
        imgUrl =
            "/gumtree.png"
    in
    Html.article [ class "media" ]
        [ Html.figure [ class "media-left" ]
            [ Html.p [ class "image is-64x64 " ]
                [ img [ src imgUrl, class "is-marginless is-rounded" ] []
                ]
            ]
        , div [ class "media-content", Html.Attributes.style "overflow-x" "unset" ]
            [ div [ class "content " ]
                [ a [ class "has-text-black has-text-weight-light" ] [ text "description" ]
                ]
            , Html.nav [ class "level is-mobile" ]
                [ a [ class "level-item" ]
                    [ Html.span [ class "icon has-text-grey-lighter fas fa-heart", title "Favourite" ]
                        []
                    ]
                ]
            ]
        ]


mainView : Html Msg
mainView =
    Html.section [ class "hero is-primary  is-fullheight" ] []


footerView : Model -> Html Msg
footerView model =
    Html.footer [ class "footer p-b-md p-t-md has-background-grey-light" ]
        [ div [ class "content has-text-centered " ]
            [ Html.p [] [ text "Kacper Marzecki 2020" ]
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
                                , Html.Attributes.attribute "aria-label" "username-input"
                                , Html.Attributes.placeholder "Username"
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
                                , Html.Attributes.placeholder "Password"
                                , Html.Attributes.attribute "aria-label" "password-input"
                                , Html.Attributes.type_ "password"
                                , onInput (\a -> GotLoginFormMsg (ChangePassword a))
                                , Html.Attributes.value formState.password
                                ]
                                []
                            ]
                        ]
                    , Html.button [ class "button is-block is-info is-large is-fullwidth", onClick (GotLoginFormMsg LoginButtonClicked) ]
                        [ text "Login "
                        , i [ class "fas fa-sign-in-alt" ] []
                        ]
                    , Html.button [ class "button is-block is-info is-large is-fullwidth m-t-sm", onClick (GotLoginFormMsg OpenRegistrationSite) ]
                        [ text "Register "
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
                                , Html.Attributes.placeholder "Username"
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
                                , Html.Attributes.placeholder "Password"
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
                                , Html.Attributes.placeholder "Password"
                                , Html.Attributes.type_ "password"
                                , onInput (GotRegisterFormMsg << ChangeRegisterRepeatPassword)
                                , Html.Attributes.value formState.passwordRepeat
                                ]
                                []
                            ]
                        ]
                    , Html.button [ class "button is-block is-info is-large is-fullwidth", onClick (GotRegisterFormMsg RegisterButtonClicked) ]
                        [ text "Register"
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
                        div [ class "container has-text-danger" ] [ text "No Friends, no messages :(" ]

                    else
                        div [ class "columns is-multiline" ]
                            [ div [ class "column is-full" ]
                                [ div [ class "field is-horizontal" ]
                                    [ div [ class "field-label is-normal" ]
                                        [ Html.label [ class "label" ] [ text "Name" ]
                                        ]
                                    , div [ class "field-body" ]
                                        [ div [ class "field" ]
                                            [ div [ class "control " ]
                                                [ Html.input
                                                    [ class "input is-pulled-left m-r-sm"
                                                    , Html.Attributes.placeholder "Conversation name"
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
                                        (div [ class "column is-full" ] [ text "Click to add:" ] :: myFriendsButtons)
                                    , div [ class "column is-one-second" ]
                                        (div [ class "column is-full" ] [ text "Friends in conversation:" ] :: friendsToAddToConversation)
                                    ]
                                ]
                            , div [ class "control column is-full" ]
                                [ Html.button
                                    [ class "button is-primary is-rounded is-fullwidth"
                                    , Html.Attributes.disabled (List.isEmpty friendsToAddToConversation || String.isEmpty formState.conversationName)
                                    , onClick (GotConversationViewMsg <| GotNewConversationFormMsg <| CreateConversationButtonClicked)
                                    ]
                                    [ text "Create conversation !" ]
                                ]
                            ]
            in
            [ div [ class "modal is-active" ]
                [ div [ class "modal-background" ] []
                , div [ class "modal-card" ]
                    [ Html.header [ class "modal-card-head" ]
                        [ Html.p [ class "modal-card-title" ] [ text "Create new conversation" ]
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
                [ img [ src <| "https://eu.ui-avatars.com/api/?bold=true&rounded=true&name=" ++ message.username ++ "&size=128x128" ] []
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
            , Html.nav [ class "level is-mobile" ]
                [ div [ class "level-left" ]
                    [ a [ class "level-item icon is-small" ] [ Html.i [ class "fas fa-reply" ] [] ]
                    ]
                ]
            ]
        ]


messageInputView : List Message -> ConversationViewFormState -> Model -> Html Msg
messageInputView messages formState model =
    let
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
                Html.Attributes.attribute "asd" "asd"
    in
    Html.article [ class "media" ]
        [ Html.figure [ class "media-left" ]
            [ Html.p [ class "image is-64x64" ]
                [ img [ src <| "https://eu.ui-avatars.com/api/?bold=true&rounded=true&name=" ++ username ++ "&size=128x128" ]
                    []
                ]
            ]
        , div [ class "media-content" ]
            [ div [ class "field" ]
                [ Html.p [ class "control " ]
                    [ Html.textarea
                        [ class "is-fullwidth input"
                        , Html.Attributes.placeholder "Message content"
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
                            [ text "Send" ]
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
                            , text "Press enter to send"
                            ]
                        ]
                    ]
                ]
            ]
        ]


conversationView : Model -> List (Html Msg)
conversationView model =
    let
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
                [ text "Select or create a conversation" ]

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
                        [ class "columns m-t-sm is-fullheight conversation-columns" ]
                        [ div [ class "column is-one-fifth fixed-column" ]
                            [ Html.aside [ class " is-narrow-mobile  box m-l-sm has-background-white-ter" ]
                                [ Html.button
                                    [ class "m-b-md button is-rounded"
                                    , onClick (GotConversationViewMsg NewConversationClicked)
                                    ]
                                    [ text "New Conversation" ]
                                , div [ class "list is-hoverable has-background-white" ]
                                    (List.map
                                        (\c ->
                                            Html.a
                                                [ Html.Attributes.classList
                                                    [ ( "list-item is-borderless", True )
                                                    , ( "has-background-white", Utils.equal model.chosenChannel c.id )
                                                    ]
                                                , onClick (GotConversationViewMsg (ConversationClicked c.id))
                                                ]
                                                [ text c.name ]
                                        )
                                        (Dict.values model.channels)
                                    )
                                ]
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
                                                [ text "Accept" ]
                                            , Html.button
                                                [ class "button is-rounded is-danger"
                                                , onClick (GotFriendsFormMsg (DeclineFriendRequest f.id))
                                                ]
                                                [ text "Decline" ]
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
                [ div [ class "column is-2 " ]
                    [ div [ class "field has-addons" ]
                        [ div [ class "control" ]
                            [ Html.input
                                [ class "input is-pulled-left m-r-sm"
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
                                [ text "Send friend request" ]
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
                            [ Html.thead [ class "has-text-weight-bold" ] [ text "My friends" ]
                            , Html.tbody []
                                myFriends
                            ]
                        ]
                    ]
                , div [ class "column is-one-second" ]
                    [ div [ class "box " ]
                        [ Html.table [ class "table is-fullwidth is-hoverable" ]
                            [ Html.thead [ class "has-text-weight-bold" ] [ text "Pending Requests" ]
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
                        [ div [] [ mainView ] ]

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
