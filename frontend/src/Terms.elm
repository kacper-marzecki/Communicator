module Terms exposing (..)


type TermsLanguage
    = PL 
    | EN


type alias FriendsTerms =
    { sendFriendRequest : String
    , myFriends : String
    , pendingRequests : String
    , acceptRequest : String
    , declineRequest : String
    }


type alias ConversationTerms =
    { newConversation : String
    , selectOrCreateConversation : String
    , messageContent : String
    , send : String
    , pressEnterToSend : String
    , noFriendsNoMessages : String
    , conversationName : String
    , clickToAdd : String
    , friendsInConversation : String
    , createConversation : String
    , name : String
    }


type alias LogInTerms =
    { username : String
    , password : String
    , logIn : String
    , register: String
    }


type alias RegisterTerms =
    { username : String
    , password : String
    , register : String
    }


type alias Terms =
    { signOut : String
    , signIn : String
    , logInTerms : LogInTerms
    , registerTerms : RegisterTerms
    , conversationTerms : ConversationTerms
    , friendsTerms : FriendsTerms
    }


logInTermsPL : LogInTerms
logInTermsPL =
    { username = "Użytkownik"
    , password = "Hasło"
    , logIn = "Zaloguj się"
    , register = "Zarejestruj się"
    }


registerTermsPL : RegisterTerms
registerTermsPL =
    { username = "Użytkownik"
    , password = "Hasło"
    , register = "Zarejestruj się"
    }


conversationTermsPL : ConversationTerms
conversationTermsPL =
    { newConversation = "Nowa konwersacja"
    , selectOrCreateConversation = "Wybierz albo stwórz konwersację"
    , messageContent = "tekst wiadomości"
    , send = "Wyślij"
    , pressEnterToSend = "Enter by wysłać"
    , noFriendsNoMessages = "Bez znajomych, nie ma do kogo wysyłać :("
    , conversationName = "Nazwa konwersacji"
    , clickToAdd = "Kliknij aby dodać"
    , friendsInConversation = "Znajomi w konwersacji"
    , createConversation = "Stwórz konwersację !"
    , name = "Nazwa"
    }


friendsTermsPL : FriendsTerms
friendsTermsPL =
    { sendFriendRequest = "Wyślij zapytanie"
    , myFriends = "Znajomi"
    , pendingRequests = "Oczekujące zapytania"
    , acceptRequest = "zaakceptuj"
    , declineRequest = "Odmów"
    }


termsPL : Terms
termsPL =
    { signOut = "Wyloguj się"
    , signIn = "Zaloguj się"
    , logInTerms = logInTermsPL
    , registerTerms = registerTermsPL
    , conversationTerms = conversationTermsPL
    , friendsTerms = friendsTermsPL
    }


logInTermsEN : LogInTerms
logInTermsEN =
    { username = "Username"
    , password = "Password"
    , logIn = "Sign in"
    , register = "Register"
    }


registerTermsEN : RegisterTerms
registerTermsEN =
    { username = "Username"
    , password = "Password"
    , register = "Register"
    }


conversationTermsEN : ConversationTerms
conversationTermsEN =
    { newConversation = "New conversation"
    , selectOrCreateConversation = "Select or create conversation"
    , messageContent = "Message content"
    , send = "Send"
    , pressEnterToSend = "Press ENTER to send"
    , noFriendsNoMessages = "No friends, no messages :("
    , conversationName = "Conversation name"
    , clickToAdd = "Click to add"
    , friendsInConversation = "Friends in conversation"
    , createConversation = "Create new conversation !"
    , name = "Name"
    }


friendsTermsEN : FriendsTerms
friendsTermsEN =
    { sendFriendRequest = "Send friend request"
    , myFriends = "My friends"
    , pendingRequests = "Pending requests"
    , acceptRequest = "Accept"
    , declineRequest = "Decline"
    }


termsEN : Terms
termsEN =
    { signOut = "Sign out"
    , signIn = "Sign in"
    , logInTerms = logInTermsEN
    , registerTerms = registerTermsEN
    , conversationTerms = conversationTermsEN
    , friendsTerms = friendsTermsEN
    }


oppositeLanugage : TermsLanguage -> TermsLanguage
oppositeLanugage language =
    case language of
        PL ->
            EN

        EN ->
            PL


getTerms : TermsLanguage -> Terms
getTerms language =
    case language of
        PL ->
            termsPL

        EN ->
            termsEN
