port module Main exposing (..)

import Browser
import Channel exposing (..)
import Conversation exposing (Conversation, ConversationId, NewConversationFormState, conversationsDecoder, initNewConversationForm)
import Friends exposing (Friend, FriendsSiteState, friendDecoder, initFriendsSiteState)
import Home exposing (Home)
import Html exposing (Html, a, div, h1, i, img, input, nav, td, text, tr)
import Html.Attributes exposing (attribute, class, src, title)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (Decoder, field, string)
import Json.Encode as E
import Login exposing (LoginFormState, encodeLoginForm, newLoginForm)
import Message exposing (Message, messageDecoder)
import Page exposing (Page, pageDecoder)
import Process
import Registration exposing (RegistrationFormState, encodeRegisterForm, initRegistrationForm)
import Task
import User exposing (User, encodeUser, userDecoder)
import Utils exposing (isNothing)



-- PORTS


port copyToClipboard : E.Value -> Cmd msg


port openLink : E.Value -> Cmd msg


port showSnackbarIn : (E.Value -> msg) -> Sub msg


port showSnackbarOut : E.Value -> Cmd msg


port scrollToTheTop : () -> Cmd msg


port saveUser : E.Value -> Cmd msg


port getSavedUser : (E.Value -> msg) -> Sub msg


port connectWs : () -> Cmd msg


port getChannels : () -> Cmd msg


port gotChannel : (E.Value -> msg) -> Sub msg


port gotFriend : (E.Value -> msg) -> Sub msg


port logoutJs : () -> Cmd msg


port deletedFriend : (E.Value -> msg) -> Sub msg



-- port addNewFriend : E.Value -> Cmd msg


showSnackbar : String -> Cmd msg
showSnackbar s =
    showSnackbarOut (E.string s)



-- getConversations : Model -> Cmd Msg
-- getConversations model =
--     Http.get
--         { url = model.backendApi ++ "/conversations"
--         , expect = Http.expectJson (ApiMessage << GotConversations) conversationsDecoder
--         }


login : String -> LoginFormState -> Cmd Msg
login backendApi loginForm =
    Http.post
        { url = backendApi ++ "/api/auth/login"
        , expect = Http.expectJson (ApiMessage << LoggedIn) userDecoder
        , body = Http.jsonBody (encodeLoginForm loginForm)
        }


testAuth : Model -> Cmd Msg
testAuth model =
    let
        authentication =
            case model.user of
                Just user ->
                    user.token

                _ ->
                    "falseToken"
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



-- getUserInfo : String -> String -> Cmd Msg
-- getUserInfo backendApi authentication =
--     Http.request
--         { method = "GET"
--         , url = backendApi ++ "/api/auth/me"
--         , expect = Http.expectJson (ApiMessage << GotUser) userDecoder
--         , headers = [ Http.header "token" authentication ]
--         , body = Http.emptyBody
--         , timeout = Nothing
--         , tracker = Nothing
--         }


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


getMessagesCmd : String -> Cmd Msg
getMessagesCmd url =
    Http.get
        { url = url
        , expect = Http.expectJson (ApiMessage << GotMessages) (pageDecoder messageDecoder)
        }


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


type alias Model =
    { site : Site
    , form : Maybe Form
    , user : Maybe User
    , friends : List Friend
    , loading : Bool
    , menuOpen : Bool
    , conversations : List Conversation
    , channels : List Channel
    , page : Int
    , messagesPage : Maybe (Page Message)
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
            , friends = []
            , errors = []
            , messagesPage = Nothing
            , page = 0
            , backendApi = flags.backendApi
            , bottomNotification = Nothing
            , conversations = []
            , channels = []
            , token = ""
            }
    in
    ( model
    , Cmd.batch []
    )



---- UPDATE ----


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
    | AddNewFriendButtonClicked


type ApiMsg
    = GetUser
    | OpenLink String
    | GetConversations
    | GetMessages ConversationId
    | LoggedIn (Result Http.Error User)
    | GotMessages (Result Http.Error (Page Message))
    | GotConversations (Result Http.Error (List Conversation))
    | RegistrationComplete (Result Http.Error ())


type Msg
    = NoOp (Result Http.Error ())
    | ApiMessage ApiMsg
    | GotLoginFormMsg LoginFormMsg
    | GotRegisterFormMsg RegisterFormMsg
    | GotFriendsFormMsg FriendsFormMsg
    | GotUser (Result Json.Decode.Error User)
    | AuthTest (Result Http.Error ())
    | GotFriend (Result Json.Decode.Error Friend)
    | GotChannel (Result Json.Decode.Error Channel)
    | OpenMainSite
    | OpenFriendsSite
    | OpenLoginSite
    | OpenConversationSite
    | NewConversationClicked
    | CloseNewConversationFormView
    | SignOutClicked
    | OpenConversation Int
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
    if List.member channel model.channels then
        model

    else
        { model | channels = model.channels ++ [ channel ] }


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

        GotMessages (Err _) ->
            ( model, showSnackbar "Cannot get messages, please try later" )

        LoggedIn (Ok user) ->
            ( { model | user = Just user }, saveUser (encodeUser user) )

        OpenLink link ->
            ( model, openLink (E.string link) )

        GotConversations (Ok conversations) ->
            ( { model | conversations = conversations, loading = False }, Cmd.none )

        GetMessages pageNumber ->
            case buildMessagesUrl model pageNumber of
                Just url ->
                    ( { model | page = pageNumber }, Cmd.batch [ getMessagesCmd url ] )

                Nothing ->
                    update (Error "Invalid search parameters") model

        GotMessages (Ok messagesPage) ->
            ( { model | messagesPage = Just messagesPage }, Cmd.none )

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

        AddNewFriendButtonClicked ->
            ( model, addNewFriend model state )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.form ) of
        ( ApiMessage x, form ) ->
            apiUpdate x model form

        ( GotRegisterFormMsg m, Just (RegistrationForm state) ) ->
            registrationUpdate m state model

        ( GotLoginFormMsg m, Just (LoginForm state) ) ->
            loginUpdate m state model

        ( GotFriendsFormMsg m, Just (FriendsSiteForm state) ) ->
            friendsUpdate m state model

        ( CloseNewConversationFormView, _ ) ->
            ( { model | form = Nothing }, Cmd.none )

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

        ( OpenMainSite, _ ) ->
            ( { model | menuOpen = False, site = MainSite }, Cmd.none )

        ( OpenFriendsSite, _ ) ->
            ( { model | site = FriendsSite, form = Just (FriendsSiteForm initFriendsSiteState) }, Cmd.none )

        ( GotChannel (Ok channel), _ ) ->
            ( addChannel model channel, Cmd.none )

        ( NewConversationClicked, _ ) ->
            ( { model | form = Just (NewConversationForm initNewConversationForm) }, Cmd.none )

        ( OpenLoginSite, _ ) ->
            ( { model | site = LoginSite, form = Just (LoginForm newLoginForm), menuOpen = False }, Cmd.none )

        ( OpenConversation conversationId, _ ) ->
            ( { model | menuOpen = False, site = ConversationSite }, Cmd.none )

        ( OpenConversationSite, _ ) ->
            ( { model | site = ConversationSite }, getChannels () )

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
            -- TODO sign out api
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
            [ Html.a [ class "navbar-item", Html.Attributes.href "#", onClick OpenMainSite ]
                [ i [ class "fas fa-home" ] []
                ]
            , Html.a [ class "navbar-item", Html.Attributes.href "#", onClick OpenFriendsSite ]
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


homesPageView : Page Home -> Html Msg
homesPageView page =
    let
        homes =
            List.map (\home -> messageTile)
                page.content
    in
    div [ class "container is-fluid p-l-md", Html.Attributes.style "flex-direction" "column-reverse" ]
        (homes
            ++ [ div [ class "pagination is-centered is-rounded m-t-sm m-b-sm", Html.Attributes.attribute "role" "navigation" ]
                    [ Html.button [ class "pagination-previous", Html.Attributes.disabled (page.number == 0), onClick ((ApiMessage << GetMessages) (page.number - 1)) ] [ text "Previous" ]
                    , Html.ul [ class "pagination-list" ]
                        [ Html.li []
                            [ a [ class "pagination-link" ] [ text (String.fromInt (page.number + 1)) ]
                            ]
                        ]
                    , Html.button [ class "pagination-next", Html.Attributes.style "margin-right" "15px", Html.Attributes.disabled (page.number + 1 == page.totalPages), onClick ((ApiMessage << GetMessages) (page.number + 1)) ] [ text "Next" ]
                    ]
               ]
        )


mainView : Html Msg
mainView =
    Html.section [ class "hero is-primary  is-fullheight" ] []


footerView : Model -> Html Msg
footerView model =
    Html.footer [ class "footer p-b-md p-t-md" ]
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
                        [ img [ src "https://placehold.it/128x128" ] []
                        ]
                    , div [ class "field" ]
                        [ div [ class "control " ]
                            [ input
                                [ class "input is-large"
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



-- |> Html.map (\q -> ApiMessage << q)


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
                        [ img [ src "https://placehold.it/128x128" ] []
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


newConversationFormView : Model -> List (Html Msg)
newConversationFormView model =
    let
        friendSelect =
            if List.isEmpty model.friends then
                div [ class "container has-text-danger" ] [ text "No Friends, no messages :(" ]

            else
                div [ class "field is-grouped" ]
                    [ Html.label [ class "label" ] [ text "Select friends" ]
                    , div [ class "control" ]
                        [ div [ class "select " ]
                            (List.map (\f -> Html.option [] [ text f.requester ]) model.friends)
                        ]
                    , div [ class "control" ]
                        [ Html.button [ class "button" ] [ text "add" ] ]
                    ]
    in
    case model.form of
        Just (NewConversationForm form) ->
            [ div [ class "modal is-active" ]
                [ div [ class "modal-background" ] []
                , div [ class "modal-card" ]
                    [ Html.header [ class "modal-card-head" ]
                        [ Html.p [ class "modal-card-title" ] [ text "Create new conversation" ]
                        , Html.button [ class "modal-close is-large", onClick CloseNewConversationFormView ] []
                        ]
                    , Html.section [ class "modal-card-body" ]
                        [ friendSelect ]
                    , Html.footer [ class "modal-card-footer" ]
                        [ Html.button [ class "modal-close is-large", onClick CloseNewConversationFormView ] []
                        ]
                    ]
                ]
            ]

        _ ->
            []


conversationView : Model -> List (Html Msg)
conversationView model =
    let
        newConversationForm =
            newConversationFormView model
    in
    newConversationForm
        ++ [ div [ class "columns is-multiline" ]
                [ div [ class "column is-full m-l-sm" ]
                    [ Html.button [ class "is-pulled-left button is-rounded", onClick NewConversationClicked ] [ text "New Conversation" ] ]
                , div [ class "column is-full" ]
                    [ div
                        [ class "columns is-full" ]
                        [ div [ class "column is-one-fifth" ]
                            [ Html.aside [ class "menu is-narrow-mobile is-fullheight box m-l-sm" ]
                                [ Html.p [ class "menu-label" ] [ text "Conversations" ]
                                , Html.ul [ class "menu-list" ]
                                    (List.map
                                        (\c -> Html.li [] [ text c.name ])
                                        model.channels
                                    )
                                ]
                            ]
                        , div [ class "column  " ]
                            [ Html.aside [ class " box menu is-fullheight " ]
                                [ Html.p [ class "menu-label" ] [ text "Conversations" ]
                                , Html.ul [ class "menu-list" ]
                                    (List.map
                                        (\c -> Html.li [] [ text c.name ])
                                        model.channels
                                    )
                                ]
                            ]
                        ]
                    ]
                ]
           ]



--     [ Html.aside [ class "menu is-narrow-mobile is-fullheight box m-l-sm" ]
--         [ Html.p [ class "menu-label" ] [ text "Conversations" ]
--         , Html.ul [ class "menu-list" ]
--             (List.map
--                 (\c -> Html.li [] [ text c.name ])
--                 model.channels
--             )
--         ]
--     ]
-- , div [ class "column  " ]
--     [ Html.aside [ class " box menu is-fullheight " ]
--         [ Html.p [ class "menu-label" ] [ text "Conversations" ]
--         , Html.ul [ class "menu-list" ]
--             (List.map
--                 (\c -> Html.li [] [ text c.name ])
--                 model.channels
--             )
--         ]
--     ]
-- ]


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
            case model.user of
                Just user ->
                    user.username

                _ ->
                    ""

        myFriends =
            List.map
                (\f ->
                    if f.requester == userName then
                        tr [] [ td [] [ text f.target ] ]

                    else
                        tr [] [ td [] [ text f.requester ] ]
                )
                (List.filter
                    (\f -> not f.pending)
                    model.friends
                )

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
                                            [ Html.button [ class "button is-rounded" ] [ text "Accept" ]
                                            , Html.button [ class "button is-rounded is-danger" ] [ text "Decline" ]
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
                    [ Html.input
                        [ class "input is-pulled-left m-r-sm"
                        , Html.Attributes.value formState.addFriendInput
                        , onInput (GotFriendsFormMsg << ChangeNewFriendInput)
                        ]
                        []
                    ]
                , div [ class "column is-1" ]
                    [ Html.button
                        [ class "button is-rounded is-pulled-left m-r-sm"
                        , onClick (GotFriendsFormMsg AddNewFriendButtonClicked)
                        ]
                        [ text "Send friend request" ]
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
            Html.section [ class "hero is-primary  is-fullheight" ]
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
    { backendApi : String
    }


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
                    ]
                )
        }
