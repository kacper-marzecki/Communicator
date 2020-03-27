package com.kmarzecki.communicator.service;

import com.kmarzecki.communicator.model.Language;

import java.security.Principal;

/**
 * Service containing logic related to friends
 */
public interface FriendsService {
    /**
     * Get Friends of the requesting user
     * Pushes the response through a websocket connection
     * @param principal Principal of the requesting user
     */
    void getFriendsFor(Principal principal);

    /**
     * Add a friend
     * Pushes the response through a websocket connection
     * @param requester Friendship requester id
     * @param target User id of the target of the friendship
     * @param language User language
     */
    void addFriend(String requester, String target, Language language);

    /**
     * Respond to a friendship request
     * Pushes the response through a websocket connection
     * @param id friendship request id
     * @param accept whether the request is accepted
     * @param language User language
     * @param principal principal of the responding user
     */
    void processFriendshipRequest(Integer id, boolean accept, Principal principal , Language language);
}
