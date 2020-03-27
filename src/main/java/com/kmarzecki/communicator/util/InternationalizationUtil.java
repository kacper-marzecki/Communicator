package com.kmarzecki.communicator.util;

import com.kmarzecki.communicator.model.Language;

public class InternationalizationUtil {

    public static String userExists(String user, Language language){
        return language == Language.PL
                ? "Użytkownik " + user + " już istnieje"
                : "User " + user + " exists";
    }

    public static String cannotFindRequestedUsers(Language language){
        return language == Language.PL
                ?  "Nie udało się naleźć żądanych użytkowników"
                : "Cannot find all requested users";
    }

    public static String cannotBeYourOwnFriend(Language language){
        return language == Language.PL
                ?  "Nie możesz być sam sobie przyjacielem :)"
                : "You cannot be your own friend :)";
    }

    public static String alreadyAFriendOrInProgress(Language language){
        return language == Language.PL
                ?  "Już go znasz / nie odpowiedział na zapytanie"
                : "Already a friend or in progress of becoming one";
    }

    public static String conversationNameIsNotUnique(Language language){
        return language == Language.PL
                ?  "Nazwa konwersacji nie jest unikalna"
                : "Conversation name is not unique";
    }
    public static String cannotRespondToSomeoneElsesRequest(Language language){
        return language == Language.PL
                ?  "Nie można odpowiedzieć na czyjeś zapytanie"
                : "Cannot respond to someone else's request";
    }
    public static String cannotFindRequestedRequest(Language language){
        return language == Language.PL
                ?  "Nie udało się naleźć żądanej operacji"
                : "Such request does not exist";
    }
}
